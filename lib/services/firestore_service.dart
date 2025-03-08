import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:async';
import '../models/exercise.dart';
import '../models/exercise_result.dart';
import '../models/workout_plan.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Ensure user is authenticated
  Future<String> ensureAuthenticated() async {
    if (_auth.currentUser == null) {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user!.uid;
    }
    return _auth.currentUser!.uid;
  }

  // Generate a unique invite code
  String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    final random = Random();
    String code = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    return code.toUpperCase();
  }

  // Upload a workout plan to Firestore
  Future<String> uploadWorkoutPlan(WorkoutPlan workoutPlan) async {
    final planDocRef = await _firestore.collection('workout_plans').add({
      'name': workoutPlan.name,
      'exercises': workoutPlan.exercises.map((e) => e.toJson()).toList(),
      'created_at': FieldValue.serverTimestamp(),
      'created_by': currentUserId,
    });

    return planDocRef.id;
  }

  // Create a new group workout
  Future<String> createGroupWorkout({
    required String workoutType,
    required String inviteCode,
    required WorkoutPlan workoutPlan,
  }) async {
    final userId = await ensureAuthenticated();

    // First upload the workout plan
    final planId = await uploadWorkoutPlan(workoutPlan);

    // Then create the group workout
    final workoutRef = await _firestore.collection('group_workouts').add({
      'type': workoutType, // 'Collaborative' or 'Competitive'
      'invite_code': inviteCode,
      'workout_plan_id': planId,
      'workout_plan': {
        'name': workoutPlan.name,
        'exercises': workoutPlan.exercises.map((e) => e.toJson()).toList(),
      },
      'created_by': userId,
      'created_at': FieldValue.serverTimestamp(),
      'participants': {
        userId: {
          'joined_at': FieldValue.serverTimestamp(),
          'results': [],
          'is_creator': true,
        }
      },
      'status': 'waiting',
      'is_active': true,
    });

    return workoutRef.id;
  }

  // Join an existing group workout
  Future<Map<String, dynamic>> joinGroupWorkout(String inviteCode) async {
    final userId = await ensureAuthenticated();

    // Normalize invite code to uppercase
    inviteCode = inviteCode.toUpperCase();

    print('Looking for workout with invite code: $inviteCode');

    // Query for the workout with the invite code
    final querySnapshot = await _firestore
        .collection('group_workouts')
        .where('invite_code', isEqualTo: inviteCode)
        .where('is_active', isEqualTo: true)
        .get();

    print('Query returned ${querySnapshot.docs.length} documents');

    if (querySnapshot.docs.isEmpty) {
      throw Exception('No active workout found with that invite code.');
    }

    final workoutDoc = querySnapshot.docs.first;
    final workoutData = workoutDoc.data();
    print('Found workout: ${workoutData['type']} - Status: ${workoutData['status']}');

    // Check if workout has already started
    final status = workoutData['status'] as String? ?? 'waiting';
    if (status == 'active') {
      throw Exception('This workout has already started and cannot be joined.');
    }

    // Add the user to participants if not already there
    if (!workoutData['participants'].containsKey(userId)) {
      print('Adding user $userId as a participant');
      await workoutDoc.reference.update({
        'participants.$userId': {
          'joined_at': FieldValue.serverTimestamp(),
          'results': [],
        }
      });
      print('User added successfully');
    } else {
      print('User is already a participant');
    }

    return workoutData;
  }

  // Start a workout (change status to active)
  Future<void> startWorkout(String workoutId) async {
    await _firestore.collection('group_workouts').doc(workoutId).update({
      'status': 'active',
    });
  }

  // Submit results for a group workout
  Future<void> submitWorkoutResults(String inviteCode, List<ExerciseResult> results) async {
    final userId = await ensureAuthenticated();

    // Find the workout
    final querySnapshot = await _firestore
        .collection('group_workouts')
        .where('invite_code', isEqualTo: inviteCode)
        .where('is_active', isEqualTo: true)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Workout not found or no longer active.');
    }

    final workoutDoc = querySnapshot.docs.first;

    // Convert results to JSON format
    final resultsJson = results.map((result) => result.toJson()).toList();

    // Update the user's results
    await workoutDoc.reference.update({
      'participants.$userId.results': resultsJson,
      'participants.$userId.completed_at': FieldValue.serverTimestamp(),
    });
  }

  // Get workout data with results
  Future<Map<String, dynamic>> getWorkoutResults(String inviteCode) async {
    // Find the workout
    final querySnapshot = await _firestore
        .collection('group_workouts')
        .where('invite_code', isEqualTo: inviteCode)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Workout not found.');
    }

    final workoutDoc = querySnapshot.docs.first;
    final workoutData = workoutDoc.data();

    return workoutData;
  }

  // Listen for workout changes
  Stream<DocumentSnapshot> listenToWorkout(String workoutId) {
    return _firestore.collection('group_workouts').doc(workoutId).snapshots();
  }

  // Calculate rankings for competitive workout
  Map<String, int> calculateRankings(Map<String, dynamic> participants) {
    if (participants.isEmpty) return {};

    // Extract all participants and count their successful exercises
    List<MapEntry<String, int>> participantSuccesses = [];

    participants.forEach((userId, data) {
      if (data['results'] != null && (data['results'] as List).isNotEmpty) {
        int successCount = 0;
        int totalExercises = (data['results'] as List).length;

        for (var result in data['results']) {
          // Consider an exercise successful if actual_output >= target
          num actualOutput = result['actual_output'] ?? 0;
          num targetOutput = result['target'] ?? 0;

          if (actualOutput >= targetOutput) {
            successCount++;
          }
        }

        // Add to our list for ranking
        participantSuccesses.add(MapEntry(userId, successCount));

        // Debug logging
        print('User $userId: $successCount/$totalExercises successful exercises');
      }
    });

    // Sort by success count (descending)
    participantSuccesses.sort((a, b) => b.value.compareTo(a.value));

    // Debug logging
    print('Sorted participants: ${participantSuccesses.map((e) => "${e.key}:${e.value}").join(", ")}');

    // Assign ranks (handling ties correctly)
    Map<String, int> rankings = {};

    if (participantSuccesses.isEmpty) return rankings;

    // Initialize with first participant
    int currentRank = 1;
    int previousScore = participantSuccesses[0].value;
    rankings[participantSuccesses[0].key] = currentRank;

    // Process remaining participants
    for (int i = 1; i < participantSuccesses.length; i++) {
      final userId = participantSuccesses[i].key;
      final score = participantSuccesses[i].value;

      // If this score is lower than previous, increment rank
      if (score < previousScore) {
        currentRank = i + 1; // Rank should be position + 1
      }

      rankings[userId] = currentRank;
      previousScore = score;
    }

    // Debug logging
    rankings.forEach((userId, rank) {
      print('Assigned rank $rank to user $userId');
    });

    return rankings;
  }

  // Process results for collaborative workout
  Map<String, dynamic> processCollaborativeResults(Map<String, dynamic> participants, List<Exercise> exercises) {
    Map<String, int> combinedResults = {};

    // Initialize combined results with 0 for each exercise
    for (var exercise in exercises) {
      combinedResults[exercise.name] = 0;
    }

    // Add up all participant results
    participants.forEach((userId, data) {
      if (data['results'] != null) {
        for (var result in data['results']) {
          String exerciseName = result['name'] as String;
          // Handle numeric values that might be num (int or double)
          num output = result['actual_output'] ?? 0;
          combinedResults[exerciseName] = (combinedResults[exerciseName] ?? 0) + output.toInt();
        }
      }
    });

    return {
      'combined_results': combinedResults,
      'participant_count': participants.length,
    };
  }
}
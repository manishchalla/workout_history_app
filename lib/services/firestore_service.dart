import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
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
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
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
        }
      },
      'is_active': true,
    });

    return workoutRef.id;
  }

  // Join an existing group workout
  Future<Map<String, dynamic>> joinGroupWorkout(String inviteCode) async {
    final userId = await ensureAuthenticated();

    // Query for the workout with the invite code
    final querySnapshot = await _firestore
        .collection('group_workouts')
        .where('invite_code', isEqualTo: inviteCode)
        .where('is_active', isEqualTo: true)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('No active workout found with that invite code.');
    }

    final workoutDoc = querySnapshot.docs.first;
    final workoutData = workoutDoc.data();

    // Add the user to participants if not already there
    if (!workoutData['participants'].containsKey(userId)) {
      await workoutDoc.reference.update({
        'participants.$userId': {
          'joined_at': FieldValue.serverTimestamp(),
          'results': [],
        }
      });
    }

    return workoutData;
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

  // Calculate rankings for competitive workout
  Map<String, int> calculateRankings(Map<String, dynamic> participants) {
    if (participants.isEmpty) return {};

    // Extract all participants and their total scores
    List<MapEntry<String, int>> participantScores = [];

    participants.forEach((userId, data) {
      if (data['results'] != null && (data['results'] as List).isNotEmpty) {
        int totalScore = 0;

        for (var result in data['results']) {
          // Handle numeric values that might be num (int or double)
          num resultOutput = result['actual_output'] ?? 0;
          totalScore += resultOutput.toInt(); // Convert to int
        }

        participantScores.add(MapEntry(userId, totalScore));
      }
    });

    // Sort by score (descending)
    participantScores.sort((a, b) => b.value.compareTo(a.value));

    // Assign ranks
    Map<String, int> rankings = {};
    for (int i = 0; i < participantScores.length; i++) {
      rankings[participantScores[i].key] = i + 1; // Rank starts at 1
    }

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
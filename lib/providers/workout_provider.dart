import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/exercise.dart';
import '../models/exercise_result.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../database/database_helper.dart';
import '../services/firestore_service.dart';

class WorkoutProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirestoreService _firestoreService = FirestoreService();

  List<Workout> _workouts = [];
  List<WorkoutPlan> _savedWorkoutPlans = [];
  StreamSubscription<QuerySnapshot>? _groupWorkoutsSubscription;

  List<Workout> get workouts => List.unmodifiable(_workouts);
  List<WorkoutPlan> get savedWorkoutPlans => List.unmodifiable(_savedWorkoutPlans);

  // Getter for recent workouts (last 7 days)
  List<Workout> get recentWorkouts {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _workouts.where((workout) => workout.date.isAfter(sevenDaysAgo)).toList();
  }

  // Load all saved workouts and listen for real-time updates
  Future<void> loadWorkouts() async {
    // Load solo workouts from SQLite
    List<Workout> soloWorkouts = await _dbHelper.getWorkouts();
    print('Loaded ${soloWorkouts.length} solo workouts from SQLite');

    // Update the workouts list with the solo workouts
    _workouts = soloWorkouts;
    notifyListeners();

    // Set up listener for group workouts from Firestore
    final userId = _firestoreService.currentUserId;
    if (userId != null) {
      // Cancel any existing subscription
      _groupWorkoutsSubscription?.cancel();

      // Set up a new subscription
      _groupWorkoutsSubscription = FirebaseFirestore.instance
          .collection('group_workouts')
          .where('participants.$userId', isNull: false)
          .snapshots()
          .listen((snapshot) async {
        await _processGroupWorkouts(snapshot, userId);
      });
    }
  }

  // Process group workouts data and update workout list
  Future<void> _processGroupWorkouts(QuerySnapshot snapshot, String userId) async {
    List<Workout> groupWorkouts = [];

    for (var doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final workoutType = data['type'] as String? ?? 'Competitive';
        final workoutPlanData = data['workout_plan'] as Map<String, dynamic>?;
        final participants = data['participants'] as Map<String, dynamic>?;

        if (participants != null && workoutPlanData != null) {
          final userParticipantData = participants[userId] as Map<String, dynamic>?;

          if (userParticipantData != null && userParticipantData['results'] != null) {
            // Get participant count
            final participantCount = participants.length;

            // Calculate user rank for competitive workouts
            int? userRank;
            if (workoutType == 'Competitive') {
              final rankings = _firestoreService.calculateRankings(participants);
              userRank = rankings[userId];
            }

            // Convert user results
            final userResults = (userParticipantData['results'] as List<dynamic>)
                .map((result) {
              final resultMap = result as Map<String, dynamic>;

              // Calculate total output for each exercise (for collaborative)
              int? teamTotal;
              int? ranking;

              if (workoutType == 'Collaborative') {
                String exerciseName = resultMap['name'];
                teamTotal = 0;
                participants.forEach((pid, pData) {
                  if (pData['results'] != null) {
                    for (var pResult in pData['results']) {
                      if (pResult['name'] == exerciseName) {
                        // Convert num to int
                        num actualOutput = pResult['actual_output'] ?? 0;
                        teamTotal = (teamTotal ?? 0) + actualOutput.toInt();
                      }
                    }
                  }
                });
              } else if (workoutType == 'Competitive') {
                // Calculate ranking for this specific exercise
                String exerciseName = resultMap['name'];
                List<MapEntry<String, int>> exerciseRankings = [];

                participants.forEach((pid, pData) {
                  if (pData['results'] != null) {
                    for (var pResult in pData['results']) {
                      if (pResult['name'] == exerciseName) {
                        // Convert num to int
                        num actualOutput = pResult['actual_output'] ?? 0;
                        exerciseRankings.add(MapEntry(pid, actualOutput.toInt()));
                      }
                    }
                  }
                });

                // Sort by output (descending)
                exerciseRankings.sort((a, b) => b.value.compareTo(a.value));

                // Find user's position
                ranking = exerciseRankings.indexWhere((entry) => entry.key == userId) + 1;
              }

              // Convert actual_output from num to int
              num actualOutputNum = resultMap['actual_output'] ?? 0;

              return ExerciseResult(
                exercise: Exercise(
                  name: resultMap['name'],
                  targetOutput: (resultMap['target'] as num).toInt(),
                  unit: resultMap['unit'],
                ),
                actualOutput: actualOutputNum.toInt(),
                ranking: ranking,
                teamTotal: teamTotal,
              );
            })
                .toList();

            // Get timestamp and convert to DateTime
            Timestamp? createdAt = data['created_at'] as Timestamp?;
            DateTime date = createdAt?.toDate() ?? DateTime.now();

            // Create workout object with all the details
            groupWorkouts.add(Workout(
              id: null,
              date: date,
              results: userResults,
              type: workoutType,
              rank: userRank,
              participantCount: participantCount,
            ));
          }
        }
      } catch (e) {
        print('Error processing group workout: $e');
      }
    }

    // Update workout list with both solo and group workouts
    List<Workout> soloWorkouts = await _dbHelper.getWorkouts();
    _workouts = [...soloWorkouts, ...groupWorkouts];

    // Sort combined list by date (newest first)
    _workouts.sort((a, b) => b.date.compareTo(a.date));

    // Notify listeners of the update
    notifyListeners();
  }

  // Clean up the stream subscription
  @override
  void dispose() {
    _groupWorkoutsSubscription?.cancel();
    super.dispose();
  }

  // Add a new workout to the database (Solo Workouts)
  Future<void> addWorkout(Workout workout) async {
    try {
      await _dbHelper.insertWorkout(workout);
      _workouts.insert(0, workout); // Add to the top of the list
      notifyListeners(); // Notify listeners to update the UI
      print('Workout saved successfully.');
    } catch (e) {
      print('Error saving workout: $e');
    }
  }

  // Delete a workout by ID (Solo Workouts)
  Future<void> deleteWorkout(int workoutId) async {
    await _dbHelper.deleteWorkout(workoutId);
    _workouts.removeWhere((workout) => workout.id == workoutId);
    notifyListeners();
  }

  // Load all saved workout plans from the database
  Future<void> loadSavedWorkoutPlans() async {
    print('Loading saved workout plans...');
    try {
      _savedWorkoutPlans = await _dbHelper.getSavedWorkoutPlans();
      print('Loaded ${_savedWorkoutPlans.length} workout plans');
      notifyListeners();
    } catch (e) {
      print('Error loading saved workout plans: $e');
    }
  }

  // Save a new workout plan to the database
  Future<void> saveWorkoutPlan(WorkoutPlan workoutPlan) async {
    try {
      print('Saving workout plan: ${workoutPlan.name}');
      int id = await _dbHelper.insertWorkoutPlan(workoutPlan);
      print('Plan saved with ID: $id');

      // Create a new WorkoutPlan object with the updated ID
      final updatedWorkoutPlan = workoutPlan.copyWithId(id);

      _savedWorkoutPlans.add(updatedWorkoutPlan);
      print('Added plan to provider. Total plans: ${_savedWorkoutPlans.length}');
      notifyListeners();
      print('Notified listeners after saving workout plan.');

      // Verify the updated list
      print('Current workout plans:');
      for (var plan in _savedWorkoutPlans) {
        print('- ${plan.name} (ID: ${plan.id})');
      }
    } catch (e) {
      print('Error saving workout plan: $e');
    }
  }

  // Delete a workout plan by ID
  Future<void> deleteWorkoutPlan(int planId) async {
    try {
      await _dbHelper.deleteWorkoutPlan(planId);
      _savedWorkoutPlans.removeWhere((plan) => plan.id == planId);
      notifyListeners();
      print('Workout plan deleted successfully.');
    } catch (e) {
      print('Error deleting workout plan: $e');
    }
  }

  // Check if a workout plan with the same name already exists
  Future<bool> isDuplicatePlan(String name) async {
    final savedPlans = await _dbHelper.getSavedWorkoutPlans();
    return savedPlans.any((plan) => plan.name.toLowerCase() == name.toLowerCase());
  }

  // Create a new group workout in Firestore
  Future<String> createGroupWorkout(String type, String sharedKey, List<ExerciseResult> results) async {
    try {
      // Use the FirestoreService to submit workout results
      await _firestoreService.submitWorkoutResults(sharedKey, results);

      print('Group workout created successfully with shared key: $sharedKey');
      return sharedKey;
    } catch (e) {
      print('Error creating group workout: $e');
      rethrow;
    }
  }

  // Join a group workout using the shared key
  Future<void> joinGroupWorkout(String sharedKey, List<ExerciseResult> results) async {
    try {
      // Use the FirestoreService to submit workout results
      await _firestoreService.submitWorkoutResults(sharedKey, results);

      print('Successfully joined group workout with shared key: $sharedKey');
    } catch (e) {
      print('Error joining group workout: $e');
      rethrow;
    }
  }

  // Fetch group workout details by shared key
  Future<Map<String, dynamic>> getGroupWorkout(String sharedKey) async {
    try {
      final workoutData = await _firestoreService.getWorkoutResults(sharedKey);
      print('Fetched group workout data: $workoutData');
      return workoutData;
    } catch (e) {
      print('Error fetching group workout: $e');
      rethrow;
    }
  }
}
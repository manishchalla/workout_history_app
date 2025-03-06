import 'package:flutter/material.dart';
import '../models/exercise_result.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../database/database_helper.dart';

class WorkoutProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Workout> _workouts = [];
  List<WorkoutPlan> _savedWorkoutPlans = [];

  List<Workout> get workouts => List.unmodifiable(_workouts);
  List<WorkoutPlan> get savedWorkoutPlans => List.unmodifiable(_savedWorkoutPlans);

  // Getter for recent workouts (last 7 days)
  List<Workout> get recentWorkouts {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _workouts.where((workout) => workout.date.isAfter(sevenDaysAgo)).toList();
  }

  // Load all saved workouts from the database (Solo Workouts)
  Future<void> loadWorkouts() async {
    _workouts = await _dbHelper.getWorkouts();
    notifyListeners();
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
    _savedWorkoutPlans = await _dbHelper.getSavedWorkoutPlans();
    notifyListeners();
  }

  // Save a new workout plan to the database
  Future<void> saveWorkoutPlan(WorkoutPlan workoutPlan) async {
    try {
      int id = await _dbHelper.insertWorkoutPlan(workoutPlan);
      workoutPlan.id = id; // Assign the ID to the WorkoutPlan object
      _savedWorkoutPlans.add(workoutPlan);
      notifyListeners();
      print('Workout plan saved successfully.');
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
      final workoutId = await _dbHelper.createGroupWorkout(type, sharedKey, results);
      print('Group workout created successfully with ID: $workoutId');
      return workoutId;
    } catch (e) {
      print('Error creating group workout: $e');
      rethrow;
    }
  }

  // Join a group workout using the shared key
  Future<void> joinGroupWorkout(String sharedKey, List<ExerciseResult> results) async {
    try {
      await _dbHelper.joinGroupWorkout(sharedKey, results);
      print('Successfully joined group workout with shared key: $sharedKey');
    } catch (e) {
      print('Error joining group workout: $e');
      rethrow;
    }
  }

  // Fetch group workout details by shared key
  Future<Map<String, dynamic>> getGroupWorkout(String sharedKey) async {
    try {
      final workoutData = await _dbHelper.getGroupWorkout(sharedKey);
      print('Fetched group workout data: $workoutData');
      return workoutData;
    } catch (e) {
      print('Error fetching group workout: $e');
      rethrow;
    }
  }
}
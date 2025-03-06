import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../models/exercise.dart';
import '../models/exercise_result.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  // Getter for the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the SQLite database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'workout_app.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create tables when the database is first created
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        target_output INTEGER NOT NULL,
        unit TEXT NOT NULL,
        actual_output INTEGER NOT NULL,
        FOREIGN KEY(workout_id) REFERENCES workouts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        exercises TEXT NOT NULL
      )
    ''');
  }

  // Handle database upgrades (e.g., adding new tables)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE workout_plans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          exercises TEXT NOT NULL
        )
      ''');
    }
  }

  // Insert a new workout into the SQLite database (Solo Workouts)
  Future<int> insertWorkout(Workout workout) async {
    final db = await database;
    int workoutId = await db.insert('workouts', {'date': workout.date.toIso8601String()});
    for (var result in workout.results) {
      await db.insert('exercise_results', {
        'workout_id': workoutId,
        'name': result.exercise.name,
        'target_output': result.exercise.targetOutput,
        'unit': result.exercise.unit,
        'actual_output': result.actualOutput,
      });
    }
    return workoutId;
  }

  // Fetch all workouts from the SQLite database (Solo Workouts)
  Future<List<Workout>> getWorkouts() async {
    final db = await database;
    List<Map<String, dynamic>> workoutMaps = await db.query('workouts', orderBy: 'date DESC');
    List<Workout> workouts = [];
    for (var workoutMap in workoutMaps) {
      List<Map<String, dynamic>> resultMaps = await db.query(
        'exercise_results',
        where: 'workout_id = ?',
        whereArgs: [workoutMap['id']],
      );
      List<ExerciseResult> results = resultMaps.map((resultMap) {
        return ExerciseResult(
          exercise: Exercise(
            name: resultMap['name'],
            targetOutput: resultMap['target_output'],
            unit: resultMap['unit'],
          ),
          actualOutput: resultMap['actual_output'],
        );
      }).toList();
      workouts.add(Workout(
        id: workoutMap['id'],
        date: DateTime.parse(workoutMap['date']),
        results: results,
      ));
    }
    return workouts;
  }

  // Delete a workout by ID (Solo Workouts)
  Future<void> deleteWorkout(int workoutId) async {
    final db = await database;
    await db.delete('exercise_results', where: 'workout_id = ?', whereArgs: [workoutId]);
    await db.delete('workouts', where: 'id = ?', whereArgs: [workoutId]);
  }

  // Insert or replace a workout plan into the SQLite database
  Future<int> insertWorkoutPlan(WorkoutPlan workoutPlan) async {
    final db = await database;
    int id = await db.insert(
      'workout_plans',
      {
        'name': workoutPlan.name,
        'exercises': jsonEncode(workoutPlan.exercises.map((e) => {
          'name': e.name,
          'targetOutput': e.targetOutput,
          'unit': e.unit,
        }).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id; // Return the ID of the inserted workout plan
  }

  // Fetch all saved workout plans from the SQLite database
  Future<List<WorkoutPlan>> getSavedWorkoutPlans() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('workout_plans');
      print('Fetched workout plans: $maps'); // Log fetched data
      return maps.map((map) {
        final exercises = (jsonDecode(map['exercises']) as List<dynamic>)
            .map((e) => Exercise(
          name: e['name'],
          targetOutput: e['targetOutput'],
          unit: e['unit'],
        ))
            .toList();
        return WorkoutPlan(
          id: map['id'], // Assign the ID from the database
          name: map['name'],
          exercises: exercises,
        );
      }).toList();
    } catch (e) {
      print('Error fetching workout plans: $e');
      return [];
    }
  }

  // Delete a workout plan by ID (SQLite)
  Future<void> deleteWorkoutPlan(int planId) async {
    final db = await database;
    await db.delete('workout_plans', where: 'id = ?', whereArgs: [planId]);
  }

  // Firestore Methods for Group Workouts

  // Create a new group workout in Firestore
  Future<String> createGroupWorkout(String type, String sharedKey, List<ExerciseResult> results) async {
    final firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Store workout data in Firestore
    final workoutRef = await firestore.collection('workouts').add({
      'type': type,
      'creatorId': userId,
      'date': DateTime.now(),
      'sharedKey': sharedKey,
      'results': {userId: results.map((result) => result.toJson()).toList()},
    });

    return workoutRef.id; // Return the Firestore document ID
  }

  // Join a group workout using the shared key
  Future<void> joinGroupWorkout(String sharedKey, List<ExerciseResult> results) async {
    final firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Find the workout by shared key
    final querySnapshot = await firestore
        .collection('workouts')
        .where('sharedKey', isEqualTo: sharedKey)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Workout not found');
    }

    final workoutDoc = querySnapshot.docs.first;
    final workoutData = workoutDoc.data();

    // Update the results map with the current user's results
    final updatedResults = Map<String, dynamic>.from(workoutData['results']);
    updatedResults[userId] = results.map((result) => result.toJson()).toList();

    // Update the workout document in Firestore
    await workoutDoc.reference.update({'results': updatedResults});
  }

  // Fetch group workout details by shared key
  Future<Map<String, dynamic>> getGroupWorkout(String sharedKey) async {
    final firestore = FirebaseFirestore.instance;

    // Find the workout by shared key
    final querySnapshot = await firestore
        .collection('workouts')
        .where('sharedKey', isEqualTo: sharedKey)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Workout not found');
    }

    final workoutDoc = querySnapshot.docs.first;
    return workoutDoc.data();
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'dart:math';
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
    print('Database path: $path'); // Print the database path

    return await openDatabase(
      path,
      version: 3, // Increment version to trigger upgrade
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Check if the workout_plans table exists
        var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        print('Database tables: $tables');

        // Check if workout_plans table has any data
        try {
          var count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM workout_plans'));
          print('Workout plans count in database: $count');
        } catch (e) {
          print('Error counting workout plans: $e');
        }
      },
    );
  }

  // Create tables when the database is first created
  Future<void> _onCreate(Database db, int version) async {
    print('Creating database tables for version $version');

    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT DEFAULT 'Solo'
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

    print('Database tables created successfully');
  }

  // Handle database upgrades (e.g., adding new tables)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      try {
        print('Creating workout_plans table if it doesn\'t exist...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS workout_plans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            exercises TEXT NOT NULL
          )
        ''');

        // Add type column to workouts if it doesn't exist
        try {
          await db.execute('ALTER TABLE workouts ADD COLUMN type TEXT DEFAULT "Solo"');
        } catch (e) {
          // Column might already exist
          print('Error adding column: $e');
        }
      } catch (e) {
        print('Error during upgrade to version 2: $e');
      }
    }

    if (oldVersion < 3) {
      // Just to force an upgrade and check the tables
      print('Upgrading to version 3...');

      // Make sure workout_plans table exists with correct schema
      try {
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='workout_plans'");
        if (tables.isEmpty) {
          print('workout_plans table doesn\'t exist, creating it...');
          await db.execute('''
            CREATE TABLE workout_plans (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              exercises TEXT NOT NULL
            )
          ''');
        } else {
          print('workout_plans table exists');
        }
      } catch (e) {
        print('Error checking workout_plans table: $e');
      }
    }
  }

  // Insert a new workout into the SQLite database (Solo Workouts)
  Future<int> insertWorkout(Workout workout) async {
    final db = await database;
    int workoutId = await db.insert('workouts', {
      'date': workout.date.toIso8601String(),
      'type': 'Solo'
    });

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
        type: workoutMap['type'] ?? 'Solo',
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
    print('Saving workout plan to database: ${workoutPlan.name}');

    final exercisesJson = jsonEncode(workoutPlan.exercises.map((e) => {
      'name': e.name,
      'targetOutput': e.targetOutput,
      'unit': e.unit,
    }).toList());

    print('Exercises count: ${workoutPlan.exercises.length}');
    print('Exercises JSON sample: ${exercisesJson.substring(0, min(100, exercisesJson.length))}...');

    try {
      int id = await db.insert(
        'workout_plans',
        {
          'name': workoutPlan.name,
          'exercises': exercisesJson,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('Workout plan saved with ID: $id');

      // Verify the saved data
      final savedPlans = await db.query(
        'workout_plans',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (savedPlans.isNotEmpty) {
        print('Saved plan confirmed in database with name: ${savedPlans.first['name']}');
      } else {
        print('Warning: Plan saved but not found on verification query');
      }

      return id;
    } catch (e) {
      print('Error inserting workout plan: $e');
      rethrow;
    }
  }

  // Fetch all saved workout plans from the SQLite database
  Future<List<WorkoutPlan>> getSavedWorkoutPlans() async {
    final db = await database;
    try {
      print('Attempting to fetch workout plans from database...');

      final List<Map<String, dynamic>> maps = await db.query('workout_plans');
      print('Fetched ${maps.length} workout plans from database');

      if (maps.isEmpty) {
        print('No workout plans found in database.');
        return [];
      }

      List<WorkoutPlan> plans = [];
      for (var map in maps) {
        try {
          print('Processing plan: ${map['name']}');
          final exercisesJson = map['exercises'] as String;
          print('Exercises JSON length: ${exercisesJson.length}');

          final exercisesList = jsonDecode(exercisesJson) as List<dynamic>;
          print('Decoded ${exercisesList.length} exercises');

          final exercises = exercisesList.map((e) => Exercise(
            name: e['name'],
            targetOutput: e['targetOutput'],
            unit: e['unit'],
          )).toList();

          plans.add(WorkoutPlan(
            id: map['id'],
            name: map['name'],
            exercises: exercises,
          ));

          print('Successfully processed plan: ${map['name']} with ${exercises.length} exercises');
        } catch (e) {
          print('Error processing individual plan ${map['name']}: $e');
        }
      }

      print('Returning ${plans.length} workout plans');
      return plans;
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

  // Get recent group workouts from Firestore
  Future<List<Workout>> getRecentGroupWorkouts() async {
    final firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return [];

    // Simplified query - just query for workouts where this user is a participant
    final querySnapshot = await firestore
        .collection('group_workouts')
        .where('participants.$userId', isNull: false)
        .get();

    List<Workout> groupWorkouts = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final workoutType = data['type'] as String;
      final workoutPlanData = data['workout_plan'];
      final participants = data['participants'] as Map<String, dynamic>;
      final userParticipantData = participants[userId];

      if (userParticipantData != null &&
          userParticipantData['results'] != null &&
          workoutPlanData != null) {

        // Convert results to ExerciseResult objects
        final results = (userParticipantData['results'] as List)
            .map((result) {
          return ExerciseResult(
            exercise: Exercise(
              name: result['name'],
              targetOutput: result['target'],
              unit: result['unit'],
            ),
            actualOutput: result['actual_output'],
          );
        }).toList();

        // Create Workout object
        Timestamp? createdAt = data['created_at'] as Timestamp?;
        DateTime date = createdAt?.toDate() ?? DateTime.now();

        groupWorkouts.add(Workout(
          id: null,
          date: date,
          results: results,
          type: workoutType,
        ));
      }
    }

    // Sort the workouts by date after fetching them
    groupWorkouts.sort((a, b) => b.date.compareTo(a.date));

    // Return just the most recent ones
    return groupWorkouts.take(10).toList();
  }
}
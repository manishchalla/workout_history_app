import 'exercise.dart';

class WorkoutPlan {
  final int? id; // Nullable because it's assigned after insertion into SQLite
  final String name;
  final List<Exercise> exercises;

  WorkoutPlan({
    this.id,
    required this.name,
    required this.exercises,
  });

  // Factory method to create a WorkoutPlan from JSON
  factory WorkoutPlan.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('Invalid or missing data in WorkoutPlan JSON');
    }

    return WorkoutPlan(
      name: json['name'] ?? 'Unnamed Workout', // Default to 'Unnamed Workout' if null
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((e) => Exercise.fromJson(e))
          .toList() ??
          [], // Default to empty list if null
    );
  }

  // Convert WorkoutPlan to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
  WorkoutPlan copyWithId(int id) {
    return WorkoutPlan(
      id: id,
      name: name,
      exercises: exercises,
    );
  }
}
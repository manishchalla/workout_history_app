import 'exercise.dart';

class WorkoutPlan {
  int? id; // Nullable and non-final ID
  final String name;
  final List<Exercise> exercises;

  WorkoutPlan({
    this.id,
    required this.name,
    required this.exercises,
  });

  // Factory method to create a WorkoutPlan from JSON
  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'], // ID may be null
      name: json['name'],
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => Exercise(
        name: e['name'],
        targetOutput: e['targetOutput'] ?? 0,
        unit: e['unit'] ?? 'repetitions',
      ))
          .toList(),
    );
  }

  // Convert WorkoutPlan to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => {
        'name': e.name,
        'targetOutput': e.targetOutput,
        'unit': e.unit,
      }).toList(),
    };
  }
}
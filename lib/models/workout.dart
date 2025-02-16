import 'exercise_result.dart';

class Workout {
  final int? id; // Optional ID for database persistence
  final DateTime date; // The date and time of the workout
  final List<ExerciseResult> results; // List of exercise results in this workout

  Workout({
    this.id,
    required this.date,
    required this.results,
  });

  // Factory method to create a Workout from JSON
  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'], // ID is optional and may not be present in JSON
      date: DateTime.parse(json['date']), // Parse the date string into a DateTime object
      results: (json['results'] as List<dynamic>)
          .map((resultJson) => ExerciseResult.fromJson(resultJson))
          .toList(), // Convert each result JSON into an ExerciseResult
    );
  }

  // Convert Workout to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(), // Convert DateTime to ISO 8601 string
      'results': results.map((result) => result.toJson()).toList(), // Convert each ExerciseResult to JSON
    };
  }
}
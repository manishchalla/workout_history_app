import 'exercise.dart';

class ExerciseResult {
  final Exercise exercise; // The exercise details (name, target output, unit)
  final int actualOutput; // The actual output achieved by the user
  final int? ranking; // Position in competitive workout for this exercise
  final int? teamTotal;

  ExerciseResult({
    required this.exercise,
    required this.actualOutput,
    this.ranking, // Add ranking
    this.teamTotal,
  });

  bool get isSuccessful => actualOutput >= exercise.targetOutput;

  // Factory method to create an ExerciseResult from JSON
  factory ExerciseResult.fromJson(Map<String, dynamic> json) {
    return ExerciseResult(
      exercise: Exercise.fromJson(json), // Use Exercise.fromJson to avoid mismatches
      actualOutput: json['actual_output'] as int? ?? 0, // Ensure proper casting
    );
  }

  // Convert ExerciseResult to JSON
  Map<String, dynamic> toJson() {
    return {
      ...exercise.toJson(), // Merge exercise JSON
      'actual_output': actualOutput,
    };
  }
}
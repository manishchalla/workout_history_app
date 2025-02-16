import 'exercise.dart';

class ExerciseResult {
  final Exercise exercise; // The exercise details (name, target output, unit)
  final int actualOutput; // The actual output achieved by the user

  ExerciseResult({
    required this.exercise,
    required this.actualOutput,
  });

  bool get isSuccessful => actualOutput >= exercise.targetOutput;

  // Factory method to create an ExerciseResult from JSON
  factory ExerciseResult.fromJson(Map<String, dynamic> json) {
    return ExerciseResult(
      exercise: Exercise(
        name: json['name'],
        targetOutput: json['target_output'] ?? 0, // Default to 0 if null
        unit: json['unit'] ?? 'repetitions', // Default to 'repetitions' if null
      ),
      actualOutput: json['actual_output'] ?? 0, // Default to 0 if null
    );
  }

  // Convert ExerciseResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': exercise.name,
      'target_output': exercise.targetOutput,
      'unit': exercise.unit,
      'actual_output': actualOutput,
    };
  }
}
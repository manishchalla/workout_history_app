import 'exercise.dart';

class ExerciseResult {
  final Exercise exercise;
  final int actualOutput;

  ExerciseResult({
    required this.exercise,
    required this.actualOutput,
  });

  bool get isSuccessful => actualOutput >= exercise.targetOutput;
}
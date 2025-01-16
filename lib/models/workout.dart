import 'exercise_result.dart';

class Workout {
  final DateTime date;
  final List<ExerciseResult> results;

  Workout({
    required this.date,
    required this.results,
  });

  int get totalExercises => results.length;
  int get successfulExercises => results.where((result) => result.isSuccessful).length;
}
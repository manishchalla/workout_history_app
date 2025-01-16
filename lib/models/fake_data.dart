import 'workout.dart';
import 'exercise.dart';
import 'exercise_result.dart';

final List<Workout> fakeWorkouts = [
  Workout(
    date: DateTime.now().subtract(Duration(days: 2)),
    results: [
      ExerciseResult(
        exercise: Exercise(name: "Push-ups", targetOutput: 20, unit: "repetitions"),
        actualOutput: 25,
      ),
      ExerciseResult(
        exercise: Exercise(name: "Plank", targetOutput: 60, unit: "seconds"),
        actualOutput: 45,
      ),
    ],
  ),
  Workout(
    date: DateTime.now().subtract(Duration(days: 1)),
    results: [
      ExerciseResult(
        exercise: Exercise(name: "Squats", targetOutput: 30, unit: "repetitions"),
        actualOutput: 35,
      ),
      ExerciseResult(
        exercise: Exercise(name: "Running", targetOutput: 1000, unit: "meters"),
        actualOutput: 1200,
      ),
    ],
  ),
];
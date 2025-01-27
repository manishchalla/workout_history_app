import 'exercise.dart';

class WorkoutPlan {
  final String name;
  final List<Exercise> exercises;

  WorkoutPlan({
    required this.name,
    required this.exercises,
  });
}

final WorkoutPlan exampleWorkoutPlan = WorkoutPlan(
  name: "Full Body Workout",
  exercises: [
    Exercise(name: "Push-ups", targetOutput: 20, unit: "repetitions"),
    Exercise(name: "Plank", targetOutput: 60, unit: "seconds"),
    Exercise(name: "Squats", targetOutput: 30, unit: "repetitions"),
    Exercise(name: "Running", targetOutput: 1000, unit: "meters"),
    Exercise(name: "Pull-ups", targetOutput: 10, unit: "repetitions"),
    Exercise(name: "Burpees", targetOutput: 15, unit: "repetitions"),
    Exercise(name: "Lunges", targetOutput: 20, unit: "repetitions"),
  ],
);

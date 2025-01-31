import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_app/pages/workout_history_page.dart';
import 'package:workout_app/providers/workout_provider.dart';
import 'package:workout_app/models/workout.dart';
import 'package:workout_app/models/exercise_result.dart';
import 'package:workout_app/models/exercise.dart';

void main() {
  testWidgets('WorkoutHistoryPage displays multiple workouts', (WidgetTester tester) async {
    // Arrange: Create mock data for WorkoutProvider
    final provider = WorkoutProvider();
    provider.addWorkout(Workout(
      date: DateTime.now().subtract(Duration(days: 1)),
      results: [
        ExerciseResult(
          exercise: Exercise(name: 'Push-ups', targetOutput: 20, unit: 'repetitions'),
          actualOutput: 25,
        ),
      ],
    ));
    provider.addWorkout(Workout(
      date: DateTime.now().subtract(Duration(days: 2)),
      results: [
        ExerciseResult(
          exercise: Exercise(name: 'Plank', targetOutput: 60, unit: 'seconds'),
          actualOutput: 70,
        ),
      ],
    ));

    // Act: Render the WorkoutHistoryPage with the provider
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => provider,
        child: MaterialApp(
          home: WorkoutHistoryPage(),
        ),
      ),
    );

    // Assert: Verify that workouts are displayed
    expect(find.textContaining('Workout on'), findsNWidgets(2));
    expect(find.textContaining('1/1 exercises completed'), findsNWidgets(2));
  });
}

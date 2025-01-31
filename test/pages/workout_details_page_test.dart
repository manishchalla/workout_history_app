import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app/pages/workout_details_page.dart';
import 'package:workout_app/models/workout.dart';
import 'package:workout_app/models/exercise_result.dart';
import 'package:workout_app/models/exercise.dart';

void main() {
  testWidgets('WorkoutDetailsPage shows correct exercise details', (WidgetTester tester) async {
    // Arrange: Create a mock workout
    final mockWorkout = Workout(
      date: DateTime.now(),
      results: [
        ExerciseResult(
          exercise: Exercise(name: 'Push-ups', targetOutput: 20, unit: 'repetitions'),
          actualOutput: 25,
        ),
        ExerciseResult(
          exercise: Exercise(name: 'Plank', targetOutput: 60, unit: 'seconds'),
          actualOutput: 45,
        ),
      ],
    );

    // Act: Render the WorkoutDetailsPage
    await tester.pumpWidget(
      MaterialApp(
        home: WorkoutDetailsPage(workout: mockWorkout),
      ),
    );

    // Assert: Verify details for each exercise
    expect(find.text('Push-ups'), findsOneWidget);
    expect(find.text('Target: 20 repetitions, Actual: 25'), findsOneWidget);
    expect(find.text('Success'), findsOneWidget);

    expect(find.text('Plank'), findsOneWidget);
    expect(find.text('Target: 60 seconds, Actual: 45'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
  });
}

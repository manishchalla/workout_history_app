import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_app/pages/workout_recording_page.dart';
import 'package:workout_app/providers/workout_provider.dart';
import 'package:workout_app/models/workout_plan.dart';
import 'package:workout_app/models/exercise.dart';

void main() {
  testWidgets('WorkoutRecordingPage displays inputs for each exercise', (WidgetTester tester) async {
    // Arrange: Create a test WorkoutPlan
    final testWorkoutPlan = WorkoutPlan(
      name: 'Test Plan',
      exercises: [
        Exercise(name: 'Push-ups', targetOutput: 20, unit: 'repetitions'),
        Exercise(name: 'Plank', targetOutput: 60, unit: 'seconds'),
        Exercise(name: 'Running', targetOutput: 1000, unit: 'meters'),
      ],
    );

    // Act: Render the WorkoutRecordingPage with the test provider
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WorkoutProvider(),
        child: MaterialApp(
          home: WorkoutRecordingPage(workoutPlan: testWorkoutPlan),
        ),
      ),
    );

    // Assert: Verify that each exercise has an input field
    for (var exercise in testWorkoutPlan.exercises) {
      expect(find.text(exercise.name), findsOneWidget); // Exercise name
      expect(find.byType(TextField), findsNWidgets(testWorkoutPlan.exercises.length)); // Input fields
    }
  });

  testWidgets('WorkoutRecordingPage adds workout to shared state', (WidgetTester tester) async {
    // Arrange: Create a test WorkoutPlan and a WorkoutProvider
    final testWorkoutPlan = WorkoutPlan(
      name: 'Test Plan',
      exercises: [
        Exercise(name: 'Push-ups', targetOutput: 20, unit: 'repetitions'),
        Exercise(name: 'Plank', targetOutput: 60, unit: 'seconds'),
      ],
    );
    final provider = WorkoutProvider();

    // Act: Render the WorkoutRecordingPage
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => provider,
        child: MaterialApp(
          home: WorkoutRecordingPage(workoutPlan: testWorkoutPlan),
        ),
      ),
    );

    // Fill out inputs
    for (var exercise in testWorkoutPlan.exercises) {
      final textField = find.widgetWithText(TextField, exercise.unit);
      await tester.enterText(textField, '25'); // Enter output for each exercise
    }

    // Submit the workout
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Assert: Verify the workout was added to the provider
    expect(provider.workouts.length, 1);
    expect(provider.workouts.first.results.length, testWorkoutPlan.exercises.length);
  });
}

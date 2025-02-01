import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_app/models/exercise.dart';
import 'package:workout_app/models/workout_plan.dart';
import 'package:workout_app/pages/workout_recording_page.dart';
import 'package:workout_app/providers/workout_provider.dart';

void main() {
  testWidgets('WorkoutRecordingPage displays input fields for each exercise', (WidgetTester tester) async {
    final workoutPlan = WorkoutPlan(
      name: "Test Plan",
      exercises: [
        Exercise(name: "Push-ups", targetOutput: 20, unit: "repetitions"),
        Exercise(name: "Plank", targetOutput: 60, unit: "seconds"),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WorkoutProvider(),
        child: MaterialApp(home: WorkoutRecordingPage(workoutPlan: workoutPlan)),
      ),
    );

    for (var exercise in workoutPlan.exercises) {
      expect(find.text(exercise.name), findsOneWidget);
    }

    expect(find.byType(TextField), findsNWidgets(workoutPlan.exercises.length));
  });

  testWidgets('WorkoutRecordingPage adds a Workout to the shared state when submitted', (WidgetTester tester) async {
    final workoutPlan = WorkoutPlan(
      name: "Test Workout",
      exercises: [
        Exercise(name: "Push-ups", targetOutput: 20, unit: "repetitions"),
        Exercise(name: "Plank", targetOutput: 60, unit: "seconds"),
      ],
    );

    final provider = WorkoutProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(home: WorkoutRecordingPage(workoutPlan: workoutPlan)),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), '25');
    await tester.enterText(find.byType(TextField).at(1), '70');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Workout'));
    await tester.pumpAndSettle();

    expect(provider.workouts.length, 1);
    expect(provider.workouts.first.results[0].actualOutput, 25);
    expect(provider.workouts.first.results[1].actualOutput, 70);
  });
}

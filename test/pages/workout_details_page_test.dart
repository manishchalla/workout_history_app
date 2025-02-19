import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_app/models/exercise.dart';
import 'package:workout_app/models/workout_plan.dart';
import 'package:workout_app/pages/workout_details_page.dart';
import 'package:workout_app/providers/workout_provider.dart';
import '../mocks.mocks.dart'; // Import the generated mock classes

void main() {
  late MockWorkoutProvider mockWorkoutProvider;

  setUp(() {
    mockWorkoutProvider = MockWorkoutProvider();
  });

  Widget buildTestableWidget(Widget child) {
    return ChangeNotifierProvider<WorkoutProvider>.value(
      value: mockWorkoutProvider,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('WorkoutDetailsPage Tests', () {
    testWidgets('Shows separate input for each exercise', (WidgetTester tester) async {
      // Arrange
      final workoutPlan = WorkoutPlan(
        name: 'Plan 1',
        exercises: [
          Exercise(name: 'Push-ups', targetOutput: 20, unit: 'repetitions'),
          Exercise(name: 'Squats', targetOutput: 30, unit: 'seconds'),
          Exercise(name: 'Running', targetOutput: 500, unit: 'meters'),
        ],
      );

      // Act
      await tester.pumpWidget(buildTestableWidget(WorkoutDetailsPage(workoutPlan: workoutPlan)));

      // Assert
      expect(find.byType(TextField), findsNWidgets(1)); // Only Squats has a TextField
      expect(find.byType(Slider), findsNWidgets(1)); // Running uses a Slider
      expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(1)); // Push-ups uses increment buttons
    });
    
    testWidgets('Validates inputs and shows error messages for invalid values', (WidgetTester tester) async {
      // Arrange
      final workoutPlan = WorkoutPlan(
        name: 'Plan 1',
        exercises: [
          Exercise(name: 'Push-ups', targetOutput: 20, unit: 'repetitions'),
          Exercise(name: 'Squats', targetOutput: 30, unit: 'seconds'),
        ],
      );

      // Act
      await tester.pumpWidget(buildTestableWidget(WorkoutDetailsPage(workoutPlan: workoutPlan)));

      // Enter invalid input for Squats
      await tester.enterText(find.byType(TextField), '-5'); // Invalid value
      await tester.tap(find.text('Save Workout'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error in Squats: Value must be between 0 and 30'), findsOneWidget);
    });
  });
}
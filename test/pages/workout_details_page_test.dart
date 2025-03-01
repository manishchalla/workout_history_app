import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:workout_app/models/exercise.dart';
import 'package:workout_app/models/workout_plan.dart';
import 'package:workout_app/pages/workout_details_page.dart';
import 'package:workout_app/providers/workout_provider.dart';
import '../mocks.mocks.dart';

void main() {
  late MockWorkoutProvider mockWorkoutProvider;

  setUp(() {
    mockWorkoutProvider = MockWorkoutProvider();
  });

  Widget buildTestableWidget(Widget child) {
    return ChangeNotifierProvider<WorkoutProvider>.value(
      value: mockWorkoutProvider,
      child: MaterialApp(
        home: ScaffoldMessenger( // ✅ Ensures Snackbar appears
          child: Scaffold(
            body: child,
          ),
        ),
      ),
    );
  }

  group('WorkoutDetailsPage Tests', () {
    testWidgets('WorkoutDetailsPage saves workout and adds to provider', (WidgetTester tester) async {
      // Arrange
      final workoutPlan = WorkoutPlan(
        name: 'Plan 1',
        exercises: [
          Exercise(name: 'Push-ups', targetOutput: 20, unit: 'repetitions'),
          Exercise(name: 'Squats', targetOutput: 30, unit: 'seconds'),
        ],
      );

      when(mockWorkoutProvider.addWorkout(any)).thenAnswer((_) async => Future.value());

      await tester.pumpWidget(buildTestableWidget(WorkoutDetailsPage(workoutPlan: workoutPlan)));

      // Act
      await tester.tap(find.byIcon(Icons.add_circle_outline)); // Increase Push-ups count
      await tester.enterText(find.byType(TextField), '25'); // Set Squats to valid value
      await tester.tap(find.text('Save Workout'));

      await tester.pump(const Duration(seconds: 2)); // ✅ Wait for Snackbar

      // Assert
      verify(mockWorkoutProvider.addWorkout(any)).called(1); // ✅ Ensure workout was saved

      // ✅ Check if Snackbar appears
      expect(find.byType(SnackBar), findsOneWidget);

      // ✅ Alternative check: find text inside the Snackbar
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Workout saved successfully!'),
        ),
        findsOneWidget,
      );
    });
  });
}

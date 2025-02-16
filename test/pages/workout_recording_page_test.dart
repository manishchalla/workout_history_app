import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:workout_app/models/exercise.dart';
import 'package:workout_app/models/workout_plan.dart';
import 'package:workout_app/pages/workout_details_page.dart';
import 'package:workout_app/pages/workout_recording_page.dart';
import 'package:workout_app/providers/workout_provider.dart';
import '../mocks.mocks.dart'; // Import the generated mock classes

void main() {
  late MockWorkoutProvider mockWorkoutProvider;

  setUp(() {
    mockWorkoutProvider = MockWorkoutProvider();
  });

  Widget _buildTestableWidget(Widget child) {
    return ChangeNotifierProvider<WorkoutProvider>.value(
      value: mockWorkoutProvider,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('WorkoutRecordingPage Tests', () {
    testWidgets('Displays saved workout plans', (WidgetTester tester) async {
      // Arrange
      final savedPlans = [
        WorkoutPlan(name: 'Plan 1', exercises: []),
        WorkoutPlan(name: 'Plan 2', exercises: []),
      ];
      when(mockWorkoutProvider.savedWorkoutPlans).thenReturn(savedPlans);

      // Act
      await tester.pumpWidget(_buildTestableWidget(WorkoutRecordingPage()));

      // Assert
      expect(find.text('Plan 1'), findsOneWidget);
      expect(find.text('Plan 2'), findsOneWidget);
    });

    testWidgets('Navigates to WorkoutDetailsPage when a plan is selected', (WidgetTester tester) async {
      // Arrange
      final savedPlans = [
        WorkoutPlan(
          name: 'Plan 1',
          exercises: [
            Exercise(name: 'Push-ups', targetOutput: 20, unit: 'repetitions'),
            Exercise(name: 'Squats', targetOutput: 30, unit: 'repetitions'),
          ],
        ),
      ];
      when(mockWorkoutProvider.savedWorkoutPlans).thenReturn(savedPlans);

      // Act
      await tester.pumpWidget(_buildTestableWidget(WorkoutRecordingPage()));
      await tester.tap(find.text('Start Workout')); // Tap the "Start Workout" button
      await tester.pumpAndSettle(); // Wait for navigation to complete

      // Assert
      expect(find.byType(WorkoutDetailsPage), findsOneWidget); // Verify navigation
    });

    testWidgets('Deletes a workout plan when the delete icon is pressed', (WidgetTester tester) async {
      // Arrange
      final savedPlans = [
        WorkoutPlan(
          id: 1,
          name: 'Plan 1',
          exercises: [],
        ),
      ];
      when(mockWorkoutProvider.savedWorkoutPlans).thenReturn(savedPlans);

      // Act
      await tester.pumpWidget(_buildTestableWidget(WorkoutRecordingPage()));
      await tester.tap(find.byIcon(Icons.delete)); // Tap the delete icon
      await tester.pumpAndSettle(); // Wait for the delete operation to complete

      // Assert
      verify(mockWorkoutProvider.deleteWorkoutPlan(1)).called(1); // Verify that deleteWorkoutPlan was called
    });
  });
}
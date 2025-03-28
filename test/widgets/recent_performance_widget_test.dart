import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:workout_app/models/exercise.dart';
import 'package:workout_app/models/exercise_result.dart';
import 'package:workout_app/models/workout.dart';
import 'package:workout_app/widgets/recent_performance_widget.dart';
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
        home: Scaffold(body: child),
      ),
    );
  }

  group('RecentPerformanceWidget Tests', () {
    testWidgets('Displays performance metrics when workouts exist', (WidgetTester tester) async {
      // Arrange
      final workouts = [
        Workout(
          id: 1,
          date: DateTime.now(),
          results: [
            ExerciseResult(
              exercise: Exercise(name: 'Push-ups', targetOutput: 20, unit: 'repetitions'),
              actualOutput: 20, // Successful
            ),
            ExerciseResult(
              exercise: Exercise(name: 'Squats', targetOutput: 30, unit: 'seconds'),
              actualOutput: 30, // Successful
            ),
          ],
        ),
      ];
      when(mockWorkoutProvider.recentWorkouts).thenReturn(workouts);

      // Act
      await tester.pumpWidget(buildTestableWidget(const RecentPerformanceWidget()));

      // Assert
      expect(find.text('Last 7 Days Performance'), findsOneWidget);
      expect(find.text('Successful Exercises: 2 / 2'), findsOneWidget);
      expect(find.text('100.0% Success'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget); // Ensure progress bar exists
    });

    testWidgets('Displays default message when no workouts exist', (WidgetTester tester) async {
      // Arrange
      when(mockWorkoutProvider.recentWorkouts).thenReturn([]); // No workouts

      // Act
      await tester.pumpWidget(buildTestableWidget(const RecentPerformanceWidget()));

      // Assert
      expect(find.text('No Recent Performance.'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing); // No progress bar should be shown
    });
  });
}

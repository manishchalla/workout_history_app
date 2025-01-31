import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_app/pages/recent_performance_page.dart';
import 'package:workout_app/providers/workout_provider.dart';
import 'package:workout_app/models/workout.dart';
import 'package:workout_app/models/exercise_result.dart';
import 'package:workout_app/models/exercise.dart';

void main() {
  testWidgets('RecentPerformanceWidget displays metrics for recent workouts', (WidgetTester tester) async {
    // Arrange: Create mock data for WorkoutProvider
    final provider = WorkoutProvider();
    provider.addWorkout(Workout(
      date: DateTime.now().subtract(Duration(days: 1)),
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
    ));

    provider.addWorkout(Workout(
      date: DateTime.now().subtract(Duration(days: 3)),
      results: [
        ExerciseResult(
          exercise: Exercise(name: 'Running', targetOutput: 1000, unit: 'meters'),
          actualOutput: 1200,
        ),
      ],
    ));

    // Act: Render the RecentPerformanceWidget
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => provider,
        child: MaterialApp(
          home: Scaffold(
            body: RecentPerformanceWidget(),
          ),
        ),
      ),
    );

    // Assert: Verify metrics are displayed correctly
    expect(find.textContaining('Last 7 Days Performance'), findsOneWidget);
    expect(find.textContaining('Total Exercises: 3'), findsOneWidget);
    expect(find.textContaining('Successful Exercises: 2'), findsOneWidget);
  });

  testWidgets('RecentPerformanceWidget displays default message with no workouts', (WidgetTester tester) async {
    // Arrange: Create an empty WorkoutProvider
    final provider = WorkoutProvider();

    // Act: Render the RecentPerformanceWidget
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => provider,
        child: MaterialApp(
          home: Scaffold(
            body: RecentPerformanceWidget(),
          ),
        ),
      ),
    );

    // Assert: Verify default message is displayed
    expect(find.text('No workouts recorded in the last 7 days.'), findsOneWidget);
  });
}

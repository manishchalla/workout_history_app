import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_app/models/exercise.dart';
import 'package:workout_app/models/exercise_result.dart';
import 'package:workout_app/models/workout.dart';
import 'package:workout_app/providers/workout_provider.dart';
import 'package:workout_app/widgets/recent_performance_widget.dart';

void main() {
  testWidgets('RecentPerformanceWidget displays correct metrics from WorkoutProvider',
          (WidgetTester tester) async {
        // Arrange: Create a WorkoutProvider with recent workouts
        final provider = WorkoutProvider();
        provider.addWorkout(Workout(
          date: DateTime.now().subtract(Duration(days: 1)), // Recent workout
          results: [
            ExerciseResult(
              exercise: Exercise(name: "Push-ups", targetOutput: 20, unit: "repetitions"),
              actualOutput: 25, // Success
            ),
            ExerciseResult(
              exercise: Exercise(name: "Plank", targetOutput: 60, unit: "seconds"),
              actualOutput: 40, // Fail
            ),
          ],
        ));

        provider.addWorkout(Workout(
          date: DateTime.now().subtract(Duration(days: 3)), // Another recent workout
          results: [
            ExerciseResult(
              exercise: Exercise(name: "Squats", targetOutput: 30, unit: "repetitions"),
              actualOutput: 30, // Success
            ),
          ],
        ));

        // Act: Render RecentPerformanceWidget inside a provider
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: provider,
            child: MaterialApp(
              home: Scaffold(body: RecentPerformanceWidget()),
            ),
          ),
        );

        // Assert: Check if correct performance values are displayed
        expect(find.textContaining('Last 7 Days Performance'), findsOneWidget);
        expect(find.textContaining('2 / 3'), findsOneWidget); // 2 successful exercises out of 3
        expect(find.textContaining('% Success'), findsOneWidget); // Percentage displayed
        expect(find.byType(LinearProgressIndicator), findsOneWidget); // Progress bar exists
      });

  testWidgets('RecentPerformanceWidget displays default message when no workouts exist in the last 7 days',
          (WidgetTester tester) async {
        // Arrange: Create a WorkoutProvider with workouts older than 7 days
        final provider = WorkoutProvider();
        provider.addWorkout(Workout(
          date: DateTime.now().subtract(Duration(days: 10)), // Older than 7 days
          results: [
            ExerciseResult(
              exercise: Exercise(name: "Push-ups", targetOutput: 20, unit: "repetitions"),
              actualOutput: 25,
            ),
          ],
        ));

        // Act: Render RecentPerformanceWidget inside a provider
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: provider,
            child: MaterialApp(
              home: Scaffold(body: RecentPerformanceWidget()),
            ),
          ),
        );

        // Assert: Check if the default message appears
        expect(find.text('No Recent Performance.'), findsOneWidget);

        // Ensure that no success percentage or progress bar is displayed
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.textContaining('% Success'), findsNothing);
      });
}

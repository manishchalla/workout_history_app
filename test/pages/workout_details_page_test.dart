import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_app/models/exercise.dart';
import 'package:workout_app/models/exercise_result.dart';
import 'package:workout_app/models/workout.dart';
import 'package:workout_app/pages/workout_details_page.dart';
import 'package:workout_app/providers/workout_provider.dart';

void main() {
  testWidgets('WorkoutDetailsPage displays exercise details correctly',
          (WidgetTester tester) async {
        // Arrange: Create a sample workout with exercises
        final workout = Workout(
          date: DateTime.now().subtract(Duration(days: 1)),
          results: [
            ExerciseResult(
              exercise: Exercise(name: "Push-ups", targetOutput: 20, unit: "repetitions"),
              actualOutput: 25,
            ),
            ExerciseResult(
              exercise: Exercise(name: "Plank", targetOutput: 60, unit: "seconds"),
              actualOutput: 70,
            ),
          ],
        );

        // Create WorkoutProvider and add the workout (to prevent errors in RecentPerformanceWidget)
        final provider = WorkoutProvider();
        provider.addWorkout(workout);

        // Act: Render the WorkoutDetailsPage inside a ChangeNotifierProvider
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: provider,  // Provide WorkoutProvider
            child: MaterialApp(
              home: WorkoutDetailsPage(workout: workout),
            ),
          ),
        );

        // Assert: Verify that workout details are displayed correctly
        expect(find.text('Push-ups'), findsOneWidget);
        expect(find.text('Target: 20 repetitions, Actual: 25'), findsOneWidget);

        expect(find.text('Plank'), findsOneWidget);
        expect(find.text('Target: 60 seconds, Actual: 70'), findsOneWidget);

        // Check that "Success" or "Failed" status is displayed correctly
        expect(find.text('Success'), findsNWidgets(2)); // Both exercises met the target
      });
}

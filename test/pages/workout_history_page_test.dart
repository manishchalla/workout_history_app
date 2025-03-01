import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:workout_app/models/exercise.dart';
import 'package:workout_app/models/exercise_result.dart';
import 'package:workout_app/models/workout.dart';
import 'package:workout_app/pages/workout_history_page.dart';
import 'package:workout_app/providers/workout_provider.dart';
import '../mocks.mocks.dart';

/// Helper function to format date and time like in `WorkoutHistoryPage`
String formatWorkoutDateTime(DateTime date) {
  String formattedDate = '${date.day}/${date.month}/${date.year}';
  String formattedTime =
      '${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  return '$formattedDate at $formattedTime';
}

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

  group('WorkoutHistoryPage Tests', () {
    testWidgets('Displays default message when no workouts exist', (WidgetTester tester) async {
      // Arrange
      when(mockWorkoutProvider.workouts).thenReturn([]);

      // Act
      await tester.pumpWidget(buildTestableWidget(const WorkoutHistoryPage()));

      // Assert
      expect(find.text('No workouts recorded yet.'), findsOneWidget);
    });

    testWidgets('Displays multiple workouts correctly', (WidgetTester tester) async {
      // Arrange
      final workout1 = Workout(
        id: 1,
        date: DateTime(2024, 2, 18, 10, 30),
        results: [
          ExerciseResult(
            exercise: Exercise(name: 'Push-ups', targetOutput: 20, unit: 'repetitions'),
            actualOutput: 15,
          ),
        ],
      );

      final workout2 = Workout(
        id: 2,
        date: DateTime(2024, 2, 19, 18, 15),
        results: [
          ExerciseResult(
            exercise: Exercise(name: 'Squats', targetOutput: 30, unit: 'seconds'),
            actualOutput: 30,
          ),
        ],
      );

      when(mockWorkoutProvider.workouts).thenReturn([workout1, workout2]);

      // Act
      await tester.pumpWidget(buildTestableWidget(const WorkoutHistoryPage()));

      // Dynamically format expected values using the same logic as the UI
      final formattedWorkout1 = formatWorkoutDateTime(workout1.date);
      final formattedWorkout2 = formatWorkoutDateTime(workout2.date);

      // Assert
      expect(find.text(formattedWorkout1), findsOneWidget);
      expect(find.text(formattedWorkout2), findsOneWidget);

      // Check if multiple workouts exist
      expect(find.byType(ExpansionTile), findsNWidgets(2));
    });

    testWidgets('Expands workout details when tapped', (WidgetTester tester) async {
      final workout = Workout(
        id: 1,
        date: DateTime(2024, 2, 18),
        results: [
          ExerciseResult(
            exercise: Exercise(name: 'Push-ups', targetOutput: 20, unit: 'repetitions'),
            actualOutput: 15,
          ),
        ],
      );

      when(mockWorkoutProvider.workouts).thenReturn([workout]);

      await tester.pumpWidget(buildTestableWidget(const WorkoutHistoryPage()));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.text('Push-ups'), findsOneWidget);
      expect(find.text('Target: 20 repetitions'), findsOneWidget);
      expect(find.text('Actual: 15 repetitions'), findsOneWidget);
    });

    testWidgets('Shows success/failure icons based on workout results', (WidgetTester tester) async {
      // Arrange
      final workout = Workout(
        id: 1,
        date: DateTime(2024, 2, 18),
        results: [
          ExerciseResult(
              exercise: Exercise(name: 'Squats', targetOutput: 30, unit: 'seconds'),
              actualOutput: 30), // Success
          ExerciseResult(
              exercise: Exercise(name: 'Push-ups', targetOutput: 20, unit: 'repetitions'),
              actualOutput: 10), // Failure
        ],
      );

      when(mockWorkoutProvider.workouts).thenReturn([workout]);

      // Act
      await tester.pumpWidget(buildTestableWidget(const WorkoutHistoryPage()));

      // Tap expansion tile
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.check_circle), findsOneWidget); // Success icon for Squats
      expect(find.byIcon(Icons.cancel), findsOneWidget); // Failure icon for Push-ups
    });
  });
}

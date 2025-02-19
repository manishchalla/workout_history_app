import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:workout_app/pages/workout_history_page.dart';
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

  group('WorkoutHistoryPage Tests', () {

    testWidgets('Displays default message when no workouts exist',
            (WidgetTester tester) async {
          // Arrange
          when(mockWorkoutProvider.workouts).thenReturn([]);

          // Act
          await tester.pumpWidget(buildTestableWidget(const WorkoutHistoryPage()));

          // Assert
          expect(find.text('No workouts recorded yet.'), findsOneWidget);
        });
  });
}
import 'package:flutter/material.dart';
import '../models/workout.dart';

class WorkoutProvider with ChangeNotifier {
  final List<Workout> _workouts = [];

  List<Workout> get workouts => List.unmodifiable(_workouts);

  void addWorkout(Workout workout) {
    _workouts.add(workout);
    notifyListeners();
  }

  List<Workout> get recentWorkouts {
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
    return _workouts.where((w) => w.date.isAfter(sevenDaysAgo)).toList();
  }
}

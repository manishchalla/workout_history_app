import 'package:flutter/material.dart';
import 'package:workout_app/pages/workouts/join_workout_screen.dart';
import '../widgets/recent_performance_widget.dart'; // Import the RecentPerformanceWidget
import 'download_workout_plan_page.dart';
import 'workout_history_page.dart';
import 'workout_recording_page.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  _HomeLayoutState createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  int _selectedIndex = 0; // Tracks the currently selected tab

  // List of pages corresponding to each tab
  final List<Widget> _pages = [
    WorkoutRecordingPage(), // Tab 1: Record a new workout
    WorkoutHistoryPage(),   // Tab 2: View workout history
    DownloadWorkoutPlanPage(), // Tab 3: Download new workout plans
  ];

  // Update the selected tab when the user taps on the navigation bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout App'), // Title of the app bar
      ),
      body: Column(
        children: [
          Expanded(
            child: _pages[_selectedIndex], // Display the selected page
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JoinWorkoutScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('Join Workout', style: TextStyle(fontSize: 16)),
            ),
          ),
          RecentPerformanceWidget(), // Persistent footer for recent performance
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Current selected tab
        onTap: _onItemTapped, // Handle tab selection
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Record Workout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Workout History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: 'Download Plans',
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
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
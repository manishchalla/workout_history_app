import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:workout_app/pages/workouts/workout_waiting_screen.dart';
import '../../models/exercise.dart';
import '../../models/workout_plan.dart';
import '../../services/firestore_service.dart';
import '../workout_details_page.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _processCode(String code) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Join the group workout
      final workoutData = await _firestoreService.joinGroupWorkout(code);

      // Extract the workout plan data
      final workoutPlanData = workoutData['workout_plan'];

      if (workoutPlanData == null) {
        throw Exception('Invalid workout data. Please try again with a valid invite code.');
      }

      // Create workout plan object
      final exercises = (workoutPlanData['exercises'] as List)
          .map((e) => Exercise(
        name: e['name'],
        targetOutput: (e['target'] as num).toInt(),
        unit: e['unit'],
      ))
          .toList();

      final workoutPlan = WorkoutPlan(
        name: workoutPlanData['name'],
        exercises: exercises,
      );

      // Determine workout type
      final workoutType = workoutData['type'] ?? 'Competitive';
      final status = workoutData['status'] as String? ?? 'waiting';

      if (status == 'waiting') {
        // Show waiting screen if the workout hasn't started yet
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutWaitingScreen(
              workoutPlan: workoutPlan,
              workoutType: workoutType,
              sharedKey: code,
            ),
          ),
        );
      } else {
        // Navigate to the workout details page if workout is active
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDetailsPage(
              workoutPlan: workoutPlan,
              workoutType: workoutType,
              sharedKey: code,
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close the scanner

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Could not join workout: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processCode(barcode.rawValue!);
                  return;
                }
              }
            },
          ),
          // QR code overlay
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.transparent,
                width: 0,
              ),
            ),
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Joining workout...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          // Instructions
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Position the QR code within the frame to scan',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
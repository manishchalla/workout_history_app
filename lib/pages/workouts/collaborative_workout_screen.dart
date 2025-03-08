import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import '../../models/workout_plan.dart';
import '../../services/firestore_service.dart';
import '../workout_details_page.dart';

class CollaborativeWorkoutScreen extends StatefulWidget {
  final WorkoutPlan workoutPlan;

  const CollaborativeWorkoutScreen({super.key, required this.workoutPlan});

  @override
  _CollaborativeWorkoutScreenState createState() => _CollaborativeWorkoutScreenState();
}

class _CollaborativeWorkoutScreenState extends State<CollaborativeWorkoutScreen> {
  late String _inviteCode;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isCreating = false;
  bool _isStarting = false;
  String? _workoutId;
  GlobalKey _qrKey = GlobalKey();
  StreamSubscription? _workoutSubscription;
  Map<String, dynamic>? _workoutData;

  @override
  void initState() {
    super.initState();
    // Generate a unique invite code
    _inviteCode = _firestoreService.generateInviteCode();
    _createWorkout();
  }

  Future<void> _createWorkout() async {
    try {
      // Create the workout in Firestore
      _workoutId = await _firestoreService.createGroupWorkout(
        workoutType: 'Collaborative',
        inviteCode: _inviteCode,
        workoutPlan: widget.workoutPlan,
      );

      // Listen for changes in participants
      _listenToWorkout();
    } catch (e) {
      print('Error creating workout: $e');
    }
  }

  void _listenToWorkout() {
    if (_workoutId == null) return;

    _workoutSubscription = FirebaseFirestore.instance
        .collection('group_workouts')
        .doc(_workoutId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _workoutData = snapshot.data();
        });
      }
    });
  }

  @override
  void dispose() {
    _workoutSubscription?.cancel();
    super.dispose();
  }

  void _copyInviteCode() {
    Clipboard.setData(ClipboardData(text: _inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareQrCode() async {
    try {
      // Capture QR code as image
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        // Save to temporary file
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/workout_invite_code.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());

        // Share the image
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Join my collaborative workout with code: $_inviteCode',
        );
      }
    } catch (e) {
      print('Error sharing QR code: $e');
    }
  }

  Future<void> _startWorkout() async {
    if (_workoutId == null) return;

    setState(() {
      _isStarting = true;
    });

    try {
      // Update workout status to active
      await _firestoreService.startWorkout(_workoutId!);

      // Navigate to the workout details page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutDetailsPage(
            workoutPlan: widget.workoutPlan,
            workoutType: 'Collaborative',
            sharedKey: _inviteCode,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isStarting = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    // Show confirmation dialog
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cancel Workout?'),
          content: Text('If you go back, this workout will be canceled and the invite code will no longer work.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Don't allow back navigation
              },
              child: Text('Stay'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Allow back navigation
              },
              child: Text('Cancel Workout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    // If user confirms, delete the workout
    if (shouldPop == true && _workoutId != null) {
      try {
        // Delete the workout from Firestore
        await FirebaseFirestore.instance
            .collection('group_workouts')
            .doc(_workoutId)
            .delete();
        print('Workout canceled: $_workoutId');
      } catch (e) {
        print('Error canceling workout: $e');
      }
    }

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Get participants from workout data
    Map<String, dynamic> participants = {};
    if (_workoutData != null && _workoutData!['participants'] != null) {
      participants = Map<String, dynamic>.from(_workoutData!['participants']);
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Collaborative Workout'),
          backgroundColor: Colors.blue,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.workoutPlan.name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),

                // Invite code section
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.group_add, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Invite Friends',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),

                        // QR Code (centered and larger)
                        Center(
                          child: Column(
                            children: [
                              RepaintBoundary(
                                key: _qrKey,
                                child: QrImageView(
                                  data: _inviteCode,
                                  version: QrVersions.auto,
                                  size: 150.0,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _shareQrCode,
                                icon: Icon(Icons.share, size: 16),
                                label: Text('Share', style: TextStyle(fontSize: 14)),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 8),
                        Text(
                          'Scan this QR code to join the workout',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Participants list
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.people, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Team Members',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              '${participants.length}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        Divider(),

                        // List of participants
                        ...participants.entries.map((entry) {
                          final userId = entry.key;
                          final userData = entry.value;
                          final isCreator = userData['is_creator'] == true;
                          final joinedAt = userData['joined_at'] as Timestamp?;
                          final joinTime = joinedAt != null
                              ? "${joinedAt.toDate().hour}:${joinedAt.toDate().minute.toString().padLeft(2, '0')}"
                              : "Unknown";

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCreator ? Colors.blue : Colors.grey[300],
                              child: Icon(
                                isCreator ? Icons.star : Icons.person,
                                color: isCreator ? Colors.white : Colors.grey[700],
                              ),
                            ),
                            title: Text(
                              isCreator ? (userId == _firestoreService.currentUserId ? "You (Host)" : "Host")
                                  : (userId == _firestoreService.currentUserId ? "You" : "Team Member"),
                              style: TextStyle(
                                fontWeight: isCreator ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text('Joined at $joinTime'),
                            dense: true,
                          );
                        }).toList(),

                        if (participants.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No one has joined yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Workout details section
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.fitness_center, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Workout Details',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'In a collaborative workout, everyone\'s results are combined! Work together to reach the targets.',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        SizedBox(height: 16),
                        Text('${widget.workoutPlan.exercises.length} Exercises:'),
                        SizedBox(height: 8),
                        ...widget.workoutPlan.exercises.map((exercise) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text('• ${exercise.name}: ${exercise.targetOutput} ${exercise.unit}'),
                        )),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Start button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_isStarting || _isCreating) ? null : _startWorkout,
                    icon: Icon(Icons.play_arrow),
                    label: Text(
                      _isStarting ? 'Starting...' : 'Start Workout',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),

                SizedBox(height: 8),
                Center(
                  child: Text(
                    'Once started, no one else can join',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
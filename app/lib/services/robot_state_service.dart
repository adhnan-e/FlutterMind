/// Centralized observable state for the robot's current pose, speed,
/// and gesture history.
///
/// Sits between the UI and [USBRobotService], providing a single source
/// of truth for the robot's logical state.
library;

import 'package:flutter/foundation.dart';
import '../models/robot_pose.dart';

/// Observable service that holds the robot's current state.
///
/// Widgets can listen to this via [ListenableBuilder] to reactively
/// rebuild when the pose, speed, or gesture history changes.
class RobotStateService extends ChangeNotifier {
  final RobotPose _currentPose = RobotPose();

  /// Global servo movement speed (1–10). Default is 5.
  int _speed = 5;

  /// History of recently executed gestures (most recent last).
  final List<String> _gestureHistory = [];

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// The current joint-angle state for all 22 servos.
  RobotPose get currentPose => _currentPose;

  /// Current global speed level (1 = slowest, 10 = fastest).
  int get speed => _speed;

  /// Read-only view of gesture execution history.
  List<String> get gestureHistory => List.unmodifiable(_gestureHistory);

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Update a single joint value by [jointName] and notify listeners.
  void setJoint(String jointName, int value) {
    switch (jointName) {
      case 'NECK_PAN':
        _currentPose.neckPan = value;
      case 'NECK_TILT':
        _currentPose.neckTilt = value;
      case 'R_SHOULDER_X':
        _currentPose.rShoulderX = value;
      case 'R_SHOULDER_Y':
        _currentPose.rShoulderY = value;
      case 'R_ELBOW':
        _currentPose.rElbow = value;
      case 'R_WRIST':
        _currentPose.rWrist = value;
      case 'R_THUMB':
        _currentPose.rThumb = value;
      case 'R_INDEX':
        _currentPose.rIndex = value;
      case 'R_MIDDLE':
        _currentPose.rMiddle = value;
      case 'R_RING':
        _currentPose.rRing = value;
      case 'R_PINKY':
        _currentPose.rPinky = value;
      case 'L_SHOULDER_X':
        _currentPose.lShoulderX = value;
      case 'L_SHOULDER_Y':
        _currentPose.lShoulderY = value;
      case 'L_ELBOW':
        _currentPose.lElbow = value;
      case 'L_WRIST':
        _currentPose.lWrist = value;
      case 'L_THUMB':
        _currentPose.lThumb = value;
      case 'L_INDEX':
        _currentPose.lIndex = value;
      case 'L_MIDDLE':
        _currentPose.lMiddle = value;
      case 'L_RING':
        _currentPose.lRing = value;
      case 'L_PINKY':
        _currentPose.lPinky = value;
      case 'SPINE_BEND':
        _currentPose.spineBend = value;
      case 'WAIST_ROTATE':
        _currentPose.waistRotate = value;
    }
    notifyListeners();
  }

  /// Update the global speed setting and notify listeners.
  void setSpeed(int newSpeed) {
    _speed = newSpeed.clamp(1, 10);
    notifyListeners();
  }

  /// Record a gesture execution in history.
  void recordGesture(String gestureName) {
    _gestureHistory.add(gestureName);
    if (_gestureHistory.length > 50) {
      _gestureHistory.removeAt(0);
    }
    notifyListeners();
  }

  /// Reset the pose to default neutral position.
  void resetPose() {
    _currentPose.resetToDefault();
    notifyListeners();
  }
}

/// Represents the complete joint-angle state for all 22 servos of the
/// FlutterMind humanoid robot.
///
/// Joint values are stored in degrees and ordered to match the POSE
/// protocol (see [docs/PROTOCOL.md]).
class RobotPose {
  /// Head: left/right rotation (0–180°, rest 90°).
  int neckPan = 90;

  /// Head: up/down tilt (60–120°, rest 90°).
  int neckTilt = 90;

  /// Right shoulder: forward/back (0–180°, rest 90°).
  int rShoulderX = 90;

  /// Right shoulder: raise/lower (0–180°, rest 90°).
  int rShoulderY = 90;

  /// Right elbow bend (0–150°, rest 90°).
  int rElbow = 90;

  /// Right wrist rotation (0–180°, rest 90°).
  int rWrist = 90;

  /// Right thumb (0–170°, rest 0°).
  int rThumb = 0;

  /// Right index finger (0–175°, rest 0°).
  int rIndex = 0;

  /// Right middle finger (0–175°, rest 0°).
  int rMiddle = 0;

  /// Right ring finger (0–175°, rest 0°).
  int rRing = 0;

  /// Right pinky finger (0–175°, rest 0°).
  int rPinky = 0;

  /// Left shoulder: forward/back (0–180°, rest 90°).
  int lShoulderX = 90;

  /// Left shoulder: raise/lower (0–180°, rest 90°).
  int lShoulderY = 90;

  /// Left elbow bend (0–150°, rest 90°).
  int lElbow = 90;

  /// Left wrist rotation (0–180°, rest 90°).
  int lWrist = 90;

  /// Left thumb (0–170°, rest 0°).
  int lThumb = 0;

  /// Left index finger (0–175°, rest 0°).
  int lIndex = 0;

  /// Left middle finger (0–175°, rest 0°).
  int lMiddle = 0;

  /// Left ring finger (0–175°, rest 0°).
  int lRing = 0;

  /// Left pinky finger (0–175°, rest 0°).
  int lPinky = 0;

  /// Torso forward/back bend (60–120°, rest 90°).
  int spineBend = 90;

  /// Torso twist left/right (45–135°, rest 90°).
  int waistRotate = 90;

  /// Safe joint limit constraints for all 22 joints.
  ///
  /// Each entry maps a canonical joint name to `[min, max]` angle limits.
  static const Map<String, List<int>> limits = {
    'NECK_PAN': [0, 180],
    'NECK_TILT': [60, 120],
    'R_SHOULDER_X': [0, 180],
    'R_SHOULDER_Y': [0, 180],
    'R_ELBOW': [0, 150],
    'R_WRIST': [0, 180],
    'R_THUMB': [0, 170],
    'R_INDEX': [0, 175],
    'R_MIDDLE': [0, 175],
    'R_RING': [0, 175],
    'R_PINKY': [0, 175],
    'L_SHOULDER_X': [0, 180],
    'L_SHOULDER_Y': [0, 180],
    'L_ELBOW': [0, 150],
    'L_WRIST': [0, 180],
    'L_THUMB': [0, 170],
    'L_INDEX': [0, 175],
    'L_MIDDLE': [0, 175],
    'L_RING': [0, 175],
    'L_PINKY': [0, 175],
    'SPINE_BEND': [60, 120],
    'WAIST_ROTATE': [45, 135],
  };

  RobotPose();

  // Create a copy of current pose
  RobotPose clone() {
    return RobotPose()
      ..neckPan = neckPan
      ..neckTilt = neckTilt
      ..rShoulderX = rShoulderX
      ..rShoulderY = rShoulderY
      ..rElbow = rElbow
      ..rWrist = rWrist
      ..rThumb = rThumb
      ..rIndex = rIndex
      ..rMiddle = rMiddle
      ..rRing = rRing
      ..rPinky = rPinky
      ..lShoulderX = lShoulderX
      ..lShoulderY = lShoulderY
      ..lElbow = lElbow
      ..lWrist = lWrist
      ..lThumb = lThumb
      ..lIndex = lIndex
      ..lMiddle = lMiddle
      ..lRing = lRing
      ..lPinky = lPinky
      ..spineBend = spineBend
      ..waistRotate = waistRotate;
  }

  // Convert to serial command string
  String toPoseCommand() {
    final list = [
      neckPan,
      neckTilt,
      rShoulderX,
      rShoulderY,
      rElbow,
      rWrist,
      rThumb,
      rIndex,
      rMiddle,
      rRing,
      rPinky,
      lShoulderX,
      lShoulderY,
      lElbow,
      lWrist,
      lThumb,
      lIndex,
      lMiddle,
      lRing,
      lPinky,
      spineBend,
      waistRotate,
    ];
    return "POSE:${list.join(',')}";
  }

  void resetToDefault() {
    neckPan = 90;
    neckTilt = 90;
    rShoulderX = 90;
    rShoulderY = 90;
    rElbow = 90;
    rWrist = 90;
    rThumb = 0;
    rIndex = 0;
    rMiddle = 0;
    rRing = 0;
    rPinky = 0;
    lShoulderX = 90;
    lShoulderY = 90;
    lElbow = 90;
    lWrist = 90;
    lThumb = 0;
    lIndex = 0;
    lMiddle = 0;
    lRing = 0;
    lPinky = 0;
    spineBend = 90;
    waistRotate = 90;
  }
}

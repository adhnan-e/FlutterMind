class RobotPose {
  // Ordered exactly as expected by the POSE protocol
  int neckPan = 90;
  int neckTilt = 90;
  int rShoulderX = 90;
  int rShoulderY = 90;
  int rElbow = 90;
  int rWrist = 90;
  int rThumb = 0;
  int rIndex = 0;
  int rMiddle = 0;
  int rRing = 0;
  int rPinky = 0;
  int lShoulderX = 90;
  int lShoulderY = 90;
  int lElbow = 90;
  int lWrist = 90;
  int lThumb = 0;
  int lIndex = 0;
  int lMiddle = 0;
  int lRing = 0;
  int lPinky = 0;
  int spineBend = 90;
  int waistRotate = 90;

  // Safe joint limit constraints
  static const int minFinger = 0;
  static const int maxFinger = 175;

  static const Map<String, List<int>> limits = {
    "NECK_PAN": [0, 180],
    "NECK_TILT": [60, 120],
    "R_SHOULDER_X": [0, 180],
    "R_SHOULDER_Y": [0, 180],
    "R_ELBOW": [0, 150],
    "R_WRIST": [0, 180],
    "R_THUMB": [0, 170],
    "L_SHOULDER_X": [0, 180],
    "L_SHOULDER_Y": [0, 180],
    "L_ELBOW": [0, 150],
    "L_WRIST": [0, 180],
    "L_THUMB": [0, 170],
    "SPINE_BEND": [60, 120],
    "WAIST_ROTATE": [45, 135],
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

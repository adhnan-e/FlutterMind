import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/robot_pose.dart';

void main() {
  group('RobotPose', () {
    late RobotPose pose;

    setUp(() {
      pose = RobotPose();
    });

    test('default values are neutral rest position', () {
      expect(pose.neckPan, 90);
      expect(pose.neckTilt, 90);
      expect(pose.rShoulderX, 90);
      expect(pose.rShoulderY, 90);
      expect(pose.rElbow, 90);
      expect(pose.rWrist, 90);
      expect(pose.rThumb, 0);
      expect(pose.rIndex, 0);
      expect(pose.rMiddle, 0);
      expect(pose.rRing, 0);
      expect(pose.rPinky, 0);
      expect(pose.lShoulderX, 90);
      expect(pose.lShoulderY, 90);
      expect(pose.lElbow, 90);
      expect(pose.lWrist, 90);
      expect(pose.lThumb, 0);
      expect(pose.lIndex, 0);
      expect(pose.lMiddle, 0);
      expect(pose.lRing, 0);
      expect(pose.lPinky, 0);
      expect(pose.spineBend, 90);
      expect(pose.waistRotate, 90);
    });

    test('toPoseCommand() generates correct 22-value string', () {
      final cmd = pose.toPoseCommand();
      expect(cmd, 'POSE:90,90,90,90,90,90,0,0,0,0,0,90,90,90,90,0,0,0,0,0,90,90');

      // Verify exactly 22 comma-separated values after POSE:
      final values = cmd.substring(5).split(',');
      expect(values.length, 22);
    });

    test('toPoseCommand() reflects changed values', () {
      pose.rElbow = 120;
      pose.rThumb = 170;
      pose.lIndex = 150;
      final cmd = pose.toPoseCommand();
      final values = cmd.substring(5).split(',');

      // Index 4 = r_elbow, index 6 = r_thumb, index 16 = l_index
      expect(values[4], '120');
      expect(values[6], '170');
      expect(values[16], '150');
    });

    test('clone() creates an independent copy', () {
      pose.rElbow = 45;
      pose.lThumb = 100;

      final cloned = pose.clone();

      expect(cloned.rElbow, 45);
      expect(cloned.lThumb, 100);

      // Modifying clone should not affect original
      cloned.rElbow = 90;
      expect(pose.rElbow, 45);
      expect(cloned.rElbow, 90);
    });

    test('resetToDefault() restores all joints to neutral', () {
      pose.neckPan = 45;
      pose.rElbow = 120;
      pose.rThumb = 170;
      pose.lIndex = 150;
      pose.spineBend = 100;
      pose.waistRotate = 60;

      pose.resetToDefault();

      expect(pose.neckPan, 90);
      expect(pose.rElbow, 90);
      expect(pose.rThumb, 0);
      expect(pose.lIndex, 0);
      expect(pose.spineBend, 90);
      expect(pose.waistRotate, 90);
    });

    test('limits map contains all 22 joints', () {
      expect(RobotPose.limits.length, 22);

      // Verify all expected keys are present
      final expectedJoints = [
        'NECK_PAN', 'NECK_TILT',
        'R_SHOULDER_X', 'R_SHOULDER_Y', 'R_ELBOW', 'R_WRIST',
        'R_THUMB', 'R_INDEX', 'R_MIDDLE', 'R_RING', 'R_PINKY',
        'L_SHOULDER_X', 'L_SHOULDER_Y', 'L_ELBOW', 'L_WRIST',
        'L_THUMB', 'L_INDEX', 'L_MIDDLE', 'L_RING', 'L_PINKY',
        'SPINE_BEND', 'WAIST_ROTATE',
      ];

      for (final joint in expectedJoints) {
        expect(
          RobotPose.limits.containsKey(joint),
          isTrue,
          reason: 'Missing limit for joint: $joint',
        );
      }
    });

    test('limits have valid min < max ranges', () {
      for (final entry in RobotPose.limits.entries) {
        expect(
          entry.value[0] < entry.value[1],
          isTrue,
          reason: '${entry.key}: min (${entry.value[0]}) must be < max (${entry.value[1]})',
        );
      }
    });
  });
}

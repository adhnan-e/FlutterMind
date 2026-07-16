import 'package:flutter/material.dart';
import '../services/usb_robot_service.dart';
import '../services/robot_state_service.dart';
import '../widgets/joint_slider.dart';

/// Manual joint calibration screen with individual sliders for all 22
/// joints, organized by body group, plus a global speed control.
class ManualControlScreen extends StatelessWidget {
  /// USB robot service for sending commands.
  final USBRobotService usbService;

  /// Robot state service holding the current pose.
  final RobotStateService robotState;

  const ManualControlScreen({
    super.key,
    required this.usbService,
    required this.robotState,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: robotState,
      builder: (context, _) {
        final pose = robotState.currentPose;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manual Joint Calibration',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Calibrate individual servo outputs directly.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Speed control
              _buildSpeedCard(),
              const SizedBox(height: 16),

              // Emergency stop
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    usbService.sendCommand('STOP');
                    robotState.resetPose();
                  },
                  icon: const Icon(Icons.emergency_rounded),
                  label: const Text('EMERGENCY STOP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Head
              _buildJointGroupCard('Head (Arduino 1)', [
                _slider('NECK_PAN', pose.neckPan),
                _slider('NECK_TILT', pose.neckTilt),
              ]),
              const SizedBox(height: 16),

              // Right Arm
              _buildJointGroupCard('Right Arm (Arduino 1)', [
                _slider('R_SHOULDER_X', pose.rShoulderX),
                _slider('R_SHOULDER_Y', pose.rShoulderY),
                _slider('R_ELBOW', pose.rElbow),
                _slider('R_WRIST', pose.rWrist),
              ]),
              const SizedBox(height: 16),

              // Right Hand — all 5 fingers
              _buildJointGroupCard('Right Hand (Arduino 1)', [
                _slider('R_THUMB', pose.rThumb),
                _slider('R_INDEX', pose.rIndex),
                _slider('R_MIDDLE', pose.rMiddle),
                _slider('R_RING', pose.rRing),
                _slider('R_PINKY', pose.rPinky),
              ]),
              const SizedBox(height: 16),

              // Left Arm
              _buildJointGroupCard('Left Arm (Arduino 2)', [
                _slider('L_SHOULDER_X', pose.lShoulderX),
                _slider('L_SHOULDER_Y', pose.lShoulderY),
                _slider('L_ELBOW', pose.lElbow),
                _slider('L_WRIST', pose.lWrist),
              ]),
              const SizedBox(height: 16),

              // Left Hand — all 5 fingers
              _buildJointGroupCard('Left Hand (Arduino 2)', [
                _slider('L_THUMB', pose.lThumb),
                _slider('L_INDEX', pose.lIndex),
                _slider('L_MIDDLE', pose.lMiddle),
                _slider('L_RING', pose.lRing),
                _slider('L_PINKY', pose.lPinky),
              ]),
              const SizedBox(height: 16),

              // Torso & Spine
              _buildJointGroupCard('Torso & Spine (Arduino 2)', [
                _slider('SPINE_BEND', pose.spineBend),
                _slider('WAIST_ROTATE', pose.waistRotate),
              ]),
            ],
          ),
        );
      },
    );
  }

  /// Build a [JointSlider] that updates state and sends the command.
  JointSlider _slider(String jointName, int value) {
    return JointSlider(
      jointName: jointName,
      value: value,
      onChanged: (val) {
        robotState.setJoint(jointName, val);
        usbService.sendCommand('JOINT:$jointName:$val');
      },
    );
  }

  Widget _buildJointGroupCard(String title, List<Widget> sliders) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const Divider(color: Color(0xFF2D2E32)),
            const SizedBox(height: 8),
            ...sliders,
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Movement Speed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.speed_rounded,
                    color: Color(0xFF7F5AF0), size: 20),
                const SizedBox(width: 12),
                Text(
                  'Speed: ${robotState.speed}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2CB67D),
                  ),
                ),
                Expanded(
                  child: Slider(
                    min: 1,
                    max: 10,
                    divisions: 9,
                    value: robotState.speed.toDouble(),
                    onChanged: (val) {
                      final level = val.round();
                      robotState.setSpeed(level);
                      usbService.sendCommand('SPEED:$level');
                    },
                  ),
                ),
              ],
            ),
            const Text(
              '1 = Very slow (precise)  •  5 = Normal  •  10 = Fast',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

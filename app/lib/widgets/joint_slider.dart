import 'package:flutter/material.dart';
import '../models/robot_pose.dart';

/// Reusable slider widget for controlling a single robot joint.
///
/// Displays the joint name, current angle value, and a slider constrained
/// to the joint's safe limits from [RobotPose.limits].
class JointSlider extends StatelessWidget {
  /// Canonical joint name (e.g. `R_ELBOW`, `NECK_PAN`).
  final String jointName;

  /// Current angle value in degrees.
  final int value;

  /// Callback when the user drags the slider to a new value.
  final ValueChanged<int> onChanged;

  const JointSlider({
    super.key,
    required this.jointName,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final limit = RobotPose.limits[jointName] ?? [0, 180];
    final double minVal = limit[0].toDouble();
    final double maxVal = limit[1].toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              jointName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '$value°',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: Color(0xFF2CB67D),
              ),
            ),
          ),
          Expanded(
            child: Slider(
              min: minVal,
              max: maxVal,
              value: value.toDouble().clamp(minVal, maxVal),
              onChanged: (val) => onChanged(val.round()),
            ),
          ),
        ],
      ),
    );
  }
}

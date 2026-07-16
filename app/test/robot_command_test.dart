import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/robot_command.dart';

void main() {
  group('RobotCommand serialization', () {
    test('JointCommand serializes correctly', () {
      const cmd = JointCommand(jointName: 'R_ELBOW', angle: 90);
      expect(cmd.serialize(), 'JOINT:R_ELBOW:90');
      expect(cmd.toString(), 'JOINT:R_ELBOW:90');
    });

    test('GestureCommand serializes correctly', () {
      const cmd = GestureCommand(gestureName: 'WAVE');
      expect(cmd.serialize(), 'GESTURE:WAVE');
    });

    test('PoseCommand serializes all 22 values', () {
      final angles = List.generate(22, (i) => i * 8);
      final cmd = PoseCommand(angles: angles);
      final serialized = cmd.serialize();

      expect(serialized.startsWith('POSE:'), isTrue);

      final values = serialized.substring(5).split(',');
      expect(values.length, 22);
      expect(values[0], '0');
      expect(values[21], '168');
    });

    test('SpeedCommand serializes with level', () {
      const cmd = SpeedCommand(level: 7);
      expect(cmd.serialize(), 'SPEED:7');
    });

    test('StopCommand serializes as STOP', () {
      const cmd = StopCommand();
      expect(cmd.serialize(), 'STOP');
    });

    test('PingCommand serializes as PING', () {
      const cmd = PingCommand();
      expect(cmd.serialize(), 'PING');
    });

    test('StatusCommand serializes as STATUS', () {
      const cmd = StatusCommand();
      expect(cmd.serialize(), 'STATUS');
    });

    test('HelloCommand serializes with default version', () {
      const cmd = HelloCommand();
      expect(cmd.serialize(), 'HELLO:FLUTTERMIND:v1.0');
    });

    test('HelloCommand serializes with custom version', () {
      const cmd = HelloCommand(version: 'v2.0');
      expect(cmd.serialize(), 'HELLO:FLUTTERMIND:v2.0');
    });
  });

  group('RobotCommand type exhaustiveness', () {
    test('all command types are sealed subtypes', () {
      // Verify the sealed hierarchy works for pattern matching
      final commands = <RobotCommand>[
        const JointCommand(jointName: 'R_ELBOW', angle: 90),
        const GestureCommand(gestureName: 'WAVE'),
        const PoseCommand(angles: []),
        const SpeedCommand(level: 5),
        const StopCommand(),
        const PingCommand(),
        const StatusCommand(),
        const HelloCommand(),
      ];

      for (final cmd in commands) {
        final label = switch (cmd) {
          JointCommand() => 'joint',
          GestureCommand() => 'gesture',
          PoseCommand() => 'pose',
          SpeedCommand() => 'speed',
          StopCommand() => 'stop',
          PingCommand() => 'ping',
          StatusCommand() => 'status',
          HelloCommand() => 'hello',
        };
        expect(label.isNotEmpty, isTrue);
      }
    });
  });
}

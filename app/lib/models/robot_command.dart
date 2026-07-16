/// Typed representation of serial commands sent between the Flutter app
/// and Arduino firmware over USB.
///
/// See [docs/PROTOCOL.md] for the full protocol reference.
library;

/// Base class for all robot commands.
///
/// Each subclass serialises to the newline-terminated ASCII format
/// expected by the Arduino firmware.
sealed class RobotCommand {
  const RobotCommand();

  /// Serialise this command to its wire-format string (without trailing `\n`).
  String serialize();

  @override
  String toString() => serialize();
}

/// Set a single joint to a specific angle.
///
/// Wire format: `JOINT:<jointName>:<angle>`
class JointCommand extends RobotCommand {
  /// The canonical joint name (e.g. `R_ELBOW`, `NECK_PAN`).
  final String jointName;

  /// Target angle in degrees (0–180).
  final int angle;

  const JointCommand({required this.jointName, required this.angle});

  @override
  String serialize() => 'JOINT:$jointName:$angle';
}

/// Execute a named gesture sequence stored in firmware.
///
/// Wire format: `GESTURE:<gestureName>`
class GestureCommand extends RobotCommand {
  /// One of the gesture names defined in the protocol
  /// (e.g. `WAVE`, `GRIP`, `REST`).
  final String gestureName;

  const GestureCommand({required this.gestureName});

  @override
  String serialize() => 'GESTURE:$gestureName';
}

/// Set all 22 joint angles in a single coordinated move.
///
/// Wire format: `POSE:<a0>,<a1>,...,<a21>`
class PoseCommand extends RobotCommand {
  /// Exactly 22 angles in the canonical order defined in PROTOCOL.md.
  final List<int> angles;

  const PoseCommand({required this.angles});

  @override
  String serialize() => 'POSE:${angles.join(',')}';
}

/// Set the global servo movement speed.
///
/// Wire format: `SPEED:<level>` where level is 1–10.
class SpeedCommand extends RobotCommand {
  /// Speed level: 1 (slowest) to 10 (fastest). Default is 5.
  final int level;

  const SpeedCommand({required this.level});

  @override
  String serialize() => 'SPEED:$level';
}

/// Emergency stop — halts all servo movement immediately.
///
/// Wire format: `STOP`
class StopCommand extends RobotCommand {
  const StopCommand();

  @override
  String serialize() => 'STOP';
}

/// Heartbeat ping to verify connection is alive.
///
/// Wire format: `PING`
class PingCommand extends RobotCommand {
  const PingCommand();

  @override
  String serialize() => 'PING';
}

/// Request Arduino status report.
///
/// Wire format: `STATUS`
class StatusCommand extends RobotCommand {
  const StatusCommand();

  @override
  String serialize() => 'STATUS';
}

/// Protocol version handshake sent on initial connection.
///
/// Wire format: `HELLO:FLUTTERMIND:<version>`
class HelloCommand extends RobotCommand {
  /// Protocol version string (e.g. `v1.0`).
  final String version;

  const HelloCommand({this.version = 'v1.0'});

  @override
  String serialize() => 'HELLO:FLUTTERMIND:$version';
}

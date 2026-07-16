/// Mock on-device AI decision service.
///
/// Parses natural-language voice/text commands and maps them to robot
/// [RobotCommand] strings. In a future phase this will be replaced with
/// real Gemma 4 E2B inference via LiteRT.
library;

import 'dart:async';

/// Result of an AI decision — a human-readable explanation plus an
/// optional serial command to dispatch.
class BrainDecision {
  /// Human-readable explanation of what the AI decided.
  final String reply;

  /// Serial command to send to the robot, or `null` if no physical
  /// action was identified.
  final String? command;

  const BrainDecision({required this.reply, this.command});
}

/// Service that processes natural-language queries and produces robot
/// commands.
///
/// Currently uses keyword matching as a placeholder. When Gemma 4 E2B
/// is integrated via LiteRT, only this class needs to change.
class LlmBrainService {
  /// Whether the real on-device model is loaded and ready.
  ///
  /// Always `false` in the current mock implementation.
  bool get isModelLoaded => false;

  /// Process a natural-language [query] and return a [BrainDecision].
  ///
  /// The returned [Future] simulates the ~1 second inference latency
  /// of a real on-device model.
  Future<BrainDecision> processQuery(String query) async {
    // Simulate inference latency
    await Future.delayed(const Duration(seconds: 1));

    final q = query.toLowerCase();

    // --- Gesture mappings ---
    if (q.contains('wave') || q.contains('hello')) {
      return const BrainDecision(
        reply: 'Decision: WAVE GESTURE. Dispatched command GESTURE:WAVE.',
        command: 'GESTURE:WAVE',
      );
    }
    if (q.contains('grip') || q.contains('close hand') || q.contains('fist')) {
      return const BrainDecision(
        reply: 'Decision: GRIP GESTURE. Dispatched command GESTURE:GRIP.',
        command: 'GESTURE:GRIP',
      );
    }
    if (q.contains('open hand') || q.contains('release')) {
      return const BrainDecision(
        reply: 'Decision: OPEN GESTURE. Dispatched command GESTURE:OPEN.',
        command: 'GESTURE:OPEN',
      );
    }
    if (q.contains('point')) {
      return const BrainDecision(
        reply: 'Decision: POINT GESTURE. Dispatched command GESTURE:POINT.',
        command: 'GESTURE:POINT',
      );
    }
    if (q.contains('pinch')) {
      return const BrainDecision(
        reply: 'Decision: PINCH GESTURE. Dispatched command GESTURE:PINCH.',
        command: 'GESTURE:PINCH',
      );
    }
    if (q.contains('peace') || q.contains('victory')) {
      return const BrainDecision(
        reply: 'Decision: PEACE GESTURE. Dispatched command GESTURE:PEACE.',
        command: 'GESTURE:PEACE',
      );
    }
    if (q.contains('clap')) {
      return const BrainDecision(
        reply: 'Decision: CLAP GESTURE. Dispatched command GESTURE:CLAP.',
        command: 'GESTURE:CLAP',
      );
    }
    if (q.contains('nod') || q.contains('yes')) {
      return const BrainDecision(
        reply: 'Decision: NOD GESTURE. Dispatched command GESTURE:NOD.',
        command: 'GESTURE:NOD',
      );
    }
    if (q.contains('thumbs up')) {
      return const BrainDecision(
        reply:
            'Decision: THUMBSUP GESTURE. Dispatched command GESTURE:THUMBSUP.',
        command: 'GESTURE:THUMBSUP',
      );
    }
    if (q.contains('rest') || q.contains('reset')) {
      return const BrainDecision(
        reply: 'Decision: REST GESTURE. Dispatched command GESTURE:REST.',
        command: 'GESTURE:REST',
      );
    }

    // --- Direct joint mappings ---
    // These must come before the "stop" and "shake" checks to avoid
    // false positives from substring matching.
    if (q.contains('look left')) {
      return const BrainDecision(
        reply: 'Decision: Turn head left. Dispatched JOINT:NECK_PAN:150.',
        command: 'JOINT:NECK_PAN:150',
      );
    }
    if (q.contains('look right')) {
      return const BrainDecision(
        reply: 'Decision: Turn head right. Dispatched JOINT:NECK_PAN:30.',
        command: 'JOINT:NECK_PAN:30',
      );
    }
    if (q.contains('look up')) {
      return const BrainDecision(
        reply: 'Decision: Tilt head up. Dispatched JOINT:NECK_TILT:60.',
        command: 'JOINT:NECK_TILT:60',
      );
    }
    if (q.contains('look down')) {
      return const BrainDecision(
        reply: 'Decision: Tilt head down. Dispatched JOINT:NECK_TILT:120.',
        command: 'JOINT:NECK_TILT:120',
      );
    }

    // --- Stop must come before 'shake head / no' to avoid matching 'no' in 'now' ---
    if (q.contains('stop')) {
      return const BrainDecision(
        reply: 'Decision: EMERGENCY STOP. Dispatched STOP command.',
        command: 'STOP',
      );
    }
    // Use word boundary to avoid matching 'no' inside words like 'now', 'know'
    if (q.contains('shake head') || RegExp(r'\bno\b').hasMatch(q)) {
      return const BrainDecision(
        reply: 'Decision: SHAKE GESTURE. Dispatched command GESTURE:SHAKE.',
        command: 'GESTURE:SHAKE',
      );
    }

    // --- Fallback ---
    return BrainDecision(
      reply:
          'Gemma Offline Brain: I heard "$query". I don\'t see any matching '
          'physical mapping for this command in my default database. You can '
          'try: \'wave hello\', \'close hand\', \'look left\', \'thumbs up\', '
          '\'peace\', \'clap\', or \'stop\'.',
    );
  }
}

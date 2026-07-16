import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/llm_brain_service.dart';

void main() {
  late LlmBrainService brain;

  setUp(() {
    brain = LlmBrainService();
  });

  group('LlmBrainService', () {
    test('isModelLoaded is false for mock implementation', () {
      expect(brain.isModelLoaded, isFalse);
    });

    test('recognizes wave command', () async {
      final decision = await brain.processQuery('wave hello');
      expect(decision.command, 'GESTURE:WAVE');
      expect(decision.reply, contains('WAVE'));
    });

    test('recognizes grip command', () async {
      final decision = await brain.processQuery('close hand');
      expect(decision.command, 'GESTURE:GRIP');
    });

    test('recognizes open hand command', () async {
      final decision = await brain.processQuery('release');
      expect(decision.command, 'GESTURE:OPEN');
    });

    test('recognizes point command', () async {
      final decision = await brain.processQuery('point at that');
      expect(decision.command, 'GESTURE:POINT');
    });

    test('recognizes peace command', () async {
      final decision = await brain.processQuery('peace sign');
      expect(decision.command, 'GESTURE:PEACE');
    });

    test('recognizes clap command', () async {
      final decision = await brain.processQuery('clap your hands');
      expect(decision.command, 'GESTURE:CLAP');
    });

    test('recognizes thumbs up command', () async {
      final decision = await brain.processQuery('thumbs up');
      expect(decision.command, 'GESTURE:THUMBSUP');
    });

    test('recognizes nod command', () async {
      final decision = await brain.processQuery('nod');
      expect(decision.command, 'GESTURE:NOD');
    });

    test('recognizes stop command', () async {
      final decision = await brain.processQuery('stop now');
      expect(decision.command, 'STOP');
    });

    test('recognizes look left command', () async {
      final decision = await brain.processQuery('look left');
      expect(decision.command, 'JOINT:NECK_PAN:150');
    });

    test('recognizes look right command', () async {
      final decision = await brain.processQuery('look right');
      expect(decision.command, 'JOINT:NECK_PAN:30');
    });

    test('recognizes look up command', () async {
      final decision = await brain.processQuery('look up');
      expect(decision.command, 'JOINT:NECK_TILT:60');
    });

    test('recognizes look down command', () async {
      final decision = await brain.processQuery('look down');
      expect(decision.command, 'JOINT:NECK_TILT:120');
    });

    test('returns null command for unrecognized input', () async {
      final decision = await brain.processQuery('fly to the moon');
      expect(decision.command, isNull);
      expect(decision.reply, contains("don't see any matching"));
    });

    test('handles case insensitivity', () async {
      final decision = await brain.processQuery('WAVE HELLO');
      expect(decision.command, 'GESTURE:WAVE');
    });
  });
}

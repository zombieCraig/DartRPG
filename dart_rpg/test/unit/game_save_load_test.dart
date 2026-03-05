import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/models/character.dart';
import 'package:dart_rpg/models/session.dart';
import 'package:dart_rpg/models/quest.dart';
import 'package:dart_rpg/models/clock.dart';
import 'package:dart_rpg/models/location.dart';
import 'package:dart_rpg/models/journal_entry.dart';

void main() {
  group('Game JSON roundtrip', () {
    test('empty game survives serialization', () {
      final game = Game(name: 'Test');
      final json = game.toJsonString();
      final restored = Game.fromJsonString(json);

      expect(restored.name, 'Test');
      expect(restored.id, game.id);
      expect(restored.tutorialsEnabled, true);
      expect(restored.sentientAiEnabled, false);
      expect(restored.aiImageGenerationEnabled, false);
    });

    test('game with characters roundtrips', () {
      final game = Game(name: 'Test');
      final char = Character(name: 'Runner', handle: 'r00t');
      game.addCharacter(char);

      final restored = Game.fromJsonString(game.toJsonString());

      expect(restored.characters.length, 1);
      expect(restored.characters.first.name, 'Runner');
      expect(restored.characters.first.handle, 'r00t');
      expect(restored.mainCharacter?.id, char.id);
    });

    test('game with sessions and journal entries roundtrips', () {
      final game = Game(name: 'Test');
      final session = game.createNewSession('Session 1');
      session.createNewEntry('First entry text');

      final restored = Game.fromJsonString(game.toJsonString());

      expect(restored.sessions.length, 1);
      expect(restored.sessions.first.title, 'Session 1');
      expect(restored.sessions.first.entries.length, 1);
      expect(restored.sessions.first.entries.first.content, 'First entry text');
    });

    test('game with quests roundtrips', () {
      final game = Game(name: 'Test');
      final char = Character(name: 'Runner');
      game.addCharacter(char);
      final quest = Quest(
        title: 'Hack the mainframe',
        characterId: char.id,
        rank: QuestRank.dangerous,
      );
      game.quests.add(quest);

      final restored = Game.fromJsonString(game.toJsonString());

      expect(restored.quests.length, 1);
      expect(restored.quests.first.title, 'Hack the mainframe');
      expect(restored.quests.first.rank, QuestRank.dangerous);
      expect(restored.quests.first.characterId, char.id);
    });

    test('game with clocks roundtrips', () {
      final game = Game(name: 'Test');
      final clock = Clock(title: 'Trace', segments: 6, type: ClockType.trace, progress: 3);
      game.addClock(clock);

      final restored = Game.fromJsonString(game.toJsonString());

      expect(restored.clocks.length, 1);
      expect(restored.clocks.first.title, 'Trace');
      expect(restored.clocks.first.segments, 6);
      expect(restored.clocks.first.type, ClockType.trace);
      expect(restored.clocks.first.progress, 3);
    });

    test('game with locations and connections roundtrips', () {
      final game = Game(name: 'Test');
      // Game creates "Your Rig" by default
      expect(game.locations.length, 1);

      final loc = Location(name: 'Server Room', segment: LocationSegment.corpNet);
      game.locations.add(loc);
      game.connectLocations(game.rigLocation!.id, loc.id);

      final restored = Game.fromJsonString(game.toJsonString());

      expect(restored.locations.length, 2);
      final restoredRig = restored.locations.firstWhere((l) => l.name == 'Your Rig');
      expect(restoredRig.connectedLocationIds, contains(loc.id));
    });

    test('AI config fields roundtrip', () {
      final game = Game(
        name: 'Test',
        sentientAiEnabled: true,
        sentientAiName: 'NEXUS',
        sentientAiPersona: 'sarcastic',
        aiImageGenerationEnabled: true,
        aiImageProvider: 'minimax',
        openaiModel: 'dall-e-3',
        aiApiKeys: {'minimax': 'key123'},
        aiArtisticDirections: {'minimax': 'neon cyberpunk'},
      );

      final restored = Game.fromJsonString(game.toJsonString());

      expect(restored.sentientAiEnabled, true);
      expect(restored.sentientAiName, 'NEXUS');
      expect(restored.sentientAiPersona, 'sarcastic');
      expect(restored.aiImageGenerationEnabled, true);
      expect(restored.aiImageProvider, 'minimax');
      expect(restored.openaiModel, 'dall-e-3');
      expect(restored.aiApiKeys['minimax'], 'key123');
      expect(restored.aiArtisticDirections['minimax'], 'neon cyberpunk');
    });

    test('selected truths roundtrip', () {
      final game = Game(
        name: 'Test',
        selectedTruths: {'truth1': 'option_a', 'truth2': null},
      );

      final restored = Game.fromJsonString(game.toJsonString());

      expect(restored.selectedTruths['truth1'], 'option_a');
      expect(restored.selectedTruths.containsKey('truth2'), true);
      expect(restored.selectedTruths['truth2'], isNull);
    });

    test('datasworn source roundtrips', () {
      final game = Game(name: 'Test', dataswornSource: 'fe_runners');

      final restored = Game.fromJsonString(game.toJsonString());

      expect(restored.dataswornSource, 'fe_runners');
    });
  });
}

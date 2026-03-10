import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/recent_move_entry.dart';
import 'package:dart_rpg/models/game.dart';

void main() {
  group('RecentMoveEntry', () {
    test('serializes to and from JSON', () {
      final entry = RecentMoveEntry(
        moveId: 'move_1',
        moveName: 'Face Danger',
        lastStat: 'Edge',
        useCount: 3,
        isFavorite: true,
      );

      final json = entry.toJson();
      final restored = RecentMoveEntry.fromJson(json);

      expect(restored.moveId, 'move_1');
      expect(restored.moveName, 'Face Danger');
      expect(restored.lastStat, 'Edge');
      expect(restored.useCount, 3);
      expect(restored.isFavorite, true);
    });

    test('handles null lastStat in JSON', () {
      final json = {
        'moveId': 'move_1',
        'moveName': 'Test Move',
        'lastStat': null,
        'useCount': 1,
        'lastUsed': DateTime.now().toIso8601String(),
        'isFavorite': false,
      };

      final entry = RecentMoveEntry.fromJson(json);
      expect(entry.lastStat, isNull);
    });
  });

  group('Game.recentMoves', () {
    late Game game;

    setUp(() {
      game = Game(name: 'Test Game');
    });

    test('starts with empty recent moves', () {
      expect(game.recentMoves, isEmpty);
    });

    test('recordMoveUse adds a new entry', () {
      game.recordMoveUse('move_1', 'Face Danger', 'Edge');

      expect(game.recentMoves.length, 1);
      expect(game.recentMoves.first.moveId, 'move_1');
      expect(game.recentMoves.first.moveName, 'Face Danger');
      expect(game.recentMoves.first.lastStat, 'Edge');
      expect(game.recentMoves.first.useCount, 1);
    });

    test('recordMoveUse updates existing entry', () {
      game.recordMoveUse('move_1', 'Face Danger', 'Edge');
      game.recordMoveUse('move_1', 'Face Danger', 'Shadow');

      expect(game.recentMoves.length, 1);
      expect(game.recentMoves.first.useCount, 2);
      expect(game.recentMoves.first.lastStat, 'Shadow');
    });

    test('recordMoveUse trims to maxRecentMoves', () {
      for (int i = 0; i < 15; i++) {
        game.recordMoveUse('move_$i', 'Move $i', 'Edge');
      }

      expect(game.recentMoves.length, Game.maxRecentMoves);
    });

    test('favorites are not trimmed', () {
      // Add a favorite first
      game.recordMoveUse('fav_move', 'Favorite Move', 'Edge');
      game.toggleMoveFavorite('fav_move');

      // Fill up to max with non-favorites
      for (int i = 0; i < 15; i++) {
        game.recordMoveUse('move_$i', 'Move $i', 'Edge');
      }

      // Favorite should still be present
      final favEntry = game.recentMoves.where((r) => r.moveId == 'fav_move');
      expect(favEntry.length, 1);
      expect(favEntry.first.isFavorite, true);
    });

    test('toggleMoveFavorite toggles favorite status', () {
      game.recordMoveUse('move_1', 'Face Danger', 'Edge');

      expect(game.recentMoves.first.isFavorite, false);

      game.toggleMoveFavorite('move_1');
      expect(game.recentMoves.first.isFavorite, true);

      game.toggleMoveFavorite('move_1');
      expect(game.recentMoves.first.isFavorite, false);
    });

    test('favoriteRecentMoves returns only favorites sorted by use count', () {
      game.recordMoveUse('move_1', 'Move 1', 'Edge');
      game.recordMoveUse('move_2', 'Move 2', 'Edge');
      game.recordMoveUse('move_2', 'Move 2', 'Edge'); // use count 2

      game.toggleMoveFavorite('move_1');
      game.toggleMoveFavorite('move_2');

      final favorites = game.favoriteRecentMoves;
      expect(favorites.length, 2);
      expect(favorites.first.moveId, 'move_2'); // Higher use count
    });

    test('nonFavoriteRecentMoves returns only non-favorites sorted by recency', () {
      game.recordMoveUse('move_1', 'Move 1', 'Edge');
      game.recordMoveUse('move_2', 'Move 2', 'Edge');
      game.toggleMoveFavorite('move_1');

      final nonFavorites = game.nonFavoriteRecentMoves;
      expect(nonFavorites.length, 1);
      expect(nonFavorites.first.moveId, 'move_2');
    });

    test('recentMoves round-trips through Game JSON', () {
      game.recordMoveUse('move_1', 'Face Danger', 'Edge');
      game.recordMoveUse('move_2', 'Secure an Advantage', 'Wits');
      game.toggleMoveFavorite('move_1');

      final json = game.toJson();
      final restored = Game.fromJson(json);

      expect(restored.recentMoves.length, 2);

      final fav = restored.recentMoves.firstWhere((r) => r.moveId == 'move_1');
      expect(fav.moveName, 'Face Danger');
      expect(fav.lastStat, 'Edge');
      expect(fav.isFavorite, true);

      final recent = restored.recentMoves.firstWhere((r) => r.moveId == 'move_2');
      expect(recent.moveName, 'Secure an Advantage');
      expect(recent.lastStat, 'Wits');
      expect(recent.isFavorite, false);
    });
  });
}

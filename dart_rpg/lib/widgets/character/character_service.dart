import '../../models/character.dart';
import '../../providers/game_provider.dart';

/// A service for character operations.
class CharacterService {
  final GameProvider gameProvider;

  CharacterService(this.gameProvider);

  /// Creates a new character.
  Future<Character?> createCharacter({
    required String name,
    String? handle,
    String? bio,
    String? imageUrl,
    bool isMainCharacter = false,
    List<CharacterStat>? stats,
  }) async {
    if (gameProvider.currentGame == null) {
      return null;
    }

    // Create the character using the GameProvider
    await gameProvider.createCharacter(
      name,
      isMainCharacter: isMainCharacter,
      handle: handle,
    );

    // Get the created character
    final character = gameProvider.currentGame!.characters.last;

    // Update additional properties
    character.bio = bio;
    character.imageUrl = imageUrl;

    // Update stats if provided
    if (stats != null && stats.isNotEmpty) {
      character.stats.clear();
      character.stats.addAll(stats);
    }

    // Set default values for key stats if it's a main character
    if (isMainCharacter) {
      character.momentum = 2;
      character.momentumReset = 2;
      character.health = 5;
      character.spirit = 5;
      character.supply = 5;

      // Ensure Base Rig asset is added
      if (character.assets.isEmpty) {
        character.assets.add(Asset.baseRig());
      }
    }

    // Save the changes
    gameProvider.saveGame();

    return character;
  }

  /// Updates an existing character.
  Future<bool> updateCharacter({
    required Character character,
    String? name,
    String? handle,
    String? bio,
    String? imageUrl,
    List<CharacterStat>? stats,
    int? momentum,
    int? health,
    int? spirit,
    int? supply,
    List<String>? notes,
    Map<String, bool>? impacts,
    List<Asset>? assets,
  }) async {
    if (gameProvider.currentGame == null) {
      return false;
    }

    // Find the character in the game
    final index = gameProvider.currentGame!.characters.indexWhere((c) => c.id == character.id);
    if (index == -1) {
      return false;
    }

    // Update character properties
    if (name != null) {
      character.name = name;
    }

    if (handle != null) {
      character.setHandle(handle);
    }

    if (bio != null) {
      character.bio = bio;
    }

    if (imageUrl != null) {
      character.imageUrl = imageUrl.isEmpty ? null : imageUrl;
    }

    // Update stats if provided
    if (stats != null && stats.isNotEmpty) {
      character.stats.clear();
      character.stats.addAll(stats);
    }

    // Update key stats if provided
    if (momentum != null) {
      character.momentum = momentum;
    }

    if (health != null) {
      character.health = health;
    }

    if (spirit != null) {
      character.spirit = spirit;
    }

    if (supply != null) {
      character.supply = supply;
    }

    // Update notes if provided
    if (notes != null) {
      character.notes = notes;
    }

    // Update impacts if provided
    if (impacts != null) {
      if (impacts.containsKey('wounded')) {
        character.impactWounded = impacts['wounded']!;
      }
      if (impacts.containsKey('shaken')) {
        character.impactShaken = impacts['shaken']!;
      }
      if (impacts.containsKey('unregulated')) {
        character.impactUnregulated = impacts['unregulated']!;
      }
      if (impacts.containsKey('permanently_harmed')) {
        character.impactPermanentlyHarmed = impacts['permanently_harmed']!;
      }
      if (impacts.containsKey('traumatized')) {
        character.impactTraumatized = impacts['traumatized']!;
      }
      if (impacts.containsKey('doomed')) {
        character.impactDoomed = impacts['doomed']!;
      }
      if (impacts.containsKey('tormented')) {
        character.impactTormented = impacts['tormented']!;
      }
      if (impacts.containsKey('indebted')) {
        character.impactIndebted = impacts['indebted']!;
      }
      if (impacts.containsKey('overheated')) {
        character.impactOverheated = impacts['overheated']!;
      }
      if (impacts.containsKey('infected')) {
        character.impactInfected = impacts['infected']!;
      }
    }

    // Update assets if provided
    if (assets != null) {
      character.assets.clear();
      character.assets.addAll(assets);
    }

    // Save the changes
    gameProvider.saveGame();

    return true;
  }

  /// Deletes a character.
  Future<bool> deleteCharacter(String characterId) async {
    if (gameProvider.currentGame == null) {
      return false;
    }

    // Check if the character is the main character
    final isMainCharacter = gameProvider.currentGame!.mainCharacter?.id == characterId;

    // Remove the character from the game
    gameProvider.currentGame!.characters.removeWhere((c) => c.id == characterId);

    // If the character was the main character, set mainCharacter to null
    if (isMainCharacter) {
      gameProvider.currentGame!.mainCharacter = null;
    }

    // Save the changes
    gameProvider.saveGame();

    return true;
  }

  /// Sets a character as the main character.
  Future<bool> setMainCharacter(String characterId) async {
    if (gameProvider.currentGame == null) {
      return false;
    }

    // Find the character in the game
    final character = gameProvider.currentGame!.characters.firstWhere(
      (c) => c.id == characterId,
      orElse: () => throw Exception('Character not found'),
    );

    // Set the character as the main character
    gameProvider.currentGame!.mainCharacter = character;

    // Save the changes
    gameProvider.saveGame();

    return true;
  }

  /// Gets a character by ID.
  Character? getCharacterById(String characterId) {
    if (gameProvider.currentGame == null) {
      return null;
    }

    // Find the character in the game
    final index = gameProvider.currentGame!.characters.indexWhere((c) => c.id == characterId);
    if (index == -1) {
      return null;
    }

    return gameProvider.currentGame!.characters[index];
  }

  /// Gets all characters.
  List<Character> getAllCharacters() {
    if (gameProvider.currentGame == null) {
      return [];
    }

    return gameProvider.currentGame!.characters;
  }

  /// Gets the main character.
  Character? getMainCharacter() {
    if (gameProvider.currentGame == null) {
      return null;
    }

    return gameProvider.currentGame!.mainCharacter;
  }
}

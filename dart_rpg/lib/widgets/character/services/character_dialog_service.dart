import '../../../models/character.dart';
import '../../../providers/game_provider.dart';
import '../../../providers/datasworn_provider.dart';
import '../../../utils/logging_service.dart';

/// A service class that handles the business logic for character dialogs.
class CharacterDialogService {
  /// Creates a new character and adds it to the game.
  /// Returns the created character, or null if creation failed.
  static Future<Character?> createCharacter({
    required GameProvider gameProvider,
    required DataswornProvider dataswornProvider,
    required String name,
    required bool isPlayerCharacter,
    String? handle,
    String? bio,
    String? imageUrl,
    List<CharacterStat>? stats,
    // NPC character details
    String? firstLook,
    String? disposition,
    String? trademarkAvatar,
    String? role,
    String? details,
    String? goals,
  }) async {
    // If name is empty but handle is not, use handle as name
    String characterName = name;
    if (characterName.isEmpty && handle != null && handle.isNotEmpty) {
      characterName = handle;
    }
    
    // Create character
    Character character;
    if (isPlayerCharacter) {
      character = Character.createMainCharacter(
        characterName,
        handle: handle,
      );
    } else {
      character = Character(
        name: characterName,
        handle: handle,
      );
    }
    
    // Set bio and image
    character.bio = bio;
    
    // Handle the new image ID format
    if (imageUrl != null && imageUrl.startsWith('id:')) {
      character.imageId = imageUrl.substring(3);
    } else {
      character.imageUrl = imageUrl;
    }
    
    // Set NPC character details
    if (!isPlayerCharacter) {
      character.firstLook = firstLook;
      character.disposition = disposition;
      character.trademarkAvatar = trademarkAvatar;
      character.role = role;
      character.details = details;
      character.goals = goals;
    }
    
    // Update stats if it's a player character
    if (isPlayerCharacter && stats != null) {
      character.stats.clear();
      character.stats.addAll(stats);
    }
    
    // Add character to game
    if (gameProvider.currentGame != null) {
      // Use the createCharacter method from GameProvider
      await gameProvider.createCharacter(
        character.name, 
        isMainCharacter: isPlayerCharacter,
        handle: handle,
      );
    
      // Update the character with our custom data
      final createdCharacter = gameProvider.currentGame!.characters.last;
      createdCharacter.bio = character.bio;
      
      // Set image properties
      if (character.imageId != null) {
        createdCharacter.imageId = character.imageId;
        createdCharacter.imageUrl = null;
      } else {
        createdCharacter.imageUrl = character.imageUrl;
        createdCharacter.imageId = null;
      }
      
      // Update NPC character details if it's not a player character
      if (!isPlayerCharacter) {
        createdCharacter.firstLook = firstLook;
        createdCharacter.disposition = disposition;
        createdCharacter.trademarkAvatar = trademarkAvatar;
        createdCharacter.role = role;
        createdCharacter.details = details;
        createdCharacter.goals = goals;
      }
      
      // Update stats if it's a player character
      if (isPlayerCharacter && stats != null) {
        createdCharacter.stats.clear();
        createdCharacter.stats.addAll(stats);
        
        // Set default values for key stats
        createdCharacter.momentum = 2;
        createdCharacter.momentumReset = 2;
        createdCharacter.health = 5;
        createdCharacter.spirit = 5;
        createdCharacter.supply = 5;
        
        // Ensure Base Rig asset is added - use DataswornProvider if possible
        if (createdCharacter.assets.isEmpty) {
          // Try to find the Base Rig asset in the DataswornProvider by ID
          Asset? baseRig = dataswornProvider.findAssetById("base_rig");
          
          // If not found by ID, try to find it in the rig asset collection
          if (baseRig == null) {
            final assetsByCategory = dataswornProvider.getAssetsByCategory();
            if (assetsByCategory.containsKey('rig')) {
              final rigAssets = assetsByCategory['rig'];
              if (rigAssets != null && rigAssets.isNotEmpty) {
                // Look for an asset with ID "base_rig" in the rig category
                try {
                  baseRig = rigAssets.firstWhere(
                    (asset) => asset.id == "base_rig"
                  );
                  LoggingService().debug(
                    'Found Base Rig asset in rig category: ${baseRig.name} (ID: ${baseRig.id})',
                    tag: 'CharacterDialogService',
                  );
                } catch (e) {
                  LoggingService().warning(
                    'Base Rig asset not found in rig category: ${e.toString()}',
                    tag: 'CharacterDialogService',
                  );
                }
              }
            }
          } else {
            LoggingService().debug(
              'Found Base Rig asset by ID: ${baseRig.name} (ID: ${baseRig.id})',
              tag: 'CharacterDialogService',
            );
          }
          
          // If still not found, use the factory method and log a warning
          if (baseRig == null) {
            LoggingService().warning(
              'Base Rig asset not found in Datasworn data. Using factory fallback.',
              tag: 'CharacterDialogService',
            );
            baseRig = Asset.baseRig();
          }
          
          // Add the Base Rig asset to the character
          createdCharacter.assets.add(baseRig);
        }
      }
      
      // Save the game
      gameProvider.saveGame();
      
      // Return the created character
      return createdCharacter;
    }
    
    // Return null if no game is available
    return null;
  }
  
  /// Updates an existing character.
  static void updateCharacter({
    required GameProvider gameProvider,
    required Character character,
    required String name,
    String? handle,
    String? bio,
    String? imageUrl,
    List<String>? notes,
    List<CharacterStat>? stats,
    // Key stats
    int? momentum,
    int? health,
    int? spirit,
    int? supply,
    // Impacts
    bool? impactWounded,
    bool? impactShaken,
    bool? impactUnregulated,
    bool? impactPermanentlyHarmed,
    bool? impactTraumatized,
    bool? impactDoomed,
    bool? impactTormented,
    bool? impactIndebted,
    bool? impactOverheated,
    bool? impactInfected,
    // NPC character details
    String? firstLook,
    String? disposition,
    String? trademarkAvatar,
    String? role,
    String? details,
    String? goals,
  }) {
    if (gameProvider.currentGame != null) {
      // If name is empty but handle is not, use handle as name
      String characterName = name;
      if (characterName.isEmpty && handle != null && handle.isNotEmpty) {
        characterName = handle;
      }
      
      // Find the character in the game
      final index = gameProvider.currentGame!.characters.indexWhere((c) => c.id == character.id);
      if (index != -1) {
        // Update the character properties
        character.name = characterName;
        if (handle != null) {
          character.setHandle(handle);
        }
        character.bio = bio;
        // Handle the new image ID format
        if (imageUrl != null && imageUrl.startsWith('id:')) {
          character.imageId = imageUrl.substring(3);
          character.imageUrl = null; // Clear the URL since we're using an ID
        } else {
          character.imageUrl = imageUrl;
          character.imageId = null; // Clear the ID since we're using a URL
        }
        
        // Update notes
        if (notes != null) {
          character.notes = notes;
        }
        
        // Update NPC character details if it's not a player character
        if (!character.isMainCharacter) {
          character.firstLook = firstLook;
          character.disposition = disposition;
          character.trademarkAvatar = trademarkAvatar;
          character.role = role;
          character.details = details;
          character.goals = goals;
        }
        
        // Update stats if it's a main character
        if (character.stats.isNotEmpty && stats != null) {
          character.stats.clear();
          character.stats.addAll(stats);
        }
        
        // Update key stats
        if (momentum != null) character.momentum = momentum;
        if (health != null) character.health = health;
        if (spirit != null) character.spirit = spirit;
        if (supply != null) character.supply = supply;
        
        // Update impacts
        if (impactWounded != null) character.impactWounded = impactWounded;
        if (impactShaken != null) character.impactShaken = impactShaken;
        if (impactUnregulated != null) character.impactUnregulated = impactUnregulated;
        if (impactPermanentlyHarmed != null) character.impactPermanentlyHarmed = impactPermanentlyHarmed;
        if (impactTraumatized != null) character.impactTraumatized = impactTraumatized;
        if (impactDoomed != null) character.impactDoomed = impactDoomed;
        if (impactTormented != null) character.impactTormented = impactTormented;
        if (impactIndebted != null) character.impactIndebted = impactIndebted;
        if (impactOverheated != null) character.impactOverheated = impactOverheated;
        if (impactInfected != null) character.impactInfected = impactInfected;
        
        // Save changes
        gameProvider.saveGame();
      }
    }
  }
  
  /// Deletes a character from the game.
  static void deleteCharacter({
    required GameProvider gameProvider,
    required Character character,
  }) {
    if (gameProvider.currentGame != null) {
      gameProvider.currentGame!.characters.removeWhere((c) => c.id == character.id);
      // Save the changes
      gameProvider.saveGame();
    }
  }
  
  /// Sets a character as the main character.
  static void setAsMainCharacter({
    required GameProvider gameProvider,
    required Character character,
  }) {
    if (gameProvider.currentGame != null) {
      gameProvider.currentGame!.mainCharacter = character;
      // Save the changes
      gameProvider.saveGame();
    }
  }
}

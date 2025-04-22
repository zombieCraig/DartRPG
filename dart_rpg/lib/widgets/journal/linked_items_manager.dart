import '../../models/journal_entry.dart';
import '../../models/character.dart';
import '../../models/location.dart';

/// A class for managing linked items in a journal entry.
class LinkedItemsManager {
  /// The list of linked character IDs.
  List<String> _linkedCharacterIds = [];
  
  /// The list of linked location IDs.
  List<String> _linkedLocationIds = [];
  
  /// The list of move rolls.
  List<MoveRoll> _moveRolls = [];
  
  /// The list of oracle rolls.
  List<OracleRoll> _oracleRolls = [];
  
  /// The list of embedded image URLs.
  List<String> _embeddedImages = [];
  
  /// The list of embedded image IDs.
  List<String> _embeddedImageIds = [];
  
  /// Creates a new LinkedItemsManager.
  LinkedItemsManager({
    List<String>? linkedCharacterIds,
    List<String>? linkedLocationIds,
    List<MoveRoll>? moveRolls,
    List<OracleRoll>? oracleRolls,
    List<String>? embeddedImages,
    List<String>? embeddedImageIds,
  }) {
    _linkedCharacterIds = linkedCharacterIds ?? [];
    _linkedLocationIds = linkedLocationIds ?? [];
    _moveRolls = moveRolls ?? [];
    _oracleRolls = oracleRolls ?? [];
    _embeddedImages = embeddedImages ?? [];
    _embeddedImageIds = embeddedImageIds ?? [];
  }
  
  /// Creates a LinkedItemsManager from a journal entry.
  factory LinkedItemsManager.fromJournalEntry(JournalEntry entry) {
    return LinkedItemsManager(
      linkedCharacterIds: List.from(entry.linkedCharacterIds),
      linkedLocationIds: List.from(entry.linkedLocationIds),
      moveRolls: List.from(entry.moveRolls),
      oracleRolls: List.from(entry.oracleRolls),
      embeddedImages: List.from(entry.embeddedImages),
      embeddedImageIds: List.from(entry.embeddedImageIds),
    );
  }
  
  /// Adds a character to the linked characters list.
  void addCharacter(String characterId) {
    if (!_linkedCharacterIds.contains(characterId)) {
      _linkedCharacterIds.add(characterId);
    }
  }
  
  /// Removes a character from the linked characters list.
  void removeCharacter(String characterId) {
    _linkedCharacterIds.remove(characterId);
  }
  
  /// Adds a location to the linked locations list.
  void addLocation(String locationId) {
    if (!_linkedLocationIds.contains(locationId)) {
      _linkedLocationIds.add(locationId);
    }
  }
  
  /// Removes a location from the linked locations list.
  void removeLocation(String locationId) {
    _linkedLocationIds.remove(locationId);
  }
  
  /// Adds a move roll to the move rolls list.
  void addMoveRoll(MoveRoll moveRoll) {
    _moveRolls.add(moveRoll);
  }
  
  /// Removes a move roll from the move rolls list.
  void removeMoveRoll(MoveRoll moveRoll) {
    _moveRolls.remove(moveRoll);
  }
  
  /// Adds an oracle roll to the oracle rolls list.
  void addOracleRoll(OracleRoll oracleRoll) {
    _oracleRolls.add(oracleRoll);
  }
  
  /// Removes an oracle roll from the oracle rolls list.
  void removeOracleRoll(OracleRoll oracleRoll) {
    _oracleRolls.remove(oracleRoll);
  }
  
  /// Adds an embedded image URL to the embedded images list.
  void addEmbeddedImage(String imageUrl) {
    if (!_embeddedImages.contains(imageUrl)) {
      _embeddedImages.add(imageUrl);
    }
  }
  
  /// Removes an embedded image URL from the embedded images list.
  void removeEmbeddedImage(String imageUrl) {
    _embeddedImages.remove(imageUrl);
  }
  
  /// Adds an embedded image ID to the embedded image IDs list.
  void addEmbeddedImageId(String imageId) {
    if (!_embeddedImageIds.contains(imageId)) {
      _embeddedImageIds.add(imageId);
    }
  }
  
  /// Removes an embedded image ID from the embedded image IDs list.
  void removeEmbeddedImageId(String imageId) {
    _embeddedImageIds.remove(imageId);
  }
  
  /// Updates a journal entry with the linked items.
  void updateJournalEntry(JournalEntry entry) {
    entry.linkedCharacterIds = List.from(_linkedCharacterIds);
    entry.linkedLocationIds = List.from(_linkedLocationIds);
    entry.moveRolls = List.from(_moveRolls);
    entry.oracleRolls = List.from(_oracleRolls);
    entry.embeddedImages = List.from(_embeddedImages);
    entry.embeddedImageIds = List.from(_embeddedImageIds);
  }
  
  /// Gets the list of linked character IDs.
  List<String> get linkedCharacterIds => List.unmodifiable(_linkedCharacterIds);
  
  /// Gets the list of linked location IDs.
  List<String> get linkedLocationIds => List.unmodifiable(_linkedLocationIds);
  
  /// Gets the list of move rolls.
  List<MoveRoll> get moveRolls => List.unmodifiable(_moveRolls);
  
  /// Gets the list of oracle rolls.
  List<OracleRoll> get oracleRolls => List.unmodifiable(_oracleRolls);
  
  /// Gets the list of embedded image URLs.
  List<String> get embeddedImages => List.unmodifiable(_embeddedImages);
  
  /// Gets the list of embedded image IDs.
  List<String> get embeddedImageIds => List.unmodifiable(_embeddedImageIds);
  
  /// Validates character references in the linked characters list.
  /// 
  /// Removes any character IDs that don't exist in the provided list of characters.
  void validateCharacterReferences(List<Character> characters) {
    final validCharacterIds = characters.map((c) => c.id).toSet();
    _linkedCharacterIds.removeWhere((id) => !validCharacterIds.contains(id));
  }
  
  /// Validates location references in the linked locations list.
  /// 
  /// Removes any location IDs that don't exist in the provided list of locations.
  void validateLocationReferences(List<Location> locations) {
    final validLocationIds = locations.map((l) => l.id).toSet();
    _linkedLocationIds.removeWhere((id) => !validLocationIds.contains(id));
  }
  
  /// Clears all linked items.
  void clear() {
    _linkedCharacterIds.clear();
    _linkedLocationIds.clear();
    _moveRolls.clear();
    _oracleRolls.clear();
    _embeddedImages.clear();
    _embeddedImageIds.clear();
  }
}

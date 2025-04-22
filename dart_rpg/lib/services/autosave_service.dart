import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/journal_entry.dart';
import '../providers/game_provider.dart';
import '../utils/logging_service.dart';

/// A service for handling automatic saving of journal entries.
class AutosaveService {
  /// The timer for autosaving.
  Timer? _autoSaveTimer;
  
  /// Whether an autosave operation is currently in progress.
  bool _isAutoSaving = false;
  
  /// The ID of the entry created during this editing session.
  String? _createdEntryId;
  
  /// Starts the autosave timer.
  /// 
  /// Cancels any existing timer and starts a new one that will save after
  /// the specified delay.
  void startAutoSaveTimer({
    required Function() onSave,
    Duration delay = const Duration(seconds: 10), // Increased from 2 to 10 seconds
  }) {
    // Cancel any existing timer
    _autoSaveTimer?.cancel();
    
    // Start a new timer
    _autoSaveTimer = Timer(delay, onSave);
  }
  
  /// Cancels the autosave timer.
  void cancelAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }
  
  /// Performs an autosave operation for a journal entry.
  /// 
  /// If the entry already exists, it updates it. If it doesn't exist and
  /// there's content, it creates a new entry.
  Future<void> autoSave({
    required BuildContext context,
    required String? entryId,
    required String content,
    required String? richContent,
    required List<String> linkedCharacterIds,
    required List<String> linkedLocationIds,
    required List<MoveRoll> moveRolls,
    required List<OracleRoll> oracleRolls,
    required List<String> embeddedImages,
  }) async {
    // Skip autosave for very short content to reduce unnecessary saves
    if (content.length < 20 && entryId == null && _createdEntryId == null) {
      return;
    }
    
    // Prevent multiple auto-saves from running simultaneously
    if (_isAutoSaving) return;
    
    _isAutoSaving = true;
    
    final stopwatch = Stopwatch()..start();
    
    try {
      // Auto-save for both new and existing entries
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      final currentSession = gameProvider.currentSession;
      
      if (currentSession == null) {
        _isAutoSaving = false;
        return;
      }
      
      if (entryId != null) {
        // Update existing entry
        final entry = currentSession.entries.firstWhere(
          (e) => e.id == entryId,
        );
        
        // Update content
        entry.update(content);
        entry.richContent = richContent;
        
        // Update linked entities
        entry.linkedCharacterIds = linkedCharacterIds;
        entry.linkedLocationIds = linkedLocationIds;
        
        // Update rolls
        entry.moveRolls = moveRolls;
        entry.oracleRolls = oracleRolls;
        
        // Update embedded images
        entry.embeddedImages = embeddedImages;
        
        // Save the changes
        await gameProvider.updateJournalEntry(entryId, content);
        await gameProvider.saveGame();
        
      } else if (content.isNotEmpty) {
        if (_createdEntryId == null) {
          // Create new entry if there's content and we haven't created one yet
          final entry = await gameProvider.createJournalEntry(content);
          
          // Update the entry with additional data
          entry.richContent = richContent;
          entry.linkedCharacterIds = linkedCharacterIds;
          entry.linkedLocationIds = linkedLocationIds;
          entry.moveRolls = moveRolls;
          entry.oracleRolls = oracleRolls;
          entry.embeddedImages = embeddedImages;
          
          // Save the changes
          await gameProvider.saveGame();
          
          _createdEntryId = entry.id; // Store the ID of the created entry
        } else {
          // Update the entry we already created
          final entry = currentSession.entries.firstWhere(
            (e) => e.id == _createdEntryId,
          );
          
          // Update content
          entry.update(content);
          entry.richContent = richContent;
          
          // Update linked entities
          entry.linkedCharacterIds = linkedCharacterIds;
          entry.linkedLocationIds = linkedLocationIds;
          
          // Update rolls
          entry.moveRolls = moveRolls;
          entry.oracleRolls = oracleRolls;
          
          // Update embedded images
          entry.embeddedImages = embeddedImages;
          
          // Save the changes
          await gameProvider.updateJournalEntry(_createdEntryId!, content);
          await gameProvider.saveGame();
        }
      }
    } catch (e) {
      // Log errors during auto-save
      LoggingService().error(
        'Error during auto-save',
        tag: 'AutosaveService',
        error: e,
        stackTrace: StackTrace.current
      );
    } finally {
      _isAutoSaving = false;
      
      // Log performance metrics
      LoggingService().debug(
        'Autosave completed in ${stopwatch.elapsedMilliseconds}ms',
        tag: 'AutosaveService',
      );
    }
  }
  
  /// Gets the ID of the entry created during this editing session.
  String? get createdEntryId => _createdEntryId;
  
  /// Resets the service state.
  void reset() {
    cancelAutoSaveTimer();
    _isAutoSaving = false;
    _createdEntryId = null;
  }
  
  /// Disposes of the service resources.
  void dispose() {
    cancelAutoSaveTimer();
  }
}

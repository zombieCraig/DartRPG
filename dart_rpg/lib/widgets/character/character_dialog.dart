import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../providers/game_provider.dart';
import 'dialogs/character_create_dialog.dart';
import 'dialogs/character_edit_dialog.dart';
import 'dialogs/character_delete_confirmation.dart';

/// A utility class that handles character creation and editing dialogs.
class CharacterDialog {
  /// Shows a dialog for creating a new character.
  static Future<void> showCreateDialog(BuildContext context, GameProvider gameProvider) async {
    await CharacterCreateDialog.show(context, gameProvider);
  }

  /// Shows a dialog for editing an existing character.
  static Future<void> showEditDialog(BuildContext context, GameProvider gameProvider, Character character) async {
    await CharacterEditDialog.show(context, gameProvider, character);
  }

  /// Shows a dialog for confirming character deletion.
  static Future<bool> showDeleteConfirmation(BuildContext context, Character character) async {
    return await CharacterDeleteConfirmation.show(context, character);
  }
}

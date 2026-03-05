import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/character.dart';
import '../../models/location.dart';
import '../../providers/datasworn_provider.dart';
import '../../providers/game_provider.dart';
import '../../services/oracle_service.dart';
import '../../utils/leet_speak_converter.dart';
import '../../utils/logging_service.dart';
import '../locations/location_service.dart';
import '../locations/location_dialog.dart';
import 'autocomplete_system.dart';

/// Static methods for quick-add dialogs used from the journal entry screen.
class QuickAddDialogs {
  QuickAddDialogs._();

  /// Shows a dialog to quickly create and link a new character.
  ///
  /// [onCharacterCreated] is called with the new character's ID after creation.
  static void showAddCharacter(
    BuildContext context, {
    required void Function(String characterId) onCharacterCreated,
  }) {
    final nameController = TextEditingController();
    final handleController = TextEditingController();
    final handleFocusNode = FocusNode();
    final loggingService = LoggingService();

    handleFocusNode.addListener(() {
      if (handleFocusNode.hasFocus &&
          handleController.text.isEmpty &&
          nameController.text.isNotEmpty) {
        final character = Character(name: nameController.text);
        handleController.text = character.getHandle();
        loggingService.debug(
          'Auto-generated handle: ${handleController.text}',
          tag: 'QuickAddDialogs',
        );
      }
    });

    Future<void> generateRandomName() async {
      final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);

      final firstNameTable = OracleService.findOracleTableByKeyAnywhere('first_names', dataswornProvider);
      if (firstNameTable == null) {
        loggingService.warning('Could not find first_names oracle table', tag: 'QuickAddDialogs');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find first_names oracle table')),
        );
        return;
      }

      final surnameTable = OracleService.findOracleTableByKeyAnywhere('surnames', dataswornProvider);
      if (surnameTable == null) {
        loggingService.warning('Could not find surnames oracle table', tag: 'QuickAddDialogs');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find surnames oracle table')),
        );
        return;
      }

      final firstNameResult = OracleService.rollOnOracleTable(firstNameTable);
      final surnameResult = OracleService.rollOnOracleTable(surnameTable);

      if (firstNameResult['success'] == true && surnameResult['success'] == true) {
        final firstName = firstNameResult['oracleRoll'].result;
        final surname = surnameResult['oracleRoll'].result;
        nameController.text = '$firstName $surname';
        loggingService.debug('Generated random name: ${nameController.text}', tag: 'QuickAddDialogs');
      } else {
        loggingService.warning('Failed to generate random name', tag: 'QuickAddDialogs');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate random name')),
        );
      }
    }

    Future<void> generateRandomHandle() async {
      final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
      final oracleTable = OracleService.findOracleTableByKeyAnywhere('fe_runner_handles', dataswornProvider);

      if (oracleTable == null) {
        loggingService.warning('Could not find fe_runner_handles oracle table', tag: 'QuickAddDialogs');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find runner handles oracle table')),
        );
        return;
      }

      final rollResult = OracleService.rollOnOracleTable(oracleTable);

      if (rollResult['success'] == true) {
        final oracleRoll = rollResult['oracleRoll'];
        final initialResult = oracleRoll.result;

        loggingService.debug('Processing oracle references in handle result: $initialResult', tag: 'QuickAddDialogs');

        final processResult = await OracleService.processOracleReferences(initialResult, dataswornProvider);

        String finalResult;
        if (processResult['success'] == true) {
          finalResult = processResult['processedText'] as String;
          loggingService.debug('Processed result: $finalResult', tag: 'QuickAddDialogs');
        } else {
          finalResult = initialResult;
          loggingService.warning(
            'Failed to process oracle references: ${processResult['error']}',
            tag: 'QuickAddDialogs',
          );
        }

        final currentHandle = handleController.text;
        if (currentHandle.isNotEmpty) {
          handleController.text = '$currentHandle$finalResult';
        } else {
          handleController.text = finalResult;
        }

        loggingService.debug('Generated random handle: ${handleController.text}', tag: 'QuickAddDialogs');
      } else {
        loggingService.warning(
          'Failed to roll on fe_runner_handles oracle table: ${rollResult['error']}',
          tag: 'QuickAddDialogs',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate random handle: ${rollResult['error']}')),
        );
      }
    }

    void convertToLeetSpeak() {
      final currentHandle = handleController.text;
      if (currentHandle.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a handle first')),
        );
        return;
      }
      handleController.text = LeetSpeakConverter.convert(currentHandle);
      loggingService.debug('Converted handle to leet speak: ${handleController.text}', tag: 'QuickAddDialogs');
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Character'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Character Name',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.casino),
                      tooltip: 'Random Name',
                      onPressed: () async => await generateRandomName(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: handleController,
                        focusNode: handleFocusNode,
                        decoration: const InputDecoration(
                          labelText: 'Short Name or Handle',
                          helperText: 'No spaces, @, #, or brackets. Will default to first name if blank.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.casino),
                      tooltip: 'Random Handle',
                      onPressed: () async => await generateRandomHandle(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.terminal),
                      tooltip: 'Make l33t',
                      onPressed: convertToLeetSpeak,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty && handleController.text.isNotEmpty) {
                  nameController.text = handleController.text;
                }

                if (nameController.text.isNotEmpty) {
                  final gameProvider = Provider.of<GameProvider>(context, listen: false);
                  final character = await gameProvider.createCharacter(
                    nameController.text,
                    handle: handleController.text.isEmpty ? null : handleController.text,
                  );

                  onCharacterCreated(character.id);

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a name or handle'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  /// Shows a dialog to quickly create and link a new location.
  ///
  /// [onLocationCreated] is called with the new location after creation.
  /// If [isEditing] is true and [editorController] is provided, a mention
  /// will be inserted at the cursor position.
  static void showAddLocation(
    BuildContext context, {
    required void Function(Location location) onLocationCreated,
    bool isEditing = false,
    TextEditingController? editorController,
    AutocompleteSystem? autocompleteSystem,
  }) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final locationService = LocationService(gameProvider: gameProvider);

    LocationDialog.showCreateDialog(
      context,
      locationService,
    ).then((location) {
      if (location != null) {
        onLocationCreated(location);

        if (isEditing && editorController != null && editorController.text.isNotEmpty && autocompleteSystem != null) {
          final result = autocompleteSystem.insertMention(
            location,
            editorController.text,
            editorController.selection.baseOffset,
          );

          editorController.value = TextEditingValue(
            text: result['text'],
            selection: TextSelection.collapsed(offset: result['cursorPosition']),
          );
        }
      }
    });
  }
}

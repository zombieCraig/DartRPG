import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/character.dart';
import '../../providers/datasworn_provider.dart';
import '../../services/oracle_service.dart';
import '../../utils/leet_speak_converter.dart';
import '../../utils/logging_service.dart';

/// A component for character data entry.
class CharacterForm extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController handleController;
  final TextEditingController bioController;
  final TextEditingController imageUrlController;
  final bool isPlayerCharacterSwitchVisible;
  final bool isPlayerCharacter;
  final Function(bool)? onPlayerCharacterChanged;

  const CharacterForm({
    super.key,
    required this.nameController,
    required this.handleController,
    required this.bioController,
    required this.imageUrlController,
    required this.isPlayerCharacterSwitchVisible,
    required this.isPlayerCharacter,
    this.onPlayerCharacterChanged,
  });

  @override
  State<CharacterForm> createState() => _CharacterFormState();
}

class _CharacterFormState extends State<CharacterForm> {
  final FocusNode _handleFocusNode = FocusNode();
  final LoggingService _loggingService = LoggingService();
  
  @override
  void initState() {
    super.initState();
    _handleFocusNode.addListener(_handleFocusChange);
  }
  
  @override
  void dispose() {
    _handleFocusNode.removeListener(_handleFocusChange);
    _handleFocusNode.dispose();
    super.dispose();
  }
  
  /// Handles focus change for the handle field.
  void _handleFocusChange() {
    if (_handleFocusNode.hasFocus && 
        widget.handleController.text.isEmpty && 
        widget.nameController.text.isNotEmpty) {
      // Generate handle from name
      final character = Character(name: widget.nameController.text);
      widget.handleController.text = character.getHandle();
      _loggingService.debug(
        'Auto-generated handle: ${widget.handleController.text}',
        tag: 'CharacterForm',
      );
    }
  }
  
  /// Generates a random handle from the fe_runner_handles oracle.
  void _generateRandomHandle() {
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    
    // Try to find the fe_runner_handles oracle table using the new method
    final oracleTable = OracleService.findOracleTableByKeyAnywhere('fe_runner_handles', dataswornProvider);
    
    if (oracleTable == null) {
      _loggingService.warning(
        'Could not find fe_runner_handles oracle table',
        tag: 'CharacterForm',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not find runner handles oracle table'),
        ),
      );
      return;
    }
    
    // Roll on the oracle table
    final rollResult = OracleService.rollOnOracleTable(oracleTable);
    
    if (rollResult['success'] == true) {
      final oracleRoll = rollResult['oracleRoll'];
      final result = oracleRoll.result;
      
      // Append the result to the current handle
      final currentHandle = widget.handleController.text;
      if (currentHandle.isNotEmpty) {
        widget.handleController.text = '$currentHandle$result';
      } else {
        widget.handleController.text = result;
      }
      
      _loggingService.debug(
        'Generated random handle: ${widget.handleController.text}',
        tag: 'CharacterForm',
      );
    } else {
      _loggingService.warning(
        'Failed to roll on fe_runner_handles oracle table: ${rollResult['error']}',
        tag: 'CharacterForm',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate random handle: ${rollResult['error']}'),
        ),
      );
    }
  }
  
  /// Converts the current handle to leet speak.
  void _convertToLeetSpeak() {
    final currentHandle = widget.handleController.text;
    if (currentHandle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a handle first'),
        ),
      );
      return;
    }
    
    // Convert to leet speak
    final leetHandle = LeetSpeakConverter.convert(currentHandle);
    widget.handleController.text = leetHandle;
    
    _loggingService.debug(
      'Converted handle to leet speak: $leetHandle',
      tag: 'CharacterForm',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter character name',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.handleController,
                focusNode: _handleFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Short Name or Handle',
                  hintText: 'Enter a short name without spaces or special characters',
                  helperText: 'No spaces, @, #, or brackets. Will default to first name if blank.',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.casino),
              tooltip: 'Random Handle',
              onPressed: _generateRandomHandle,
            ),
            IconButton(
              icon: const Icon(Icons.terminal),
              tooltip: 'Make l33t',
              onPressed: _convertToLeetSpeak,
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: widget.bioController,
          decoration: const InputDecoration(
            labelText: 'Bio',
            hintText: 'Enter character bio',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: widget.imageUrlController,
          decoration: const InputDecoration(
            labelText: 'Image URL (optional)',
            hintText: 'Enter URL to character image',
          ),
        ),
        if (widget.isPlayerCharacterSwitchVisible) ...[
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Player Character'),
            subtitle: const Text('Has stats and can use assets'),
            value: widget.isPlayerCharacter,
            onChanged: widget.onPlayerCharacterChanged,
          ),
        ],
      ],
    );
  }
}

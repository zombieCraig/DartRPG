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
  
  // Controllers for NPC character details
  final TextEditingController? firstLookController;
  final TextEditingController? dispositionController;
  final TextEditingController? trademarkAvatarController;
  final TextEditingController? roleController;
  final TextEditingController? detailsController;
  final TextEditingController? goalsController;

  const CharacterForm({
    super.key,
    required this.nameController,
    required this.handleController,
    required this.bioController,
    required this.imageUrlController,
    required this.isPlayerCharacterSwitchVisible,
    required this.isPlayerCharacter,
    this.onPlayerCharacterChanged,
    this.firstLookController,
    this.dispositionController,
    this.trademarkAvatarController,
    this.roleController,
    this.detailsController,
    this.goalsController,
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
  Future<void> _generateRandomHandle() async {
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
      final initialResult = oracleRoll.result;
      
      // Process any oracle references in the result
      _loggingService.debug(
        'Processing oracle references in handle result: $initialResult',
        tag: 'CharacterForm',
      );
      
      
      // Process the references
      final processResult = await OracleService.processOracleReferences(initialResult, dataswornProvider);
      
      String finalResult;
      if (processResult['success'] == true) {
        finalResult = processResult['processedText'] as String;
        _loggingService.debug(
          'Processed result: $finalResult',
          tag: 'CharacterForm',
        );
      } else {
        // If processing fails, use the initial result
        finalResult = initialResult;
        _loggingService.warning(
          'Failed to process oracle references: ${processResult['error']}',
          tag: 'CharacterForm',
        );
      }
      
      // Append the result to the current handle
      final currentHandle = widget.handleController.text;
      if (currentHandle.isNotEmpty) {
        widget.handleController.text = '$currentHandle$finalResult';
      } else {
        widget.handleController.text = finalResult;
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
  
  /// Generates random content for a field using the specified oracle table.
  Future<void> _generateRandomField(String oracleKey, TextEditingController? controller) async {
    if (controller == null) return;
    
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    
    // Try to find the oracle table using the key
    final oracleTable = OracleService.findOracleTableByKeyAnywhere(oracleKey, dataswornProvider);
    
    if (oracleTable == null) {
      _loggingService.warning(
        'Could not find $oracleKey oracle table',
        tag: 'CharacterForm',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not find $oracleKey oracle table'),
        ),
      );
      return;
    }
    
    // Roll on the oracle table
    final rollResult = OracleService.rollOnOracleTable(oracleTable);
    
    if (rollResult['success'] == true) {
      final oracleRoll = rollResult['oracleRoll'];
      final initialResult = oracleRoll.result;
      
      // Process any oracle references in the result
      _loggingService.debug(
        'Processing oracle references in $oracleKey result: $initialResult',
        tag: 'CharacterForm',
      );
      
      // Show a loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing oracle references...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Process the references
      final processResult = await OracleService.processOracleReferences(initialResult, dataswornProvider);
      
      String finalResult;
      if (processResult['success'] == true) {
        finalResult = processResult['processedText'] as String;
        _loggingService.debug(
          'Processed result: $finalResult',
          tag: 'CharacterForm',
        );
      } else {
        // If processing fails, use the initial result
        finalResult = initialResult;
        _loggingService.warning(
          'Failed to process oracle references: ${processResult['error']}',
          tag: 'CharacterForm',
        );
      }
      
      // Append the result to the current text
      final currentText = controller.text;
      if (currentText.isNotEmpty) {
        controller.text = '$currentText\n$finalResult';
      } else {
        controller.text = finalResult;
      }
      
      _loggingService.debug(
        'Generated random content for $oracleKey: $finalResult',
        tag: 'CharacterForm',
      );
    } else {
      _loggingService.warning(
        'Failed to roll on $oracleKey oracle table: ${rollResult['error']}',
        tag: 'CharacterForm',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate random content: ${rollResult['error']}'),
        ),
      );
    }
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
              onPressed: () async => await _generateRandomHandle(),
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
        
        // NPC character details section - only show for non-player characters
        if (!widget.isPlayerCharacter && 
            widget.firstLookController != null &&
            widget.dispositionController != null &&
            widget.trademarkAvatarController != null &&
            widget.roleController != null &&
            widget.detailsController != null &&
            widget.goalsController != null) ...[
          const SizedBox(height: 24),
          const Text('Character Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          
          // First Look field with random button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.firstLookController,
                  decoration: const InputDecoration(
                    labelText: 'First Look',
                    hintText: 'What is the first thing someone notices about this character?',
                  ),
                  maxLines: 2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.casino),
                tooltip: 'Random First Look',
                onPressed: () async => await _generateRandomField('character_first_look', widget.firstLookController),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Disposition field with random button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.dispositionController,
                  decoration: const InputDecoration(
                    labelText: 'Disposition',
                    hintText: 'How does this character typically behave?',
                  ),
                  maxLines: 2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.casino),
                tooltip: 'Random Disposition',
                onPressed: () async => await _generateRandomField('character_disposition', widget.dispositionController),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Trademark Avatar field with random button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.trademarkAvatarController,
                  decoration: const InputDecoration(
                    labelText: 'Trademark Avatar Characteristic',
                    hintText: 'What distinctive feature defines their digital avatar?',
                  ),
                  maxLines: 2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.casino),
                tooltip: 'Random Trademark Avatar',
                onPressed: () async => await _generateRandomField('trademark_avatar', widget.trademarkAvatarController),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Role field with random button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.roleController,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    hintText: 'What is this character\'s function or occupation?',
                  ),
                  maxLines: 2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.casino),
                tooltip: 'Random Role',
                onPressed: () async => await _generateRandomField('character_role', widget.roleController),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Details field with random button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                    hintText: 'Additional details about this character',
                  ),
                  maxLines: 3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.casino),
                tooltip: 'Random Details',
                onPressed: () async => await _generateRandomField('character_details', widget.detailsController),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Goals field with random button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.goalsController,
                  decoration: const InputDecoration(
                    labelText: 'Goals',
                    hintText: 'What does this character want to achieve?',
                  ),
                  maxLines: 3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.casino),
                tooltip: 'Random Goals',
                onPressed: () async => await _generateRandomField('character_goals', widget.goalsController),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

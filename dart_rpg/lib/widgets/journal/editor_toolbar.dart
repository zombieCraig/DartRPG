import 'package:flutter/material.dart';

/// A toolbar for formatting actions in the journal entry editor.
class EditorToolbar extends StatelessWidget {
  /// Callback for when the bold button is pressed.
  final VoidCallback onBoldPressed;
  
  /// Callback for when the italic button is pressed.
  final VoidCallback onItalicPressed;
  
  /// Callback for when the heading button is pressed.
  final VoidCallback onHeadingPressed;
  
  /// Callback for when the bullet list button is pressed.
  final VoidCallback onBulletListPressed;
  
  /// Callback for when the numbered list button is pressed.
  final VoidCallback onNumberedListPressed;
  
  /// Callback for when the character button is pressed.
  final VoidCallback onCharacterPressed;
  
  /// Callback for when the location button is pressed.
  final VoidCallback onLocationPressed;
  
  /// Callback for when the image button is pressed.
  final VoidCallback onImagePressed;
  
  /// Callback for when the move button is pressed.
  final VoidCallback? onMovePressed;
  
  /// Callback for when the oracle button is pressed.
  final VoidCallback? onOraclePressed;
  
  /// Callback for when the quest button is pressed.
  final VoidCallback? onQuestPressed;
  
  /// Creates a new EditorToolbar.
  const EditorToolbar({
    super.key,
    required this.onBoldPressed,
    required this.onItalicPressed,
    required this.onHeadingPressed,
    required this.onBulletListPressed,
    required this.onNumberedListPressed,
    required this.onCharacterPressed,
    required this.onLocationPressed,
    required this.onImagePressed,
    this.onMovePressed,
    this.onOraclePressed,
    this.onQuestPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Formatting toolbar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Wrap(
            spacing: 4,
            children: [
              // Bold
              IconButton(
                icon: const Icon(Icons.format_bold),
                tooltip: 'Bold',
                onPressed: onBoldPressed,
              ),
              
              // Italic
              IconButton(
                icon: const Icon(Icons.format_italic),
                tooltip: 'Italic',
                onPressed: onItalicPressed,
              ),
              
              // Heading
              IconButton(
                icon: const Icon(Icons.title),
                tooltip: 'Heading',
                onPressed: onHeadingPressed,
              ),
              
              // Bullet list
              IconButton(
                icon: const Icon(Icons.format_list_bulleted),
                tooltip: 'Bullet List',
                onPressed: onBulletListPressed,
              ),
              
              // Numbered list
              IconButton(
                icon: const Icon(Icons.format_list_numbered),
                tooltip: 'Numbered List',
                onPressed: onNumberedListPressed,
              ),
            ],
          ),
        ),
          
        // Custom toolbar for character, location, and image buttons
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Row(
            children: [
              // Character button
              Tooltip(
                message: 'Add Character (@)',
                child: IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: onCharacterPressed,
                ),
              ),
              
              // Location button
              Tooltip(
                message: 'Add Location (#)',
                child: IconButton(
                  icon: const Icon(Icons.place),
                  onPressed: onLocationPressed,
                ),
              ),
              
              // Image button
              Tooltip(
                message: 'Add Image',
                child: IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: onImagePressed,
                ),
              ),
              
              // Move button
              if (onMovePressed != null)
                Tooltip(
                  message: 'Roll Move (Ctrl+M)',
                  child: IconButton(
                    icon: const Icon(Icons.sports_martial_arts),
                    onPressed: onMovePressed,
                  ),
                ),
              
              // Oracle button
              if (onOraclePressed != null)
                Tooltip(
                  message: 'Roll Oracle (Ctrl+O)',
                  child: IconButton(
                    icon: const Icon(Icons.casino),
                    onPressed: onOraclePressed,
                  ),
                ),
              
              // Quest button
              if (onQuestPressed != null)
                Tooltip(
                  message: 'Quests (Ctrl+Q)',
                  child: IconButton(
                    icon: const Icon(Icons.task_alt),
                    onPressed: onQuestPressed,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

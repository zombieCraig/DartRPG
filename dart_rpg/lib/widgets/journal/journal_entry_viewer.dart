import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../providers/game_provider.dart';
import '../../models/character.dart';
import '../../models/location.dart';
import '../../models/journal_entry.dart';
import '../../models/game.dart';
import '../../widgets/common/app_image_widget.dart';

class JournalEntryViewer extends StatelessWidget {
  final String content;
  final Function(Character character)? onCharacterTap;
  final Function(Location location)? onLocationTap;
  final Function(MoveRoll moveRoll)? onMoveRollTap;
  final Function(OracleRoll oracleRoll)? onOracleRollTap;
  final List<MoveRoll> moveRolls;
  final List<OracleRoll> oracleRolls;

  const JournalEntryViewer({
    super.key,
    required this.content,
    this.onCharacterTap,
    this.onLocationTap,
    this.onMoveRollTap,
    this.onOracleRollTap,
    this.moveRolls = const [],
    this.oracleRolls = const [],
  });

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final currentGame = gameProvider.currentGame;
    
    if (currentGame == null) {
      return SingleChildScrollView(
        child: MarkdownBody(data: content),
      );
    }
    
    // Parse the content and create a widget that handles both markdown and clickable references
    return _buildMarkdownWithReferences(context, currentGame);
  }
  
  Widget _buildMarkdownWithReferences(BuildContext context, Game currentGame) {
    // Regular expressions for finding references
    final characterRegex = RegExp(r'@(\w+)');
    final locationRegex = RegExp(r'#([^\s\[\]]+)');
    final moveRegex = RegExp(r'\[(.*?) - (.*?)\]');
    final oracleRegex = RegExp(r'\[(.*?): (.*?)\]');
    final imageRegex = RegExp(r'!\[(?:.*?)\]\((.*?)\)');
    
    // Find all matches and sort them by position
    final allMatches = <_TextMatch>[];
    
    // Find character references
    for (final match in characterRegex.allMatches(content)) {
      final handle = match.group(1)!;
      final character = _findCharacterByHandle(currentGame, handle);
      
      if (character != null) {
        allMatches.add(_TextMatch(
          start: match.start,
          end: match.end,
          type: _MatchType.character,
          data: character,
        ));
      }
    }
    
    // Find location references
    for (final match in locationRegex.allMatches(content)) {
      final name = match.group(1)!;
      final location = _findLocationByName(currentGame, name);
      
      if (location != null) {
        allMatches.add(_TextMatch(
          start: match.start,
          end: match.end,
          type: _MatchType.location,
          data: location,
        ));
      }
    }
    
    // Find move references
    for (final match in moveRegex.allMatches(content)) {
      final moveName = match.group(1)!;
      final outcome = match.group(2)!;
      final moveRoll = _findMoveRoll(moveName, outcome);
      
      if (moveRoll != null) {
        allMatches.add(_TextMatch(
          start: match.start,
          end: match.end,
          type: _MatchType.move,
          data: moveRoll,
        ));
      }
    }
    
    // Find oracle references
    for (final match in oracleRegex.allMatches(content)) {
      final oracleName = match.group(1)!;
      final result = match.group(2)!;
      final oracleRoll = _findOracleRoll(oracleName, result);
      
      if (oracleRoll != null) {
        allMatches.add(_TextMatch(
          start: match.start,
          end: match.end,
          type: _MatchType.oracle,
          data: oracleRoll,
        ));
      }
    }
    
    // Find image references
    for (final match in imageRegex.allMatches(content)) {
      final url = match.group(1)!;
      
      // Check if it's a local image (id:imageId) or a URL
      String? imageUrl;
      String? imageId;
      
      if (url.startsWith('id:')) {
        imageId = url.substring(3);
      } else {
        imageUrl = url;
      }
      
      allMatches.add(_TextMatch(
        start: match.start,
        end: match.end,
        type: _MatchType.image,
        data: {
          'url': imageUrl,
          'id': imageId,
        },
      ));
    }
    
    // If no special references, just use MarkdownBody
    if (allMatches.isEmpty) {
      return SingleChildScrollView(
        child: MarkdownBody(
          data: content,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
          softLineBreak: true,
        ),
      );
    }
    
    // Sort matches by position
    allMatches.sort((a, b) => a.start.compareTo(b.start));
    
    // Create a list to hold all the spans
    final List<InlineSpan> spans = [];
    
    // Current position in the text
    int currentPosition = 0;
    
    // Process matches in order
    for (final match in allMatches) {
      // Add any text before this match as markdown
      if (match.start > currentPosition) {
        final textBefore = content.substring(currentPosition, match.start);
        spans.add(TextSpan(
          children: _buildMarkdownSpans(context, textBefore),
        ));
      }
      
      // Add the match as a clickable span
      spans.add(_createClickableSpan(
        context,
        content.substring(match.start, match.end),
        match.type,
        match.data,
      ));
      
      // Update current position
      currentPosition = match.end;
    }
    
    // Add any remaining text as markdown
    if (currentPosition < content.length) {
      final textAfter = content.substring(currentPosition);
      spans.add(TextSpan(
        children: _buildMarkdownSpans(context, textAfter),
      ));
    }
    
    // Return the rich text widget wrapped in a SingleChildScrollView for scrolling
    return SingleChildScrollView(
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: spans,
        ),
      ),
    );
  }
  
  // Helper method to build markdown spans for text segments
  List<TextSpan> _buildMarkdownSpans(BuildContext context, String text) {
    // For simplicity, we'll handle basic markdown formatting here
    // Bold: **text**
    // Italic: *text*
    // Headers: # text, ## text, etc.
    // Lists: - item, 1. item
    
    // For now, we'll handle basic formatting manually
    // This is a simplified approach - a more complete solution would use a markdown parser
    
    // Handle bold: **text**
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    text = text.replaceAllMapped(boldRegex, (match) {
      return '<b>${match.group(1)}</b>';
    });
    
    // Handle italic: *text*
    final italicRegex = RegExp(r'\*(.*?)\*');
    text = text.replaceAllMapped(italicRegex, (match) {
      return '<i>${match.group(1)}</i>';
    });
    
    // Handle headers: # text
    final headerRegex = RegExp(r'^(#{1,6})\s+(.*?)$', multiLine: true);
    text = text.replaceAllMapped(headerRegex, (match) {
      final level = match.group(1)!.length;
      final headerText = match.group(2);
      return '<h$level>$headerText</h$level>';
    });
    
    // Handle unordered lists: - item
    final ulRegex = RegExp(r'^-\s+(.*?)$', multiLine: true);
    text = text.replaceAllMapped(ulRegex, (match) {
      return '• ${match.group(1)}';
    });
    
    // Handle ordered lists: 1. item
    final olRegex = RegExp(r'^(\d+)\.\s+(.*?)$', multiLine: true);
    text = text.replaceAllMapped(olRegex, (match) {
      return '${match.group(1)}. ${match.group(2)}';
    });
    
    // Parse the HTML-like tags
    return _parseFormattedText(context, text);
  }
  
  InlineSpan _createClickableSpan(
    BuildContext context,
    String text,
    _MatchType type,
    dynamic data,
  ) {
    // Special handling for images
    if (type == _MatchType.image) {
      final imageData = data as Map<String, String?>;
      
      return WidgetSpan(
        child: GestureDetector(
          onTap: () => _showImageDialog(context, imageData),
          child: Container(
            height: 150,
            width: 150,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: AppImageWidget(
              imageUrl: imageData['url'],
              imageId: imageData['id'],
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }
    
    // For other types, use a text span
    Color color;
    
    switch (type) {
      case _MatchType.character:
        color = Colors.blue;
        break;
      case _MatchType.location:
        color = Colors.green;
        break;
      case _MatchType.move:
        final moveRoll = data as MoveRoll;
        color = _getOutcomeColor(moveRoll.outcome);
        break;
      case _MatchType.oracle:
        color = Colors.purple;
        break;
      case _MatchType.image:
        color = Colors.grey;
        break;
    }
    
    return TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
      ),
      recognizer: TapGestureRecognizer()..onTap = () {
        _handleTap(context, type, data);
      },
    );
  }
  
  void _handleTap(BuildContext context, _MatchType type, dynamic data) {
    switch (type) {
      case _MatchType.character:
        if (onCharacterTap != null) {
          onCharacterTap!(data as Character);
        } else {
          // Show a default dialog if no callback is provided
          _showDefaultCharacterDialog(context, data as Character);
        }
        break;
      case _MatchType.location:
        if (onLocationTap != null) {
          onLocationTap!(data as Location);
        } else {
          // Show a default dialog if no callback is provided
          _showDefaultLocationDialog(context, data as Location);
        }
        break;
      case _MatchType.move:
        if (onMoveRollTap != null) {
          onMoveRollTap!(data as MoveRoll);
        } else {
          // Show a default dialog if no callback is provided
          _showDefaultMoveRollDialog(context, data as MoveRoll);
        }
        break;
      case _MatchType.oracle:
        if (onOracleRollTap != null) {
          onOracleRollTap!(data as OracleRoll);
        } else {
          // Show a default dialog if no callback is provided
          _showDefaultOracleRollDialog(context, data as OracleRoll);
        }
        break;
      case _MatchType.image:
        // Show image in a dialog
        _showImageDialog(context, data);
        break;
    }
  }
  
  // Show image in a dialog
  void _showImageDialog(BuildContext context, Map<String, String?> imageData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SizedBox(
            width: 300,
            height: 300,
            child: AppImageWidget(
              imageUrl: imageData['url'],
              imageId: imageData['id'],
              fit: BoxFit.contain,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  void _showDefaultCharacterDialog(BuildContext context, Character character) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(character.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (character.bio != null && character.bio!.isNotEmpty) ...[
                  const Text(
                    'Bio:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(character.bio!),
                  const SizedBox(height: 16),
                ],
                
                // Stats
                if (character.stats.isNotEmpty) ...[
                  const Text(
                    'Stats:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: character.stats.map((stat) => 
                      Chip(
                        label: Text('${stat.name}: ${stat.value}'),
                        backgroundColor: Colors.grey[200],
                      )
                    ).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Notes
                if (character.notes.isNotEmpty) ...[
                  const Text(
                    'Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...character.notes.map((note) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('• $note'),
                    )
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  void _showDefaultLocationDialog(BuildContext context, Location location) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(location.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (location.description != null && location.description!.isNotEmpty) ...[
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(location.description!),
                  const SizedBox(height: 16),
                ],
                
                if (location.notes.isNotEmpty) ...[
                  const Text(
                    'Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...location.notes.map((note) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('• $note'),
                    )
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  void _showDefaultMoveRollDialog(BuildContext context, MoveRoll moveRoll) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${moveRoll.moveName} Roll'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (moveRoll.moveDescription != null) ...[
                  MarkdownBody(
                    data: moveRoll.moveDescription!,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: Theme.of(context).textTheme.bodyMedium,
                      textAlign: WrapAlignment.start,
                    ),
                    softLineBreak: true,
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (moveRoll.rollType == 'action_roll') ...[
                  Text('Action Die: ${moveRoll.actionDie}'),
                  
                  if (moveRoll.statValue != null) ...[
                    const SizedBox(height: 4),
                    Text('Stat: ${moveRoll.stat} (${moveRoll.statValue})'),
                    const SizedBox(height: 4),
                    Text('Total Action Value: ${moveRoll.actionDie + moveRoll.statValue!}'),
                  ],
                  
                  if (moveRoll.modifier != null && moveRoll.modifier != 0) ...[
                    const SizedBox(height: 4),
                    Text('Modifier: ${moveRoll.modifier! > 0 ? '+' : ''}${moveRoll.modifier}'),
                  ],
                ],
                
                if (moveRoll.rollType == 'progress_roll' && moveRoll.progressValue != null) ...[
                  Text('Progress Value: ${moveRoll.progressValue}'),
                ],
                
                if (moveRoll.challengeDice.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Challenge Dice: ${moveRoll.challengeDice.join(' and ')}'),
                ],
                
                if (moveRoll.outcome != 'performed') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Outcome: ${moveRoll.outcome.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getOutcomeColor(moveRoll.outcome),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Move performed successfully',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  void _showDefaultOracleRollDialog(BuildContext context, OracleRoll oracleRoll) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${oracleRoll.oracleName} Result'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (oracleRoll.oracleTable != null) ...[
                  Text('Table: ${oracleRoll.oracleTable}'),
                  const SizedBox(height: 8),
                ],
                
                Text('Roll: ${oracleRoll.dice.join(', ')}'),
                const SizedBox(height: 16),
                
                Text(
                  'Result: ${oracleRoll.result}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  Character? _findCharacterByHandle(Game game, String handle) {
    try {
      return game.characters.firstWhere(
        (c) => (c.handle ?? c.getHandle()).toLowerCase() == handle.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
  
  Location? _findLocationByName(Game game, String name) {
    try {
      return game.locations.firstWhere(
        (l) => l.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
  
  MoveRoll? _findMoveRoll(String moveName, String outcome) {
    try {
      return moveRolls.firstWhere(
        (m) => m.moveName == moveName && m.outcome.toLowerCase().contains(outcome.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }
  
  OracleRoll? _findOracleRoll(String oracleName, String result) {
    try {
      return oracleRolls.firstWhere(
        (o) => o.oracleName == oracleName && o.result == result,
      );
    } catch (e) {
      return null;
    }
  }
  
  // Helper method to parse formatted text with HTML-like tags
  List<TextSpan> _parseFormattedText(BuildContext context, String text) {
    final List<TextSpan> spans = [];
    
    // Parse <b>, <i>, <h1>-<h6> tags
    final regex = RegExp(r'<(b|i|h[1-6])>(.*?)</\1>|([^<]+)', dotAll: true);
    
    for (final match in regex.allMatches(text)) {
      final tag = match.group(1);
      final content = match.group(2);
      final plainText = match.group(3);
      
      if (plainText != null) {
        spans.add(TextSpan(text: plainText));
      } else if (tag != null && content != null) {
        TextStyle style = DefaultTextStyle.of(context).style;
        
        if (tag == 'b') {
          style = style.copyWith(fontWeight: FontWeight.bold);
        } else if (tag == 'i') {
          style = style.copyWith(fontStyle: FontStyle.italic);
        } else if (tag.startsWith('h')) {
          final level = int.parse(tag.substring(1));
          double fontSize;
          
          switch (level) {
            case 1:
              fontSize = 24.0;
              break;
            case 2:
              fontSize = 22.0;
              break;
            case 3:
              fontSize = 20.0;
              break;
            case 4:
              fontSize = 18.0;
              break;
            case 5:
              fontSize = 16.0;
              break;
            case 6:
              fontSize = 14.0;
              break;
            default:
              fontSize = 16.0;
          }
          
          style = style.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          );
        }
        
        spans.add(TextSpan(
          text: content,
          style: style,
        ));
      }
    }
    
    return spans;
  }
  
  Color _getOutcomeColor(String outcome) {
    if (outcome.toLowerCase().contains('strong hit with a match')) {
      return Colors.green[700]!; // Darker green for strong hit with match
    } else if (outcome.toLowerCase().contains('strong hit')) {
      return Colors.green;
    } else if (outcome.toLowerCase().contains('weak hit')) {
      return Colors.orange;
    } else if (outcome.toLowerCase().contains('miss with a match')) {
      return Colors.red[700]!; // Darker red for miss with match
    } else if (outcome.toLowerCase().contains('miss')) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}

// Helper classes for parsing
enum _MatchType {
  character,
  location,
  move,
  oracle,
  image,
}

class _TextMatch {
  final int start;
  final int end;
  final _MatchType type;
  final dynamic data;
  
  _TextMatch({
    required this.start,
    required this.end,
    required this.type,
    required this.data,
  });
}

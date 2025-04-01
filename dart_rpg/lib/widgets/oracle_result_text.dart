import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../providers/datasworn_provider.dart';
import '../models/oracle.dart';
import '../models/character.dart';
import '../utils/datasworn_link_parser.dart';
import '../utils/dice_roller.dart';
import '../utils/logging_service.dart';
import '../screens/oracles_screen.dart';
import 'asset_detail_dialog.dart';

class OracleResultText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Function(OracleTable, int)? onRollLinkedOracle;

  const OracleResultText({
    super.key,
    required this.text,
    this.style,
    this.onRollLinkedOracle,
  });
  
  // Helper method to insert "collections" into a path before the last segment
  static String _insertCollectionsInPath(String path) {
    final parts = path.split('/');
    if (parts.length >= 3) {
      final lastPart = parts.removeLast();
      parts.add('collections');
      parts.add(lastPart);
      return parts.join('/');
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    // If the text doesn't contain any links, just display it as regular text
    if (!DataswornLinkParser.containsLinks(text)) {
      return Text(text, style: style);
    }

    // Parse the text to find any links
    final links = DataswornLinkParser.parseLinks(text);
    if (links.isEmpty) {
      return Text(text, style: style);
    }

    // Create a rich text widget with clickable links
    return Consumer<DataswornProvider>(
      builder: (context, dataswornProvider, _) {
        // Split the text by the links
        final parts = text.split(DataswornLinkParser.linkPattern);
        final loggingService = LoggingService();
        loggingService.debug(
          'OracleResultText: text="$text", parts=${parts.length}',
          tag: 'OracleResultText',
        );
        for (int i = 0; i < parts.length; i++) {
          loggingService.debug(
            '  Part $i: "${parts[i]}"',
            tag: 'OracleResultText',
          );
        }
        
        final spans = <InlineSpan>[];

        // Add the text parts and links alternately
        int linkIndex = 0;
        for (int i = 0; i < parts.length; i++) {
          // Add the text part
          if (parts[i].isNotEmpty) {
            spans.add(TextSpan(text: parts[i], style: style));
          }

          // Add the link if there's one for this position
          if (linkIndex < links.length && (i < parts.length - 1 || parts.length == 1)) {
            final link = links[linkIndex];
            spans.add(
              TextSpan(
                text: link.displayText,
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    final loggingService = LoggingService();
                    
                    // Handle different link types
                    if (link.linkType == 'asset') {
                      // Find the asset by path
                      final asset = DataswornLinkParser.findAssetByPath(
                        dataswornProvider,
                        link.path,
                      );
                      
                      if (asset != null) {
                        // Show asset detail dialog
                        showDialog(
                          context: context,
                          builder: (context) => AssetDetailDialog(asset: asset),
                        );
                      } else {
                        // Log error information
                        loggingService.error(
                          'Asset not found',
                          tag: 'OracleResultText',
                          error: {
                            'displayText': link.displayText,
                            'path': link.path,
                            'linkType': link.linkType,
                            'availableAssets': dataswornProvider.assets.map((a) => a.id).toList(),
                          },
                        );
                        
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Asset not found: "${link.displayText}" (${link.path})'),
                            duration: const Duration(seconds: 4),
                            action: SnackBarAction(
                              label: 'Dismiss',
                              onPressed: () {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              },
                            ),
                          ),
                        );
                      }
                    } else {
                      // Handle oracle links (default)
                      final linkedOracle = DataswornLinkParser.findOracleByPath(
                        dataswornProvider,
                        link.path,
                      );

                      if (linkedOracle != null) {
                        // Navigate to the linked oracle
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OracleTableScreen(table: linkedOracle),
                          ),
                        );
                      } else {
                        // Log detailed error information
                        final allTables = <Map<String, dynamic>>[];
                        for (final category in dataswornProvider.oracles) {
                          for (final table in category.tables) {
                            allTables.add({
                              'id': table.id,
                              'name': table.name,
                              'category': category.id,
                            });
                          }
                        }
                        
                        loggingService.error(
                          'Oracle not found',
                          tag: 'OracleResultText',
                          error: {
                            'displayText': link.displayText,
                            'path': link.path,
                            'linkType': link.linkType,
                            'availableCategories': dataswornProvider.oracles.map((c) => c.id).toList(),
                            'suggestedPaths': [
                              link.path,
                              '${link.path}/area',
                              '${link.path}/feature',
                              'oracles/${link.path.split('/').last}',
                              _insertCollectionsInPath(link.path),
                              '${_insertCollectionsInPath(link.path)}/area',
                            ],
                            'allTables': allTables,
                          },
                        );
                        
                        // Show a more detailed error if the oracle wasn't found
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Oracle not found: "${link.displayText}" (${link.path})'),
                            duration: const Duration(seconds: 4),
                            action: SnackBarAction(
                              label: 'Dismiss',
                              onPressed: () {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              },
                            ),
                          ),
                        );
                      }
                    }
                  },
              ),
            );
            linkIndex++;
          }
        }

        return RichText(
          text: TextSpan(
            style: style ?? DefaultTextStyle.of(context).style,
            children: spans,
          ),
        );
      },
    );
  }
}

class OracleResultDialog extends StatefulWidget {
  final OracleTable table;
  final int roll;
  final String result;

  const OracleResultDialog({
    super.key,
    required this.table,
    required this.roll,
    required this.result,
  });

  @override
  State<OracleResultDialog> createState() => _OracleResultDialogState();
}

class _OracleResultDialogState extends State<OracleResultDialog> {
  final List<LinkedOracleResult> _linkedResults = [];
  bool _isLoading = false;
  bool _searchedForLinks = false;
  String? _linkError;

  @override
  void initState() {
    super.initState();
    // Check if the result contains a link to another oracle
    if (DataswornLinkParser.containsLinks(widget.result)) {
      _processLinkedOracles();
    }
  }

  Future<void> _processLinkedOracles() async {
    final loggingService = LoggingService();
    
    setState(() {
      _isLoading = true;
      _searchedForLinks = true;
      _linkError = null;
    });

    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    final links = DataswornLinkParser.parseLinks(widget.result);
    
    loggingService.info(
      'Processing linked content',
      tag: 'OracleResultDialog',
      error: {
        'result': widget.result,
        'foundLinks': links.length,
        'links': links.map((l) => {
          'text': l.displayText, 
          'path': l.path,
          'type': l.linkType
        }).toList(),
      },
    );
    
    if (links.isEmpty) {
      setState(() {
        _isLoading = false;
        _linkError = 'No links found in the result text.';
      });
      loggingService.warning(
        'No links found in result text',
        tag: 'OracleResultDialog',
        error: {'result': widget.result},
      );
      return;
    }

    // Track if we found any links (either oracle or asset)
    bool foundAnyLinks = false;

    for (final link in links) {
      // Skip asset links in the recursive processing - they'll be handled directly when clicked
      if (link.linkType == 'asset') {
        // Just verify the asset exists
        final asset = DataswornLinkParser.findAssetByPath(
          dataswornProvider,
          link.path,
        );
        
        if (asset != null) {
          foundAnyLinks = true;
          // We don't add assets to the linked results, they'll be shown on demand
        }
        continue;
      }
      
      // Process oracle links
      final linkedOracle = DataswornLinkParser.findOracleByPath(
        dataswornProvider,
        link.path,
      );

      if (linkedOracle != null && linkedOracle.rows.isNotEmpty) {
        foundAnyLinks = true;
        
        // Roll on the linked oracle
        final rollResult = DiceRoller.rollOracle(linkedOracle.diceFormat);
        final total = rollResult['total'] as int;

        // Find the matching table entry
        OracleTableRow? matchingRow;
        for (final row in linkedOracle.rows) {
          if (row.matchesRoll(total)) {
            matchingRow = row;
            break;
          }
        }

        if (matchingRow != null) {
          _linkedResults.add(
            LinkedOracleResult(
              table: linkedOracle,
              roll: total,
              result: matchingRow.result,
            ),
          );

          // Check if this result also contains links (recursive)
          if (DataswornLinkParser.containsLinks(matchingRow.result)) {
            // We'll only process one level of recursion to avoid infinite loops
            final nestedLinks = DataswornLinkParser.parseLinks(matchingRow.result);
            for (final nestedLink in nestedLinks) {
              // Skip asset links in nested results
              if (nestedLink.linkType == 'asset') {
                continue;
              }
              
              final nestedOracle = DataswornLinkParser.findOracleByPath(
                dataswornProvider,
                nestedLink.path,
              );

              if (nestedOracle != null && nestedOracle.rows.isNotEmpty) {
                // Roll on the nested linked oracle
                final nestedRollResult = DiceRoller.rollOracle(nestedOracle.diceFormat);
                final nestedTotal = nestedRollResult['total'] as int;

                // Find the matching table entry
                OracleTableRow? nestedMatchingRow;
                for (final row in nestedOracle.rows) {
                  if (row.matchesRoll(nestedTotal)) {
                    nestedMatchingRow = row;
                    break;
                  }
                }

                if (nestedMatchingRow != null) {
                  _linkedResults.add(
                    LinkedOracleResult(
                      table: nestedOracle,
                      roll: nestedTotal,
                      result: nestedMatchingRow.result,
                    ),
                  );
                }
              }
            }
          }
        }
      }
    }

    // If we didn't find any linked results but we had links, show an error
    if (!foundAnyLinks && links.isNotEmpty) {
      // Get a list of all available tables and assets for debugging
      final allTables = <Map<String, dynamic>>[];
      for (final category in dataswornProvider.oracles) {
        for (final table in category.tables) {
          allTables.add({
            'id': table.id,
            'name': table.name,
            'category': category.id,
          });
        }
      }
      
      final allAssets = <Map<String, dynamic>>[];
      for (final asset in dataswornProvider.assets) {
        allAssets.add({
          'id': asset.id,
          'name': asset.name,
          'category': asset.category,
        });
      }
      
      // Log detailed error information
      loggingService.error(
        'Could not find referenced content',
        tag: 'OracleResultDialog',
        error: {
          'links': links.map((l) => {
            'text': l.displayText, 
            'path': l.path,
            'type': l.linkType
          }).toList(),
          'availableCategories': dataswornProvider.oracles.map((c) => c.id).toList(),
          'availableAssets': dataswornProvider.assets.map((a) => a.id).toList(),
          'allTables': allTables,
          'allAssets': allAssets,
        },
      );
      
      setState(() {
        _isLoading = false;
        _linkError = 'Found ${links.length} links, but could not find the referenced content.';
      });
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.table.name} Result'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Roll: ${widget.roll}'),
            const SizedBox(height: 16),
            
            // Main result with clickable links
            OracleResultText(
              text: widget.result,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            
            // Show linked oracle results section if we searched for links
            if (_searchedForLinks) ...[
              const SizedBox(height: 24),
              const Divider(),
              
              if (_linkedResults.isNotEmpty) ...[
                const Text(
                  'Linked Oracle Results:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                // List all linked results
                ...List.generate(_linkedResults.length, (index) {
                  final linkedResult = _linkedResults[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${linkedResult.table.name} (Roll: ${linkedResult.roll})',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 4),
                        OracleResultText(
                          text: linkedResult.result,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ] else if (_linkError != null) ...[
                // Show error message if we couldn't find linked oracles
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _linkError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
            
            // Show loading indicator while processing linked oracles
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
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
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Roll again on the original table
            _rollOnOracle(context, widget.table);
          },
          child: const Text('Roll Again'),
        ),
      ],
    );
  }

  void _rollOnOracle(BuildContext context, OracleTable table) {
    if (table.rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This oracle has no table entries'),
        ),
      );
      return;
    }
    
    // Roll on the oracle
    final rollResult = DiceRoller.rollOracle(table.diceFormat);
    final total = rollResult['total'] as int;
    
    // Find the matching table entry
    OracleTableRow? matchingRow;
    for (final row in table.rows) {
      if (row.matchesRoll(total)) {
        matchingRow = row;
        break;
      }
    }
    
    if (matchingRow == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No result found for roll: $total'),
        ),
      );
      return;
    }
    
    // Show the result
    showDialog(
      context: context,
      builder: (context) {
        return OracleResultDialog(
          table: table,
          roll: total,
          result: matchingRow!.result,
        );
      },
    );
  }
}

class LinkedOracleResult {
  final OracleTable table;
  final int roll;
  final String result;

  LinkedOracleResult({
    required this.table,
    required this.roll,
    required this.result,
  });
}

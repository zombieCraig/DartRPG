import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../providers/datasworn_provider.dart';
import '../models/oracle.dart';
import '../models/journal_entry.dart';
import '../utils/datasworn_link_parser.dart';
import '../utils/dice_roller.dart';
import '../utils/logging_service.dart';
import '../utils/oracle_reference_processor.dart';
import '../screens/oracles_screen.dart';
import 'asset_detail_dialog.dart';

class OracleResultText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Function(OracleTable, int)? onRollLinkedOracle;
  final bool processReferences;

  const OracleResultText({
    super.key,
    required this.text,
    this.style,
    this.onRollLinkedOracle,
    this.processReferences = false,
  });

  @override
  State<OracleResultText> createState() => _OracleResultTextState();
}

class _OracleResultTextState extends State<OracleResultText> {
  String _processedText = '';
  bool _isProcessing = false;
  bool _hasProcessed = false;
  
  @override
  void initState() {
    super.initState();
    _processedText = widget.text;
    
    // If we should process references, do it when the widget is initialized
    if (widget.processReferences && DataswornLinkParser.containsLinks(widget.text)) {
      _processOracleReferences();
    }
  }
  
  @override
  void didUpdateWidget(OracleResultText oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If the text changed, reset the processed state
    if (oldWidget.text != widget.text) {
      _processedText = widget.text;
      _hasProcessed = false;
      
      // If we should process references, do it when the widget is updated
      if (widget.processReferences && DataswornLinkParser.containsLinks(widget.text)) {
        _processOracleReferences();
      }
    }
  }
  
  Future<void> _processOracleReferences() async {
    if (_isProcessing || _hasProcessed) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
      
      // Process oracle references using the new utility
      final processResult = await OracleReferenceProcessor.processOracleReferences(
        widget.text,
        dataswornProvider,
      );
      
      setState(() {
        _processedText = processResult['processedText'] as String;
        _hasProcessed = true;
      });
    } catch (e) {
      LoggingService().error(
        'Error processing oracle references',
        tag: 'OracleResultText',
        error: e,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
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
    // If we're processing references and still loading, show a loading indicator
    if (widget.processReferences && _isProcessing) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    
    // If we've processed references, use the processed text
    final textToDisplay = widget.processReferences && _hasProcessed ? _processedText : widget.text;
    
    // If the text doesn't contain any links, just display it as regular text
    if (!DataswornLinkParser.containsLinks(textToDisplay)) {
      return Text(textToDisplay, style: widget.style);
    }

    // Parse the text to find any links
    final links = DataswornLinkParser.parseLinks(textToDisplay);
    if (links.isEmpty) {
      return Text(textToDisplay, style: widget.style);
    }

    // Create a rich text widget with clickable links
    return Consumer<DataswornProvider>(
      builder: (context, dataswornProvider, _) {
        // Split the text by the links
        final parts = textToDisplay.split(DataswornLinkParser.linkPattern);
        final loggingService = LoggingService();
        loggingService.debug(
          'OracleResultText: text="$textToDisplay", parts=${parts.length}',
          tag: 'OracleResultText',
        );
        
        final spans = <InlineSpan>[];

        // Add the text parts and links alternately
        int linkIndex = 0;
        for (int i = 0; i < parts.length; i++) {
          // Add the text part
          if (parts[i].isNotEmpty) {
            spans.add(TextSpan(text: parts[i], style: widget.style));
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
            style: widget.style ?? DefaultTextStyle.of(context).style,
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
  final String? text2; // Additional information for table_text2 oracle type

  const OracleResultDialog({
    super.key,
    required this.table,
    required this.roll,
    required this.result,
    this.text2, // Optional field
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
    
    try {
      // Process oracle references using the new utility
      final processResult = await OracleReferenceProcessor.processOracleReferences(
        widget.result,
        dataswornProvider,
      );
      
      final oracleRolls = processResult['rolls'] as List<OracleRoll>;
      
      // Convert OracleRoll objects to LinkedOracleResult objects
      for (final roll in oracleRolls) {
        // Find the oracle table for this roll
        final oracle = DataswornLinkParser.findOracleByPath(
          dataswornProvider,
          roll.oracleTable ?? '',
        );
        
        if (oracle != null) {
          _linkedResults.add(
            LinkedOracleResult(
              table: oracle,
              roll: roll.dice.isNotEmpty ? roll.dice.first : 0,
              result: roll.result,
            ),
          );
        }
      }
      
      // If we didn't find any linked results but the text contains links, show an error
      if (_linkedResults.isEmpty && DataswornLinkParser.containsLinks(widget.result)) {
        final links = DataswornLinkParser.parseLinks(widget.result);
        
        // Check if there are any oracle_rollable links
        final hasOracleLinks = links.any((link) => link.linkType == 'oracle_rollable');
        
        if (hasOracleLinks) {
          // Log detailed error information
          loggingService.error(
            'Could not find referenced oracles',
            tag: 'OracleResultDialog',
            error: {
              'result': widget.result,
              'links': links.map((l) => {
                'text': l.displayText, 
                'path': l.path,
                'type': l.linkType
              }).toList(),
            },
          );
          
          setState(() {
            _linkError = 'Found oracle references, but could not find the referenced content.';
          });
        }
      }
    } catch (e) {
      loggingService.error(
        'Error processing oracle references',
        tag: 'OracleResultDialog',
        error: e,
      );
      
      setState(() {
        _linkError = 'Error processing oracle references: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add logging to debug text2 display issue
    final loggingService = LoggingService();
    loggingService.debug(
      'OracleResultDialog.build: table=${widget.table.id}, oracleType=${widget.table.oracleType}, text2Label=${widget.table.text2Label}, text2=${widget.text2}',
      tag: 'OracleResultDialog',
    );
    
    // Log the condition for displaying text2
    final shouldShowText2 = widget.text2 != null && widget.table.text2Label != null;
    loggingService.debug(
      'OracleResultDialog.build: shouldShowText2=$shouldShowText2 (text2 != null: ${widget.text2 != null}, text2Label != null: ${widget.table.text2Label != null})',
      tag: 'OracleResultDialog',
    );
    
    return AlertDialog(
      title: Text('${widget.table.name} Result'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Roll: ${widget.roll}'),
            const SizedBox(height: 16),
            
            // Main result with clickable links and processed references
            OracleResultText(
              text: widget.result,
              style: const TextStyle(fontWeight: FontWeight.bold),
              processReferences: true,
            ),
            
            // Show text2 field if available
            if (widget.text2 != null && widget.table.text2Label != null) ...[
              const SizedBox(height: 16),
              Text(
                '${widget.table.text2Label}:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              OracleResultText(
                text: widget.text2!,
                style: const TextStyle(fontStyle: FontStyle.italic),
                processReferences: true,
              ),
            ],
            
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
                          processReferences: true,
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
    
    // Log the row data for debugging
    final loggingService = LoggingService();
    loggingService.debug(
      'OracleResultDialog._rollOnOracle: table=${table.id}, oracleType=${table.oracleType}, text2Label=${table.text2Label}, matchingRow.text2=${matchingRow.text2}',
      tag: 'OracleResultDialog',
    );
    
    // Show the result
    showDialog(
      context: context,
      builder: (context) {
        return OracleResultDialog(
          table: table,
          roll: total,
          result: matchingRow!.result,
          text2: matchingRow.text2, // Pass the text2 field
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

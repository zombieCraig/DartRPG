import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/datasworn_provider.dart';
import '../services/oracle_service.dart';
import '../utils/dice_roller.dart';
import '../utils/sentient_ai_utils.dart';

/// A dialog that appears when the Sentient AI is triggered.
class SentientAiDialog extends StatefulWidget {
  /// The name of the AI, if provided.
  final String? aiName;
  
  /// The persona of the AI, if provided.
  final String? aiPersona;
  
  /// The path to the AI image, if provided.
  final String? aiImagePath;
  
  /// Callback for when an oracle is selected.
  /// The callback receives the oracle key and the DataswornProvider instance.
  final Function(String, DataswornProvider) onOracleSelected;
  
  /// Callback for when the Ask the Oracle button is pressed.
  final VoidCallback? onAskOraclePressed;
  
  /// Creates a new SentientAiDialog.
  const SentientAiDialog({
    super.key,
    this.aiName,
    this.aiPersona,
    this.aiImagePath,
    required this.onOracleSelected,
    this.onAskOraclePressed,
  });
  
  /// Shows the SentientAiDialog.
  static Future<void> show({
    required BuildContext context,
    required String? aiName,
    required String? aiPersona,
    required String? aiImagePath,
    required Function(String, DataswornProvider) onOracleSelected,
    VoidCallback? onAskOraclePressed,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SentientAiDialog(
          aiName: aiName,
          aiPersona: aiPersona,
          aiImagePath: aiImagePath,
          onOracleSelected: onOracleSelected,
          onAskOraclePressed: onAskOraclePressed,
        );
      },
    );
  }
  
  /// Rolls on an AI oracle and returns the result.
  static Future<Map<String, dynamic>> rollOnAiOracle({
    required String oracleKey,
    required DataswornProvider dataswornProvider,
  }) async {
    // Extract just the last part of the key (without the "ai/" prefix)
    final simplifiedKey = oracleKey.split('/').last;
    
    // Use the recursive search function from OracleService with the simplified key
    final oracleTable = OracleService.findOracleTableByKeyAnywhere(simplifiedKey, dataswornProvider);
    
    if (oracleTable == null) {
      return {
        'success': false,
        'error': 'Oracle table not found: $oracleKey',
      };
    }
    
    final result = OracleService.rollOnOracleTable(oracleTable);
    
    if (result['success'] == true) {
      // Process oracle references if any
      final oracleRoll = result['oracleRoll'];
      final processResult = await OracleService.processOracleReferences(
        oracleRoll.result,
        dataswornProvider,
      );
      
      if (processResult['success'] == true) {
        oracleRoll.result = processResult['processedText'];
        oracleRoll.nestedRolls = processResult['nestedRolls'];
      }
    }
    
    return result;
  }
  
  @override
  State<SentientAiDialog> createState() => _SentientAiDialogState();
}

class _SentientAiDialogState extends State<SentientAiDialog> {
  // Track if the oracle has been consulted
  bool _oracleConsulted = false;
  
  // Store the oracle result
  String? _oracleResult;
  
  // Track if the result is positive
  bool? _isPositive;
  
  @override
  Widget build(BuildContext context) {
    // Extract persona name and description if available
    String? personaName;
    String? personaDescription;
    
    if (widget.aiPersona != null) {
      final parts = widget.aiPersona!.split(' - ');
      personaName = parts[0];
      personaDescription = parts.length > 1 ? parts[1] : null;
    }
    
    return AlertDialog(
      title: Text(
        widget.aiName != null ? "${widget.aiName} has appeared!" : "The Sentient AI has appeared!",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Image
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: SentientAiUtils.buildAiImage(
                  context,
                  widget.aiImagePath,
                  widget.aiPersona,
                ),
              ),
            ),
            
            // Persona name and description
            if (personaName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  personaName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            
            if (personaDescription != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  personaDescription,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ),
            
            const Divider(),
            
            // Guidance text
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "You can use the Core oracles to determine the purpose of the AI visit or Ask the Oracle to determine if this is a positive outcome.",
                style: TextStyle(fontSize: 14),
              ),
            ),
            
            // Ask the Oracle button - simplified to return Positive or Negative
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.help_outline),
                  label: const Text("Ask the Oracle"),
                  onPressed: () {
                    // Generate a random result (either Positive or Negative)
                    final bool isPositive = DiceRoller.rollDie(6) > 3; // 50% chance
                    final String result = isPositive ? "Positive" : "Negative";
                    
                    // Update the state to show the result
                    setState(() {
                      _oracleConsulted = true;
                      _oracleResult = result;
                      _isPositive = isPositive;
                    });
                  },
                ),
              ),
            ),
            
            // Oracle result section (only shown after consulting the oracle)
            if (_oracleConsulted && _oracleResult != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isPositive == true ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isPositive == true ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isPositive == true ? Icons.check_circle : Icons.cancel,
                          color: _isPositive == true ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Oracle Result:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isPositive == true ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _oracleResult!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isPositive == true ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Now select an outcome type below based on this result.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            
            const Divider(),
            
            // Outcome buttons section
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 12),
              child: Text(
                "Or select an outcome type:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            
            // Outcome buttons
            _buildOutcomeButton(
              context,
              "Positive Explorative",
              "positive_explorative",
              Colors.green,
              Icons.explore,
            ),
            
            _buildOutcomeButton(
              context,
              "Negative Explorative",
              "negative_explorative",
              Colors.red,
              Icons.explore_off,
            ),
            
            _buildOutcomeButton(
              context,
              "Positive Combat",
              "positive_combat",
              Colors.green,
              Icons.security,
            ),
            
            _buildOutcomeButton(
              context,
              "Negative Combat",
              "negative_combat",
              Colors.red,
              Icons.dangerous,
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            
            // Close button
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text("Close"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    // Simply close the dialog without any action
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Builds an outcome button with the given parameters.
  Widget _buildOutcomeButton(
    BuildContext context,
    String label,
    String oracleKey,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () {
            // Get the DataswornProvider before closing the dialog
            final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
            
            // Close the dialog
            Navigator.pop(context);
            
            // Call the callback with the oracle key and DataswornProvider
            widget.onOracleSelected("ai/$oracleKey", dataswornProvider);
          },
        ),
      ),
    );
  }
}

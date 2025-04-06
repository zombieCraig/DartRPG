import 'dart:io';
import 'package:flutter/material.dart';
import '../providers/datasworn_provider.dart';
import '../services/oracle_service.dart';

/// A dialog that appears when the Sentient AI is triggered.
class SentientAiDialog extends StatelessWidget {
  /// The name of the AI, if provided.
  final String? aiName;
  
  /// The persona of the AI, if provided.
  final String? aiPersona;
  
  /// The path to the AI image, if provided.
  final String? aiImagePath;
  
  /// Callback for when an oracle is selected.
  final Function(String) onOracleSelected;
  
  /// Callback for when the Ask the Oracle button is pressed.
  final VoidCallback? onAskOraclePressed;
  
  /// Creates a new SentientAiDialog.
  const SentientAiDialog({
    Key? key,
    this.aiName,
    this.aiPersona,
    this.aiImagePath,
    required this.onOracleSelected,
    this.onAskOraclePressed,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Extract persona name and description if available
    String? personaName;
    String? personaDescription;
    
    if (aiPersona != null) {
      final parts = aiPersona!.split(' - ');
      personaName = parts[0];
      personaDescription = parts.length > 1 ? parts[1] : null;
    }
    
    return AlertDialog(
      title: Text(
        aiName != null ? "$aiName has appeared!" : "The Sentient AI has appeared!",
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
            if (aiImagePath != null && File(aiImagePath!).existsSync())
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(aiImagePath!),
                      height: 150,
                      fit: BoxFit.cover,
                    ),
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
            
            // Ask the Oracle button
            if (onAskOraclePressed != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.help_outline),
                    label: const Text("Ask the Oracle"),
                    onPressed: () {
                      Navigator.pop(context);
                      onAskOraclePressed!();
                    },
                  ),
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
            Navigator.pop(context);
            onOracleSelected("ai/$oracleKey");
          },
        ),
      ),
    );
  }
  
  /// Shows the SentientAiDialog.
  static Future<void> show({
    required BuildContext context,
    required String? aiName,
    required String? aiPersona,
    required String? aiImagePath,
    required Function(String) onOracleSelected,
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
}

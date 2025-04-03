import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/move.dart';
import '../../models/journal_entry.dart';
import '../../services/roll_service.dart';
import 'action_roll_panel.dart';
import 'progress_roll_panel.dart';
import 'no_roll_panel.dart';
import 'move_oracle_panel.dart';

/// A widget for displaying the details of a move.
class MoveDetails extends StatelessWidget {
  final Move move;
  final VoidCallback onBack;
  final Function(Move, String, int, int) onActionRoll;
  final Function(Move, int) onProgressRoll;
  final Function(Move) onNoRoll;
  final Function(OracleRoll)? onOracleRollAdded;
  
  const MoveDetails({
    super.key,
    required this.move,
    required this.onBack,
    required this.onActionRoll,
    required this.onProgressRoll,
    required this.onNoRoll,
    this.onOracleRollAdded,
  });
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Moves'),
            onPressed: onBack,
          ),
          
          const SizedBox(height: 16),
          
          // Move name and roll type icon
          Row(
            children: [
              Expanded(
                child: Text(
                  move.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Icon(
                RollService.getRollTypeIcon(move.rollType),
                color: RollService.getRollTypeColor(move.rollType),
                size: 32,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Move category
          if (move.moveCategory != null || move.category != null) ...[
            Text(
              move.moveCategory ?? move.category!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Move trigger
          if (move.trigger != null) ...[
            Text(
              move.trigger!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Move description
          if (move.description != null) ...[
            MarkdownBody(
              data: move.description!,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: Theme.of(context).textTheme.bodyMedium,
              ),
              selectable: true,
            ),
            const SizedBox(height: 24),
          ],
          
          // Outcomes
          if (move.outcomes.isNotEmpty) ...[
            const Text(
              'Outcomes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...move.outcomes.map((outcome) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outcome.type.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    MarkdownBody(
                      data: outcome.description,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: Theme.of(context).textTheme.bodyMedium,
                        textAlign: WrapAlignment.start,
                      ),
                      selectable: true,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
          
          // Different UI based on roll type
          if (move.rollType == 'action_roll') ...[
            ActionRollPanel(
              move: move,
              onRoll: onActionRoll,
            ),
          ] else if (move.rollType == 'progress_roll') ...[
            ProgressRollPanel(
              move: move,
              onRoll: onProgressRoll,
            ),
          ] else if (move.rollType == 'no_roll') ...[
            NoRollPanel(
              move: move,
              onPerform: onNoRoll,
            ),
          ],
          
          // Oracle panel for moves with embedded oracles
          if (move.hasEmbeddedOracles && onOracleRollAdded != null) ...[
            MoveOraclePanel(
              move: move,
              onOracleRollAdded: onOracleRollAdded!,
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/connection.dart';

/// A panel for displaying connection action buttons
class ConnectionActionsPanel extends StatelessWidget {
  final Connection connection;
  final VoidCallback? onBond;
  final VoidCallback? onLose;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ConnectionActionsPanel({
    super.key,
    required this.connection,
    this.onBond,
    this.onLose,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status actions (only for active connections)
        if (connection.status == ConnectionStatus.active)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.heart_broken),
                  label: const Text('Lose'),
                  onPressed: onLose,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.favorite),
                  label: const Text('Bond'),
                  onPressed: onBond,
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                ),
              ],
            ),
          ),

        // Edit and delete actions
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (connection.status == ConnectionStatus.active)
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: onEdit,
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                onPressed: onDelete,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ),

        // Status information
        if (connection.status != ConnectionStatus.active)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(connection.status.icon, color: connection.status.color, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Status: ${connection.status.displayName}',
                  style: TextStyle(
                    color: connection.status.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  connection.status == ConnectionStatus.bonded
                      ? 'Bonded: ${_formatDate(connection.bondedAt)}'
                      : 'Lost: ${_formatDate(connection.lostAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import '../../models/network_route.dart';

/// A panel for displaying route action buttons
class RouteActionsPanel extends StatelessWidget {
  final NetworkRoute route;
  final VoidCallback? onComplete;
  final VoidCallback? onBurn;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const RouteActionsPanel({
    super.key,
    required this.route,
    this.onComplete,
    this.onBurn,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status actions (only for active routes)
        if (route.status == RouteStatus.active)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.local_fire_department),
                  label: const Text('Burn'),
                  onPressed: onBurn,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete'),
                  onPressed: onComplete,
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
              if (route.status == RouteStatus.active)
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
        if (route.status != RouteStatus.active)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(route.status.icon, color: route.status.color, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Status: ${route.status.displayName}',
                  style: TextStyle(
                    color: route.status.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  route.status == RouteStatus.completed
                      ? 'Completed: ${_formatDate(route.completedAt)}'
                      : 'Burned: ${_formatDate(route.burnedAt)}',
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

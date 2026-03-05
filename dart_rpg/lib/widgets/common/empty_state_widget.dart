import 'package:flutter/material.dart';

/// A reusable empty state widget shown when a list or section has no content.
///
/// Supports three variants:
/// - Simple message only (just [message])
/// - Message with icon ([message] + [icon])
/// - Message with create button ([message] + [actionLabel] + [onAction])
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
          ],
          Text(
            message,
            style: const TextStyle(fontSize: 18),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(actionLabel!),
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

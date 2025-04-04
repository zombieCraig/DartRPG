import 'package:flutter/material.dart';
import '../../models/clock.dart';
import 'clock_form.dart';

/// A dialog for creating or editing a clock
class ClockDialog {
  /// Show a dialog for creating a new clock
  static Future<Map<String, dynamic>?> showCreateDialog({
    required BuildContext context,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Clock'),
        content: SingleChildScrollView(
          child: ClockForm(
            onSubmit: (title, segments, type) {
              Navigator.of(context).pop({
                'title': title,
                'segments': segments,
                'type': type,
              });
            },
          ),
        ),
      ),
    );
  }
  
  /// Show a dialog for editing an existing clock
  static Future<Map<String, dynamic>?> showEditDialog({
    required BuildContext context,
    required Clock clock,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Clock'),
        content: SingleChildScrollView(
          child: ClockForm(
            initialClock: clock,
            onSubmit: (title, segments, type) {
              Navigator.of(context).pop({
                'title': title,
                'segments': segments,
                'type': type,
              });
            },
          ),
        ),
      ),
    );
  }
  
  /// Show a confirmation dialog for deleting a clock
  static Future<bool?> showDeleteConfirmation({
    required BuildContext context,
    required Clock clock,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Clock'),
        content: Text('Are you sure you want to delete "${clock.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  /// Show a confirmation dialog for resetting a clock
  static Future<bool?> showResetConfirmation({
    required BuildContext context,
    required Clock clock,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Clock'),
        content: Text('Are you sure you want to reset "${clock.title}" to zero?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

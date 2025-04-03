import 'package:flutter/material.dart';

/// A more compact version of StatAdjusterWidget for mobile displays
class CompactStatWidget extends StatelessWidget {
  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final Function(int) onChanged;
  final bool isEditable;
  final Color? valueColor;

  const CompactStatWidget({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 10,
    this.isEditable = true,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 2.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 2),
          if (isEditable)
            InkWell(
              onTap: value > minValue ? () => onChanged(value - 1) : null,
              child: Container(
                padding: const EdgeInsets.all(1),
                child: Icon(
                  Icons.remove,
                  size: 12,
                  color: value > minValue ? null : Colors.grey,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
          if (isEditable)
            InkWell(
              onTap: value < maxValue ? () => onChanged(value + 1) : null,
              child: Container(
                padding: const EdgeInsets.all(1),
                child: Icon(
                  Icons.add,
                  size: 12,
                  color: value < maxValue ? null : Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

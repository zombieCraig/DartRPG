import 'package:flutter/material.dart';

class StatAdjusterWidget extends StatelessWidget {
  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final Function(int) onChanged;
  final bool isEditable;
  final Color? valueColor;

  const StatAdjusterWidget({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 10,
    this.isEditable = true,
    this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEditable)
                InkWell(
                  onTap: value > minValue ? () => onChanged(value - 1) : null,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.remove,
                      size: 16,
                      color: value > minValue ? null : Colors.grey,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ),
              if (isEditable)
                InkWell(
                  onTap: value < maxValue ? () => onChanged(value + 1) : null,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.add,
                      size: 16,
                      color: value < maxValue ? null : Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

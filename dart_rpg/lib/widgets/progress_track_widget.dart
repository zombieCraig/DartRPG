import 'package:flutter/material.dart';

class ProgressTrackWidget extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Function(int)? onChanged;
  final bool isEditable;

  const ProgressTrackWidget({
    Key? key,
    required this.label,
    required this.value,
    this.maxValue = 10,
    this.onChanged,
    this.isEditable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 20,
                child: Row(
                  children: List.generate(maxValue, (index) {
                    final isFilled = index < value;
                    return Expanded(
                      child: GestureDetector(
                        onTap: isEditable && onChanged != null 
                            ? () => onChanged!(index + 1)
                            : null,
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: isFilled 
                                ? Theme.of(context).colorScheme.primary 
                                : Colors.grey[300],
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('$value/$maxValue'),
          ],
        ),
      ],
    );
  }
}

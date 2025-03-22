import 'package:flutter/material.dart';

class ImpactToggleWidget extends StatelessWidget {
  final String label;
  final String category;
  final bool value;
  final Function(bool)? onChanged;
  final bool isEditable;

  const ImpactToggleWidget({
    Key? key,
    required this.label,
    required this.category,
    required this.value,
    this.onChanged,
    this.isEditable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: isEditable && onChanged != null 
          ? (newValue) => onChanged!(newValue ?? false)
          : null,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

class ImpactCategoryWidget extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ImpactCategoryWidget({
    Key? key,
    required this.title,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.all(4.0),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

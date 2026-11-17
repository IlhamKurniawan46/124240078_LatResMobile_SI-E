import 'package:flutter/material.dart';

/// Reusable horizontal scrollable filter bar displaying FilterChip for each author/publisher.
class CustomFilterChip extends StatelessWidget {
  final List<String> authors;
  final String? selectedAuthor;
  final ValueChanged<String?> onSelected;

  const CustomFilterChip({
    super.key,
    required this.authors,
    required this.selectedAuthor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (authors.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: authors.map((author) {
          final isSelected = selectedAuthor == author;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              key: Key('filter_chip_$author'),
              label: Text(author),
              selected: isSelected,
              showCheckmark: true,
              checkmarkColor: isSelected
                  ? theme.colorScheme.onPrimary
                  : null,
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : null,
              ),
              onSelected: (selected) {
                if (selected) {
                  onSelected(author);
                } else {
                  onSelected(null);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/category.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  factory CategoryChip.all({
    required bool selected,
    required VoidCallback onTap,
  }) {
    return CategoryChip(
      label: 'All',
      color: const Color(0xFF334155),
      selected: selected,
      onTap: onTap,
    );
  }

  factory CategoryChip.fromCategory({
    required Category category,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return CategoryChip(
      label: category.name,
      color: category.chipColor,
      selected: selected,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      selectedColor: color.withValues(alpha: 0.22),
      side: BorderSide(color: selected ? color : color.withValues(alpha: 0.3)),
      checkmarkColor: color,
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: const Color(0xFF0F172A),
      ),
    );
  }
}

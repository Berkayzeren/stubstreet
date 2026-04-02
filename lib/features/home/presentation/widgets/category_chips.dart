// lib/features/home/presentation/widgets/category_chips.dart

import 'package:flutter/material.dart';
import '../../../tickets/domain/entities/ticket.dart';

class CategoryChips extends StatelessWidget {
  final TicketCategory? selectedCategory;
  final Function(TicketCategory?) onCategorySelected;

  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "Tümü" chip'i
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Tümü'),
              selected: selectedCategory == null,
              onSelected: (selected) {
                if (selected) {
                  onCategorySelected(null);
                }
              },
            ),
          ),
          // Kategori chip'leri
          ...TicketCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Text(category.icon),
                label: Text(category.displayName),
                selected: selectedCategory == category,
                onSelected: (selected) {
                  onCategorySelected(selected ? category : null);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

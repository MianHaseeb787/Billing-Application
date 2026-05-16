import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.secondaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppConstants.secondaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryChipList extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final Map<String, IconData>? categoryIcons;

  const CategoryChipList({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.categoryIcons,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 4),
          ...categories.map((category) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: CategoryChip(
                label: category,
                isSelected: category == selectedCategory,
                onTap: () => onCategorySelected(category),
                icon: categoryIcons?[category],
              ),
            );
          }),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

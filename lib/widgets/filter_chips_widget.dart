import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const List<String> kCategories = [
  'All',
  'Breakfast',
  'Lunch',
  'Dinner',
  'Snack',
  'Pasta',
  'Italian',
  'Indian',
  'Mexican',
  'Seafood',
  'Thai',
  'Dessert',
  'Salad',
  'American',
];

const List<String> kDifficulties = [
  'All',
  'Easy',
  'Medium',
  'Hard',
];

class FilterChipsWidget extends StatelessWidget {
  final String selectedCategory;
  final String selectedDifficulty;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onDifficultyChanged;

  const FilterChipsWidget({
    super.key,
    required this.selectedCategory,
    required this.selectedDifficulty,
    required this.onCategoryChanged,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category row
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: kCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = kCategories[index];
              final isSelected = cat == selectedCategory;
              return _FilterChip(
                label: cat,
                isSelected: isSelected,
                onTap: () => onCategoryChanged(cat),
                selectedColor: const Color(0xFF1A3D2B),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Difficulty row
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: kDifficulties.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final diff = kDifficulties[index];
              final isSelected = diff == selectedDifficulty;
              return _FilterChip(
                label: diff,
                isSelected: isSelected,
                onTap: () => onDifficultyChanged(diff),
                selectedColor: _difficultyColor(diff),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _difficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return const Color(0xFF4CAF50);
      case 'medium':
        return const Color(0xFFE8A838);
      case 'hard':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF1A3D2B);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? selectedColor
                : const Color(0xFFDDDAD5),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF555555),
          ),
        ),
      ),
    );
  }
}

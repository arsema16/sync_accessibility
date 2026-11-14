import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Full-width selectable option row used in Accessibility Settings,
/// identity selection, and support preferences.
class SyncOptionCard extends StatelessWidget {
  const SyncOptionCard({
    super.key,
    required this.icon,
    required this.label,
    this.description,
    required this.selected,
    required this.onTap,
    this.multi = false,
  });

  final IconData icon;
  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  /// true = checkbox style, false = radio style
  final bool multi;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      hint: description,
      value: selected ? 'Selected' : 'Not selected',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE0E0E0),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _SelectionIndicator(selected: selected, multi: multi),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected, required this.multi});
  final bool selected;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    if (multi) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFBDBDBD),
            width: 2,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : const Color(0xFFBDBDBD),
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.circle, color: Colors.white, size: 10)
          : null,
    );
  }
}

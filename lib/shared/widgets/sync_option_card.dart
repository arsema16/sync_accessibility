import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Full-width selectable option row used in Accessibility Settings,
/// identity selection, and support preferences.
///
/// Visual language (shared by every step of onboarding):
///   - 22dp card, 1.2dp neutral border → 2dp teal border + soft shadow when
///     selected, so selection is signalled by shape AND colour, never colour
///     alone.
///   - A tinted rounded-square holds the option icon.
///   - The trailing indicator is a filled checkbox ([multi]) or radio.
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.cardBorder,
              width: selected ? 2 : 1.2,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.shadowSoft,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryContainer
                      : AppColors.cardAqua,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.onPrimaryContainer, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.cardInk,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        description!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.cardInkMuted,
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
        duration: const Duration(milliseconds: 180),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardTrack,
            width: selected ? 0 : 1.5,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.cardTrack,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.circle, color: Colors.white, size: 10)
          : null,
    );
  }
}

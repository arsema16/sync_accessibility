import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Light teal informational or privacy banner.
class SyncInfoBanner extends StatelessWidget {
  const SyncInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

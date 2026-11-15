import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';

/// The dark floating capsule bottom navigation shared by the four main tabs.
///
/// Accessibility notes:
///   - Every item carries a visible text label, so the tab is never
///     identified by icon or colour alone.
///   - [Semantics.selected] exposes the active tab to screen readers, and the
///     active item also inverts to a filled white pill (shape + colour).
///   - Each item is 58dp tall and a quarter of the row wide, comfortably
///     over the 48dp minimum tap target.
class SyncBottomNav extends StatelessWidget {
  const SyncBottomNav({super.key, required this.currentIndex});

  /// 0 = Home, 1 = My Jobs, 2 = Profile, 3 = More.
  final int currentIndex;

  static const List<String> _labels = <String>[
    'Home',
    'My Jobs',
    'Profile',
    'More',
  ];

  static const List<IconData> _icons = <IconData>[
    Icons.home_rounded,
    Icons.bookmark_rounded,
    Icons.person_rounded,
    Icons.more_horiz_rounded,
  ];

  static const List<String> _routes = <String>[
    RouteNames.jobs,
    RouteNames.myJobs,
    RouteNames.profile,
    RouteNames.more,
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.navBar,
          borderRadius: BorderRadius.all(Radius.circular(37)),
          boxShadow: [
            BoxShadow(
              color: AppColors.navBarShadow,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < _labels.length; i++)
              Expanded(
                child: _NavItem(
                  label: _labels[i],
                  icon: _icons[i],
                  selected: i == currentIndex,
                  onTap: () {
                    if (i == currentIndex) return;
                    context.pushNamed(_routes[i]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.navBar : AppColors.navItemIdle;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 58,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(29),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: fg),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

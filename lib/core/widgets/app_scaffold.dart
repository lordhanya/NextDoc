import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../constants/design_tokens.dart';

final class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/recent')) return 1;
    if (location.startsWith('/tools')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/recent');
      case 2:
        context.go('/tools');
      case 3:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      body: child,
      bottomNavigationBar: _PremiumNav(
        currentIndex: currentIndex,
        isLight: isLight,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Floating Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────

final class _PremiumNav extends StatelessWidget {
  final int currentIndex;
  final bool isLight;
  final ValueChanged<int> onTap;

  const _PremiumNav({
    required this.currentIndex,
    required this.isLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isLight ? AppColors.lightNavBackground : AppColors.darkNavBackground;
    final borderColor = isLight
        ? AppColors.lightBorder.withAlpha(120)
        : AppColors.darkBorder.withAlpha(80);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: DesignTokens.navShadow(isLight),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: LucideIcons.house,
                label: 'Home',
                isSelected: currentIndex == 0,
                isLight: isLight,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: LucideIcons.file_text,
                label: 'Recent',
                isSelected: currentIndex == 1,
                isLight: isLight,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: LucideIcons.box,
                label: 'Tools',
                isSelected: currentIndex == 2,
                isLight: isLight,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: LucideIcons.settings,
                label: 'Settings',
                isSelected: currentIndex == 3,
                isLight: isLight,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation Item with elegant active state
// ─────────────────────────────────────────────────────────────────────────────

final class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isLight;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unselectedColor = isLight ? AppColors.lightIconColor : AppColors.darkIconColor;
    final activeBg = isLight
        ? AppColors.primary.withAlpha(15)
        : AppColors.primary.withAlpha(25);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: DesignTokens.durationNormal,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isSelected)
                  AnimatedContainer(
                    duration: DesignTokens.durationSlow,
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      shape: BoxShape.circle,
                    ),
                  ),
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : unselectedColor,
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: AppSpacing.xxs),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

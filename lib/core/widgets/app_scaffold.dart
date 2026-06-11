import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../constants/app_colors.dart';
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

final class _NavItemData {
  final IconData icon;
  final String label;
  const _NavItemData({required this.icon, required this.label});
}

final class _PremiumNav extends StatelessWidget {
  final int currentIndex;
  final bool isLight;
  final ValueChanged<int> onTap;

  const _PremiumNav({
    required this.currentIndex,
    required this.isLight,
    required this.onTap,
  });

  static const _navItems = [
    _NavItemData(icon: LucideIcons.house, label: 'Home'),
    _NavItemData(icon: LucideIcons.file_text, label: 'Recent'),
    _NavItemData(icon: LucideIcons.box, label: 'Tools'),
    _NavItemData(icon: LucideIcons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final borderColor = isLight
        ? AppColors.lightBorder.withAlpha(100)
        : AppColors.darkBorder.withAlpha(60);
    final unselectedColor = AppColors.primary.withAlpha(isLight ? 170 : 200);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navBg = isLight
        ? const Color(0xB0EEF2FF)
        : const Color(0xB012122A);

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 8 + bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: navBg,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: borderColor, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: isLight
                      ? const Color(0x1A000000)
                      : const Color(0x40000000),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: isLight
                      ? const Color(0x0D000000)
                      : const Color(0x22000000),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: isLight
                      ? const Color(0x05000000)
                      : const Color(0x12000000),
                  blurRadius: 48,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    final itemWidth = totalWidth / 4;

                    return SizedBox(
                      width: totalWidth,
                      height: 36,
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            left: itemWidth * currentIndex + 4,
                            width: itemWidth - 8,
                            top: 0,
                            bottom: 0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF7C5CFF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                          Row(
                            children: List.generate(4, (index) {
                              final item = _navItems[index];
                              final isActive = currentIndex == index;
                              return Expanded(
                                child: Tooltip(
                                  message: item.label,
                                  child: GestureDetector(
                                    onTap: () => onTap(index),
                                    behavior: HitTestBehavior.opaque,
                                    child: Center(
                                      child: AnimatedScale(
                                        scale: isActive ? 1.0 : 0.85,
                                        duration: DesignTokens.durationNormal,
                                        curve: Curves.easeOutBack,
                                        child: AnimatedContainer(
                                          duration: DesignTokens.durationNormal,
                                          curve: Curves.easeOut,
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Colors.white.withAlpha(20)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            item.icon,
                                            size: 20,
                                            color: isActive ? Colors.white : unselectedColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ),
          ),
        ),
      ),
    );
  }
}

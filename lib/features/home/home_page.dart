import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/custom_search_bar.dart';
import '../../core/widgets/recent_files_section.dart';
import '../../core/widgets/section_title.dart';

final class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        _BackgroundAtmosphere(isLight: isLight),
        SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, isLight)),
              SliverToBoxAdapter(child: _buildSearchBar(context, isLight)),
              SliverToBoxAdapter(child: _buildQuickToolsSection(context, isLight)),
              SliverToBoxAdapter(child: _buildRecentFiles(context)),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20 + bottomInset,
          child: _ScanFab(isLight: isLight),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isLight) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xxxl,
        AppSpacing.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: const [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            blendMode: BlendMode.srcIn,
            child: Text(
              'NextDoc',
              style: AppTextStyles.display.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your document workspace',
            style: AppTextStyles.bodySmall.copyWith(
              color: isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isLight) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xxl + AppSpacing.sm,
        AppSpacing.screenPadding,
        0,
      ),
      child: CustomSearchBar(hintText: 'Search documents...'),
    );
  }

  Widget _buildQuickToolsSection(BuildContext context, bool isLight) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xxl + AppSpacing.sm,
        AppSpacing.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Quick Tools'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.0,
            ),
            itemCount: _toolData.length,
            itemBuilder: (context, index) {
              final tool = _toolData[index];
              return _ToolDashboardCard(
                tool: tool,
                isLight: isLight,
                onTap: () => context.push(tool.route),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentFiles(BuildContext context) {
    return RecentFilesSection(
      displayMode: RecentFilesDisplayMode.grid,
      title: 'Recent Files',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tool data for the dashboard
// ─────────────────────────────────────────────────────────────────────────────

final class _ToolInfo {
  final IconData icon;
  final String label;
  final String description;
  final String route;
  final Color color;

  const _ToolInfo({
    required this.icon,
    required this.label,
    required this.description,
    required this.route,
    required this.color,
  });
}

const _toolData = <_ToolInfo>[
  _ToolInfo(
    icon: LucideIcons.image,
    label: 'JPG to PDF',
    description: 'Convert images to PDF documents',
    route: '/tools/image-to-pdf',
    color: AppColors.iconImageToPdf,
  ),
  _ToolInfo(
    icon: LucideIcons.file_plus,
    label: 'Merge PDF',
    description: 'Combine multiple PDFs into one',
    route: '/tools/merge',
    color: AppColors.iconMerge,
  ),
  _ToolInfo(
    icon: LucideIcons.minimize,
    label: 'Compress PDF',
    description: 'Reduce PDF file size efficiently',
    route: '/tools/compress',
    color: AppColors.iconCompress,
  ),
  _ToolInfo(
    icon: LucideIcons.scissors,
    label: 'Split PDF',
    description: 'Extract or split PDF pages',
    route: '/tools/split',
    color: AppColors.iconSplit,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Premium Tool Dashboard Card with per-tool semantic color
// ─────────────────────────────────────────────────────────────────────────────

final class _ToolDashboardCard extends StatefulWidget {
  final _ToolInfo tool;
  final bool isLight;
  final VoidCallback onTap;

  const _ToolDashboardCard({
    required this.tool,
    required this.isLight,
    required this.onTap,
  });

  @override
  State<_ToolDashboardCard> createState() => _ToolDashboardCardState();
}

final class _ToolDashboardCardState extends State<_ToolDashboardCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final isLight = widget.isLight;

    final cardBg = isLight ? AppColors.lightSurface1 : AppColors.darkSurface1;
    final pressedBg = isLight ? AppColors.lightSurface2 : AppColors.darkSurface2;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary;
    final mutedColor = isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted;
    final borderColor = isLight ? AppColors.lightBorder : AppColors.darkBorder;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: DesignTokens.durationFast,
        curve: Curves.easeOut,
        transform: _isPressed
            ? Matrix4.diagonal3Values(0.96, 0.96, 1.0)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: _isPressed ? pressedBg : cardBg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: _isPressed
                ? tool.color.withAlpha(100)
                : borderColor.withAlpha(80),
            width: _isPressed ? 1.0 : 0.5,
          ),
          boxShadow: [
            if (_isPressed) ...DesignTokens.glowSm(tool.color),
            if (!_isPressed) ...DesignTokens.shadowSm,
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient icon container ──────────────────────────────
            AnimatedContainer(
              duration: DesignTokens.durationNormal,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tool.color,
                    tool.color.withAlpha(160),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: DesignTokens.glowSm(tool.color),
              ),
              child: Icon(
                tool.icon,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // ── Label ───────────────────────────────────────────────
            Text(
              tool.label,
              style: AppTextStyles.titleSmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            // ── Description ─────────────────────────────────────────
            Text(
              tool.description,
              style: AppTextStyles.caption.copyWith(
                color: mutedColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scan FAB — camera icon to open Scan Document tool
// ─────────────────────────────────────────────────────────────────────────────

final class _ScanFab extends StatefulWidget {
  final bool isLight;
  const _ScanFab({required this.isLight});

  @override
  State<_ScanFab> createState() => _ScanFabState();
}

final class _ScanFabState extends State<_ScanFab> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        context.push('/tools/scan');
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF7C5CFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(100),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppColors.primary.withAlpha(40),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(LucideIcons.camera, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background atmosphere — subtle radial gradient lighting
// ─────────────────────────────────────────────────────────────────────────────

final class _BackgroundAtmosphere extends StatelessWidget {
  final bool isLight;

  const _BackgroundAtmosphere({required this.isLight});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: [
            // Primary glow — top right
            Positioned(
              top: -120,
              right: -80,
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 0.7,
                    colors: [
                      isLight
                          ? AppColors.primary.withAlpha(8)
                          : AppColors.primary.withAlpha(18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Secondary glow — top left
            Positioned(
              top: 20,
              left: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.6,
                    colors: [
                      isLight
                          ? AppColors.secondary.withAlpha(5)
                          : AppColors.secondary.withAlpha(12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Subtle third glow — center-right edge
            Positioned(
              top: 300,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.5,
                    colors: [
                      isLight
                          ? AppColors.primary.withAlpha(4)
                          : AppColors.primary.withAlpha(10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

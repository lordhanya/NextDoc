import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/typography.dart';

final class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

final class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isPressed = false;

  Future<void> _onGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_welcome', false);
    AppRouter.showWelcome = false;
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Deep background ─────────────────────────────────────────
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A0A0B),
                    Color(0xFF0D0D12),
                    Color(0xFF0A0A0B),
                  ],
                ),
              ),
            ),
          ),

          // ── Atmospheric glow circles ────────────────────────────────
          const Positioned.fill(
            child: IgnorePointer(
              child: _BackgroundGlow(),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                _buildBrand(),
                const SizedBox(height: AppSpacing.xxl),

                _buildTagline(),
                const SizedBox(height: AppSpacing.md),

                _buildSubtitle(),

                const Spacer(flex: 4),

                _buildButton(),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      blendMode: BlendMode.srcIn,
      child: Text(
        'NextDoc',
        style: AppTextStyles.display.copyWith(
          color: Colors.white,
          fontSize: 44,
          letterSpacing: -1.2,
          height: 1.1,
        ),
      ),
    ).animate().fadeIn(
      duration: 1000.ms,
      delay: 400.ms,
      curve: Curves.easeOut,
    ).slideY(
      begin: 0.08,
      end: 0,
      curve: Curves.easeOut,
    );
  }

  Widget _buildTagline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppTextStyles.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          children: [
            const TextSpan(text: 'All your PDF tools.\nOne '),
            TextSpan(
              text: 'refined',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: ' workspace.'),
          ],
        ),
      ),
    ).animate().fadeIn(
      duration: 1000.ms,
      delay: 900.ms,
      curve: Curves.easeOut,
    ).slideY(
      begin: 0.06,
      end: 0,
      curve: Curves.easeOut,
    );
  }

  Widget _buildSubtitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl + AppSpacing.lg,
      ),
      child: Text(
        'Merge, compress, convert, split and manage your documents '
        'with premium tools. No limits, no complexity.',
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(
          color: Colors.white.withAlpha(150),
          fontSize: 14,
          height: 1.6,
        ),
      ),
    ).animate().fadeIn(
      duration: 1000.ms,
      delay: 1100.ms,
      curve: Curves.easeOut,
    );
  }

  Widget _buildButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _onGetStarted();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: DesignTokens.durationFast,
        curve: Curves.easeOut,
        transform: _isPressed
            ? Matrix4.diagonal3Values(0.96, 0.96, 1.0)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl + AppSpacing.lg + 4,
          vertical: AppSpacing.lg + 2,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xxl + 4),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(60),
              blurRadius: 24,
              offset: Offset.zero,
            ),
            BoxShadow(
              color: AppColors.primary.withAlpha(25),
              blurRadius: 48,
              offset: Offset.zero,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Get Started',
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              LucideIcons.arrow_right,
              size: 20,
              color: Colors.white,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      duration: 1000.ms,
      delay: 1300.ms,
      curve: Curves.easeOut,
    ).slideY(
      begin: 0.06,
      end: 0,
      curve: Curves.easeOut,
    );
  }
}

// ── Atmospheric background glow blobs ────────────────────────────────────

final class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Primary blob — top right (large purple orb)
        Positioned(
          top: -140,
          right: -80,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(0.2, -0.3),
                radius: 0.65,
                colors: [
                  AppColors.primary.withAlpha(80),
                  AppColors.primary.withAlpha(35),
                  AppColors.primary.withAlpha(10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Secondary blob — bottom left (blue orb)
        Positioned(
          bottom: -100,
          left: -60,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.2, 0.3),
                radius: 0.6,
                colors: [
                  AppColors.secondary.withAlpha(65),
                  AppColors.secondary.withAlpha(30),
                  AppColors.secondary.withAlpha(8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Warm blob — center-right (medium accent)
        Positioned(
          top: 280,
          right: -40,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.55,
                colors: [
                  AppColors.primary.withAlpha(55),
                  AppColors.primary.withAlpha(25),
                  AppColors.primary.withAlpha(6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

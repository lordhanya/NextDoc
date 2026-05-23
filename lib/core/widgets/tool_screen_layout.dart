import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_spacing.dart';
import '../constants/app_radius.dart';
import '../constants/app_colors.dart';
import '../theme/typography.dart';
import 'recent_files_section.dart';
import 'upload_dropzone_card.dart';

final class ToolScreenLayout extends ConsumerWidget {
  final String title;
  final IconData dropIcon;
  final String dropTitle;
  final String dropSubtitle;
  final Future<void> Function() onUpload;

  const ToolScreenLayout({
    super.key,
    required this.title,
    required this.dropIcon,
    required this.dropTitle,
    required this.dropSubtitle,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(title, style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildUploadZone(context)),
            SliverToBoxAdapter(
              child: RecentFilesSection(
                displayMode: RecentFilesDisplayMode.list,
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxxl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadZone(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        0,
      ),
      child: Column(
        children: [
          UploadDropzoneCard(
            icon: dropIcon,
            title: dropTitle,
            subtitle: dropSubtitle,
            onTap: onUpload,
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: _UploadButton(onTap: onUpload),
          ),
        ],
      ),
    );
  }
}

final class _UploadButton extends StatefulWidget {
  final Future<void> Function() onTap;

  const _UploadButton({required this.onTap});

  @override
  State<_UploadButton> createState() => _UploadButtonState();
}

final class _UploadButtonState extends State<_UploadButton> {
  bool _isPressed = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _isLoading ? null : (_) => setState(() => _isPressed = true),
      onTapUp: _isLoading ? null : (_) async {
        setState(() {
          _isPressed = false;
          _isLoading = true;
        });
        try {
          await widget.onTap();
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : Text(
                    'Select Files',
                    style: AppTextStyles.button,
                  ),
          ),
        ),
      ),
    );
  }
}

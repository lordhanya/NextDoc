import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_spacing.dart';
import '../constants/app_radius.dart';
import '../constants/app_colors.dart';
import '../theme/typography.dart';
import 'glass_card.dart';
import 'section_title.dart';
import 'upload_dropzone_card.dart';
import '../../features/home/models/recent_file_model.dart';

final class ToolScreenLayout extends StatelessWidget {
  final String title;
  final IconData dropIcon;
  final String dropTitle;
  final String dropSubtitle;
  final VoidCallback onUpload;

  const ToolScreenLayout({
    super.key,
    required this.title,
    required this.dropIcon,
    required this.dropTitle,
    required this.dropSubtitle,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
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
            SliverToBoxAdapter(child: _buildRecentSection()),
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

  Widget _buildRecentSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xxl,
        AppSpacing.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Recent Files'),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: fakeRecentFiles.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final file = fakeRecentFiles[index];
              return _RecentFileRow(file: file);
            },
          ),
        ],
      ),
    );
  }
}

final class _UploadButton extends StatefulWidget {
  final VoidCallback onTap;

  const _UploadButton({required this.onTap});

  @override
  State<_UploadButton> createState() => _UploadButtonState();
}

final class _UploadButtonState extends State<_UploadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap.call();
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
            child: Text(
              'Select Files',
              style: AppTextStyles.button,
            ),
          ),
        ),
      ),
    );
  }
}

final class _RecentFileRow extends StatelessWidget {
  final RecentFile file;

  const _RecentFileRow({required this.file});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: file.iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(file.icon, size: 22, color: file.iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: AppTextStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${file.path} • ${file.size}',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Flexible(
            child: Text(
              file.formattedDate,
              style: AppTextStyles.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

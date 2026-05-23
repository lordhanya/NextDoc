import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/typography.dart';
import 'glass_card.dart';

final class PdfThumbnailCard extends StatelessWidget {
  final String heroTag;
  final Uint8List? thumbnailBytes;
  final String fileName;
  final String fileSize;
  final int pageCount;
  final VoidCallback? onTap;

  const PdfThumbnailCard({
    super.key,
    required this.heroTag,
    this.thumbnailBytes,
    required this.fileName,
    required this.fileSize,
    required this.pageCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GlassCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Hero(
                tag: heroTag,
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: _buildThumbnail(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              fileName,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                Text(
                  '$pageCount page${pageCount > 1 ? 's' : ''}',
                  style: AppTextStyles.label,
                ),
                const Spacer(),
                Text(fileSize, style: AppTextStyles.label),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (thumbnailBytes != null) {
      return Image.memory(
        thumbnailBytes!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      );
    }

    return Container(
      color: AppColors.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_rounded,
            size: 36,
            color: AppColors.textHint.withAlpha(100),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'PDF Preview',
            style: AppTextStyles.label,
          ),
        ],
      ),
    );
  }
}

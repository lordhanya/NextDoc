import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../providers/search_provider.dart';
import '../theme/typography.dart';
import 'glass_card.dart';

final class PdfThumbnailCard extends StatelessWidget {
  final String heroTag;
  final Uint8List? thumbnailBytes;
  final String fileName;
  final String fileSize;
  final int pageCount;
  final String query;
  final VoidCallback? onTap;

  const PdfThumbnailCard({
    super.key,
    required this.heroTag,
    this.thumbnailBytes,
    required this.fileName,
    required this.fileSize,
    required this.pageCount,
    this.query = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = DefaultTextStyle.of(context).style;
    final captionStyle = defaultTextStyle.merge(AppTextStyles.caption);
    final captionHighlight = captionStyle.copyWith(
      color: AppColors.primary,
      backgroundColor: AppColors.primary.withAlpha(30),
    );

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
                  child: _buildThumbnail(context),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            RichText(
              text: highlightText(
                fileName,
                query,
                captionStyle,
                captionHighlight,
              ),
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

  Widget _buildThumbnail(BuildContext context) {
    if (thumbnailBytes != null) {
      return Image.memory(
        thumbnailBytes!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      );
    }

    final isLight = Theme.of(context).brightness == Brightness.light;
    final placeholderBg = isLight ? AppColors.lightSurface2 : AppColors.darkSurface2;
    final placeholderIcon = isLight
        ? AppColors.lightTextMuted.withAlpha(100)
        : AppColors.darkTextMuted.withAlpha(100);

    return Container(
      color: placeholderBg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_rounded,
            size: 36,
            color: placeholderIcon,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../providers/pdf_thumbnail_provider.dart';

final class ThumbnailStrip extends ConsumerWidget {
  final String filePath;
  final int totalPages;
  final int currentPage;
  final ValueChanged<int> onPageTap;

  const ThumbnailStrip({
    super.key,
    required this.filePath,
    required this.totalPages,
    required this.currentPage,
    required this.onPageTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface1,
        border: Border(
          top: BorderSide(
            color: isLight
                ? AppColors.lightBorder.withAlpha(60)
                : AppColors.darkBorder.withAlpha(60),
            width: 0.5,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: totalPages,
        itemBuilder: (context, index) {
          final isActive = index == currentPage;
          return GestureDetector(
            onTap: () => onPageTap(index),
            child: Container(
              width: 72,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary
                      : (isLight ? AppColors.lightBorder : AppColors.darkBorder),
                  width: isActive ? 2 : 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm - 1),
                child: _ThumbnailContent(
                  filePath: filePath,
                  pageIndex: index,
                  isActive: isActive,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

final class _ThumbnailContent extends ConsumerWidget {
  final String filePath;
  final int pageIndex;
  final bool isActive;

  const _ThumbnailContent({
    required this.filePath,
    required this.pageIndex,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailAsync = ref.watch(pdfThumbnailProvider((filePath, pageIndex)));

    return thumbnailAsync.when(
      data: (bytes) {
        if (bytes == null) {
          return _PlaceholderThumbnail(pageIndex: pageIndex, isActive: isActive);
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              bytes,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
            ),
            if (isActive)
              Container(color: AppColors.primary.withAlpha(25)),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.black54,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  '${pageIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => _PlaceholderThumbnail(pageIndex: pageIndex, isActive: isActive),
      error: (_, _) => _PlaceholderThumbnail(pageIndex: pageIndex, isActive: isActive),
    );
  }
}

final class _PlaceholderThumbnail extends StatelessWidget {
  final int pageIndex;
  final bool isActive;

  const _PlaceholderThumbnail({
    required this.pageIndex,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      color: isLight
          ? AppColors.lightSurface2
          : AppColors.darkSurface2,
      child: Center(
        child: Text(
          '${pageIndex + 1}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive
                ? AppColors.primary
                : (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted),
          ),
        ),
      ),
    );
  }
}

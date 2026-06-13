import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/typography.dart';

final class PagesPanel extends StatelessWidget {
  final List<Uint8List> pageImages;
  final List<int> pageOrder;
  final int currentPage;
  final ValueChanged<int> onPageSelected;
  final ValueChanged<int> onPageDeleted;
  final ValueChanged<int> onPageDuplicated;
  final void Function(int oldIndex, int newIndex)? onReorder;

  const PagesPanel({
    super.key,
    required this.pageImages,
    required this.pageOrder,
    required this.currentPage,
    required this.onPageSelected,
    required this.onPageDeleted,
    required this.onPageDuplicated,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Pages', style: AppTextStyles.titleSmall),
              const Spacer(),
              Text(
                '${pageOrder.length} page${pageOrder.length == 1 ? '' : 's'}',
                style: AppTextStyles.caption.copyWith(
                  color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ReorderableListView(
              scrollDirection: Axis.horizontal,
              onReorderItem: (oldIndex, newIndex) {
                if (oldIndex == newIndex) return;
                onReorder?.call(oldIndex, newIndex);
              },
              buildDefaultDragHandles: true,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final scale = 1.0 + 0.05 * animation.value;
                    return Transform.scale(
                      scale: scale,
                      child: Material(
                        color: Colors.transparent,
                        child: child,
                      ),
                    );
                  },
                  child: child,
                );
              },
              children: [
                for (int index = 0; index < pageOrder.length; index++)
                  Padding(
                    key: ValueKey('page_${pageOrder[index]}_$index'),
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _PageThumbnail(
                      index: index,
                      pageIdx: pageOrder[index],
                      isCurrent: pageOrder[index] == currentPage,
                      bytes: pageOrder[index] < pageImages.length
                          ? pageImages[pageOrder[index]]
                          : null,
                      onTap: () => onPageSelected(pageOrder[index]),
                      onDelete: () => onPageDeleted(pageOrder[index]),
                      onDuplicate: () => onPageDuplicated(pageOrder[index]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _PageThumbnail extends StatelessWidget {
  final int index;
  final int pageIdx;
  final bool isCurrent;
  final Uint8List? bytes;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _PageThumbnail({
    required this.index,
    required this.pageIdx,
    required this.isCurrent,
    required this.bytes,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isCurrent
                ? AppColors.iconEditorStudio
                : (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(40),
            width: isCurrent ? 2 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md - 1),
                ),
                child: bytes != null
                    ? Image.memory(bytes!, fit: BoxFit.cover)
                    : Container(
                        color: isLight ? AppColors.lightSurface2 : AppColors.darkSurface3,
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: (isLight ? AppColors.lightSurface2 : AppColors.darkSurface3).withAlpha(180),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.md - 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    '${pageIdx + 1}',
                    style: AppTextStyles.caption.copyWith(
                      color: isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary,
                    ),
                  ),
                  InkWell(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.error),
                  ),
                  InkWell(
                    onTap: onDuplicate,
                    child: Icon(Icons.copy_rounded, size: 14,
                        color: AppColors.iconEditorStudio),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

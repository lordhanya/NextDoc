import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../constants/design_tokens.dart';
import '../providers/search_provider.dart';
import '../theme/typography.dart';

final class CustomSearchBar extends ConsumerStatefulWidget {
  final String hintText;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search documents...',
  });

  @override
  ConsumerState<CustomSearchBar> createState() => _CustomSearchBarState();
}

final class _CustomSearchBarState extends ConsumerState<CustomSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _hasFocus = _focusNode.hasFocus);
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).state = value;
      }
    });
  }

  void _clear() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final bgColor = isLight ? AppColors.lightSurface3 : AppColors.darkSurface2;
    final border = isLight ? AppColors.lightBorder : AppColors.darkBorder;
    final iconColor = isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: _hasFocus
              ? AppColors.primary.withAlpha(100)
              : border.withAlpha(80),
          width: _hasFocus ? 1.5 : 0.5,
        ),
        boxShadow: _hasFocus ? DesignTokens.shadowSm : null,
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onChanged,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppTextStyles.bodySmall,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: iconColor,
            ),
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: _clear,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: iconColor,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 2,
          ),
          fillColor: Colors.transparent,
          filled: true,
        ),
      ),
    );
  }
}

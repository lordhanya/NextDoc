import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/recent_files_provider.dart';
import '../../../core/services/file_picker_service.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/shimmer_loading.dart';

final class PdfProtectionScreen extends ConsumerStatefulWidget {
  const PdfProtectionScreen({super.key});

  @override
  ConsumerState<PdfProtectionScreen> createState() => _PdfProtectionScreenState();
}

final class _PdfProtectionScreenState extends ConsumerState<PdfProtectionScreen> {
  final _filePicker = FilePickerService();
  String? _filePath;
  String? _fileName;
  int? _fileSize;
  int? _pageCount;
  bool _isProtectMode = true;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _unlockPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _obscureUnlock = true;
  bool _passwordValid = false;
  String? _passwordError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _unlockPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final file = await _filePicker.pickPdf();
    if (!mounted) return;
    if (file == null) return;

    setState(() {
      _filePath = file.filePath;
      _fileName = file.fileName;
      _fileSize = file.fileSize;
      _pageCount = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _unlockPasswordController.clear();
      _passwordValid = false;
      _passwordError = null;
    });

    final metadata = await ref.read(pdfMetadataProvider(file.filePath).future);
    if (!mounted) return;
    if (metadata != null) {
      setState(() => _pageCount = metadata.pageCount);
    }
  }

  void _validatePassword(String value) {
    final confirm = _confirmPasswordController.text;
    setState(() {
      if (value.length < 4) {
        _passwordValid = false;
        _passwordError = 'At least 4 characters';
      } else if (value != confirm && confirm.isNotEmpty) {
        _passwordValid = false;
        _passwordError = 'Passwords do not match';
      } else {
        _passwordValid = value.length >= 4 && value == confirm;
        _passwordError = _passwordValid ? null : 'At least 4 characters';
      }
    });
  }

  void _validateConfirm(String value) {
    final password = _passwordController.text;
    setState(() {
      if (password.length < 4) {
        _passwordValid = false;
        _passwordError = 'At least 4 characters';
      } else if (value != password) {
        _passwordValid = false;
        _passwordError = 'Passwords do not match';
      } else {
        _passwordValid = true;
        _passwordError = null;
      }
    });
  }

  PasswordStrength _passwordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    if (password.length < 6) return PasswordStrength.weak;
    if (password.length < 10) return PasswordStrength.medium;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[^A-Za-z0-9]'));
    if (hasUpper && hasDigit && hasSpecial) return PasswordStrength.strong;
    if ((hasUpper || hasDigit) && password.length >= 8) return PasswordStrength.medium;
    return PasswordStrength.medium;
  }

  void _startExport() {
    if (_filePath == null || _filePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a PDF file')),
      );
      return;
    }

    if (_isProtectMode) {
      final password = _passwordController.text;
      if (password.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 4 characters')),
        );
        return;
      }
      if (password != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      context.push('/processing', extra: {
        'type': 'protect',
        'path': _filePath,
        'fileName': _fileName,
        'fileSize': _fileSize,
        'pageCount': _pageCount,
        'password': password,
      });
    } else {
      final password = _unlockPasswordController.text;
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter the current password')),
        );
        return;
      }

      context.push('/processing', extra: {
        'type': 'unlock',
        'path': _filePath,
        'fileName': _fileName,
        'fileSize': _fileSize,
        'pageCount': _pageCount,
        'password': password,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = AppColors.iconProtection;

    return Scaffold(
      backgroundColor: isLight ? AppColors.lightBackground : AppColors.darkBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('PDF Protection', style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFileSection(isLight, accent),
                    if (_filePath != null) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      _buildModeSwitch(isLight, accent),
                      const SizedBox(height: AppSpacing.xxl),
                      _isProtectMode
                          ? _buildProtectForm(isLight, accent)
                          : _buildUnlockForm(isLight, accent),
                    ],
                  ],
                ),
              ),
            ),
            if (_filePath != null)
              _buildBottomBar(isLight, accent),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSection(bool isLight, Color accent) {
    if (_filePath == null) {
      return _buildEmptyPicker(isLight, accent);
    }
    return _buildFileInfo(isLight, accent);
  }

  Widget _buildEmptyPicker(bool isLight, Color accent) {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxxl + AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(100),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: accent.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.shield,
                size: 32,
                color: accent,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Select PDF File', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose a PDF to add or remove password protection',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: _pickFile,
              icon: const Icon(LucideIcons.file_up, size: 18),
              label: const Text('Select PDF File'),
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.md,
                ),
                side: BorderSide(color: accent.withAlpha(60)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfo(bool isLight, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Selected File', style: AppTextStyles.titleSmall),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickFile,
              icon: const Icon(LucideIcons.refresh_cw, size: 16),
              label: const Text('Change'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(60),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent.withAlpha(15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  LucideIcons.file_text,
                  size: 24,
                  color: accent.withAlpha(200),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName ?? '',
                      style: AppTextStyles.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${_formattedSize(_fileSize)}  ·  ', style: AppTextStyles.caption),
                        if (_pageCount != null)
                          Text('$_pageCount page${_pageCount! > 1 ? "s" : ""}', style: AppTextStyles.caption)
                        else
                          const ShimmerText(width: 68, height: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeSwitch(bool isLight, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mode', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          decoration: BoxDecoration(
            color: isLight ? AppColors.lightSurface2 : AppColors.darkSurface3,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isProtectMode = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: _isProtectMode ? accent.withAlpha(20) : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.lock,
                          size: 16,
                          color: _isProtectMode
                              ? accent
                              : (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Protect',
                          style: AppTextStyles.caption.copyWith(
                            color: _isProtectMode
                                ? accent
                                : (isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary),
                            fontWeight: _isProtectMode ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isProtectMode = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: !_isProtectMode ? accent.withAlpha(20) : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Icon(
                            LucideIcons.lock_open,
                          size: 16,
                          color: !_isProtectMode
                              ? accent
                              : (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Unlock',
                          style: AppTextStyles.caption.copyWith(
                            color: !_isProtectMode
                                ? accent
                                : (isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary),
                            fontWeight: !_isProtectMode ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProtectForm(bool isLight, Color accent) {
    final strength = _passwordStrength(_passwordController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Set Password', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Choose a strong password to protect this PDF',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildPasswordField(
          controller: _passwordController,
          obscure: _obscurePassword,
          toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
          hint: 'Enter password',
          isLight: isLight,
          accent: accent,
          onChanged: _validatePassword,
        ),
        if (_passwordController.text.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildStrengthIndicator(strength),
        ],
        const SizedBox(height: AppSpacing.md),
        _buildPasswordField(
          controller: _confirmPasswordController,
          obscure: _obscureConfirm,
          toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
          hint: 'Confirm password',
          isLight: isLight,
          accent: accent,
          onChanged: _validateConfirm,
        ),
        if (_passwordError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Row(
              children: [
                Icon(LucideIcons.triangle_alert, size: 14, color: errorColor(strength)),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _passwordError!,
                  style: AppTextStyles.caption.copyWith(
                    color: errorColor(strength),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggleObscure,
    required String hint,
    required bool isLight,
    required Color accent,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(80),
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onChanged: onChanged,
        style: AppTextStyles.body.copyWith(
          color: isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body.copyWith(
            color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md + 2,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? LucideIcons.eye_off : LucideIcons.eye,
              size: 18,
              color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
            ),
            onPressed: toggleObscure,
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator(PasswordStrength strength) {
    final labels = switch (strength) {
      PasswordStrength.none => '',
      PasswordStrength.weak => 'Weak',
      PasswordStrength.medium => 'Medium',
      PasswordStrength.strong => 'Strong',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: switch (strength) {
                    PasswordStrength.none => 0,
                    PasswordStrength.weak => 0.33,
                    PasswordStrength.medium => 0.66,
                    PasswordStrength.strong => 1.0,
                  },
                  backgroundColor: AppColors.darkBorder.withAlpha(60),
                  valueColor: AlwaysStoppedAnimation(switch (strength) {
                    PasswordStrength.none => Colors.transparent,
                    PasswordStrength.weak => AppColors.error,
                    PasswordStrength.medium => AppColors.warning,
                    PasswordStrength.strong => AppColors.success,
                  }),
                  minHeight: 3,
                ),
              ),
            ),
            if (strength != PasswordStrength.none) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                labels,
                style: AppTextStyles.caption.copyWith(
                  color: switch (strength) {
                    PasswordStrength.none => AppColors.darkTextMuted,
                    PasswordStrength.weak => AppColors.error,
                    PasswordStrength.medium => AppColors.warning,
                    PasswordStrength.strong => AppColors.success,
                  },
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildUnlockForm(bool isLight, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Current Password', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Enter the password to remove protection from this PDF',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          decoration: BoxDecoration(
            color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface2,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(80),
              width: 0.5,
            ),
          ),
          child: TextField(
            controller: _unlockPasswordController,
            obscureText: _obscureUnlock,
            style: AppTextStyles.body.copyWith(
              color: isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Enter current password',
              hintStyle: AppTextStyles.body.copyWith(
                color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md + 2,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureUnlock ? LucideIcons.eye_off : LucideIcons.eye,
                  size: 18,
                  color: isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted,
                ),
                onPressed: () => setState(() => _obscureUnlock = !_obscureUnlock),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isLight, Color accent) {
    bool enabled;
    if (_isProtectMode) {
      enabled = _filePath != null && _passwordValid;
    } else {
      enabled = _filePath != null && _unlockPasswordController.text.isNotEmpty;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: isLight ? AppColors.lightSurface1 : AppColors.darkSurface1,
        border: Border(
          top: BorderSide(
            color: (isLight ? AppColors.lightBorder : AppColors.darkBorder).withAlpha(60),
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: _PrimaryButton(
          label: _isProtectMode ? 'Protect PDF' : 'Unlock PDF',
          isEnabled: enabled,
          accent: accent,
          onTap: _startExport,
        ),
      ),
    );
  }

  String _formattedSize(int? bytes) {
    if (bytes == null) return '--';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

enum PasswordStrength { none, weak, medium, strong }

Color errorColor(PasswordStrength strength) {
  return switch (strength) {
    PasswordStrength.none => AppColors.error,
    PasswordStrength.weak => AppColors.error,
    PasswordStrength.medium => AppColors.warning,
    PasswordStrength.strong => AppColors.success,
  };
}

final class _PrimaryButton extends StatefulWidget {
  final String label;
  final bool isEnabled;
  final Color accent;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.isEnabled,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

final class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final effectiveColor =
        widget.isEnabled ? widget.accent : (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(60);

    return GestureDetector(
      onTapDown: widget.isEnabled
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap.call();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 4),
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTextStyles.button.copyWith(
                color: widget.isEnabled
                    ? AppColors.onPrimary
                    : (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(120),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/file_picker_service.dart';
import '../../../core/widgets/tool_screen_layout.dart';

final class MergePdfScreen extends ConsumerWidget {
  const MergePdfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filePicker = FilePickerService();

    return ToolScreenLayout(
      title: 'Merge PDF',
      dropIcon: LucideIcons.filePlus,
      dropTitle: 'Tap to select PDF files',
      dropSubtitle: 'Select multiple PDF files to merge them into one',
      onUpload: () async {
        final files = await filePicker.pickMultiplePdf();
        if (files.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No files selected')),
            );
          }
          return;
        }

        if (context.mounted) {
          context.push('/processing', extra: files.first);
        }
      },
    );
  }
}

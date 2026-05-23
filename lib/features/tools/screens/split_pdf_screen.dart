import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/file_picker_service.dart';
import '../../../core/widgets/tool_screen_layout.dart';

final class SplitPdfScreen extends ConsumerWidget {
  const SplitPdfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filePicker = FilePickerService();

    return ToolScreenLayout(
      title: 'Split PDF',
      dropIcon: LucideIcons.scissors,
      dropTitle: 'Tap to select a PDF file',
      dropSubtitle: 'Split a PDF into multiple separate files',
      onUpload: () async {
        final file = await filePicker.pickPdf();
        if (file == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No file selected')),
            );
          }
          return;
        }

        if (context.mounted) {
          context.push('/processing', extra: file);
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/widgets/tool_screen_layout.dart';
import '../models/tool_result_data.dart';

final class SplitPdfScreen extends StatelessWidget {
  const SplitPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScreenLayout(
      title: 'Split PDF',
      dropIcon: LucideIcons.scissors,
      dropTitle: 'Tap to select a PDF file',
      dropSubtitle: 'Split a PDF into multiple separate files',
      onUpload: () {
        context.push('/processing', extra: const ToolResultData(
          fileName: 'document_1.pdf',
          toolName: 'Split PDF',
        ));
      },
    );
  }
}

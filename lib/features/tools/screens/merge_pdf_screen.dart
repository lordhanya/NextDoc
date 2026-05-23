import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/widgets/tool_screen_layout.dart';
import '../models/tool_result_data.dart';

final class MergePdfScreen extends StatelessWidget {
  const MergePdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScreenLayout(
      title: 'Merge PDF',
      dropIcon: LucideIcons.filePlus,
      dropTitle: 'Tap to select PDF files',
      dropSubtitle: 'Select multiple PDF files to merge them into one',
      onUpload: () {
        context.push('/processing', extra: const ToolResultData(
          fileName: 'document_1.pdf',
          toolName: 'Merge PDF',
        ));
      },
    );
  }
}

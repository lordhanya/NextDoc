import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/widgets/tool_screen_layout.dart';
import '../models/tool_result_data.dart';

final class CompressPdfScreen extends StatelessWidget {
  const CompressPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScreenLayout(
      title: 'Compress PDF',
      dropIcon: LucideIcons.minimize,
      dropTitle: 'Tap to select a PDF file',
      dropSubtitle: 'Reduce file size while preserving quality',
      onUpload: () {
        context.push('/processing', extra: const ToolResultData(
          fileName: 'document_1.pdf',
          toolName: 'Compress PDF',
        ));
      },
    );
  }
}

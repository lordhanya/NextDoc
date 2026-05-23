import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/widgets/tool_screen_layout.dart';
import '../models/tool_result_data.dart';

final class ImageToPdfScreen extends StatelessWidget {
  const ImageToPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScreenLayout(
      title: 'JPG to PDF',
      dropIcon: LucideIcons.image,
      dropTitle: 'Tap to select images',
      dropSubtitle: 'Convert JPG, PNG images to PDF format',
      onUpload: () {
        context.push('/processing', extra: const ToolResultData(
          fileName: 'photo_2026.jpg',
          toolName: 'JPG to PDF',
        ));
      },
    );
  }
}

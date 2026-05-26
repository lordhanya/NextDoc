import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

enum FileActionResult { success, fileNotFound, noAppToOpen, error }

final class FileActionService {
  FileActionService._();

  static Future<FileActionResult> openPdf(
    BuildContext context,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File not found')),
          );
        }
        return FileActionResult.fileNotFound;
      }

      final result = await OpenFilex.open(filePath);
      if (!context.mounted) return FileActionResult.success;

      if (result.type == ResultType.noAppToOpen) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No PDF viewer installed')),
        );
        return FileActionResult.noAppToOpen;
      }
      if (result.type == ResultType.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open: ${result.message}')),
        );
        return FileActionResult.error;
      }
      return FileActionResult.success;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open: $e')),
        );
      }
      return FileActionResult.error;
    }
  }

  static Future<FileActionResult> sharePdf(
    BuildContext context,
    String filePath,
    String fileName,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File not found')),
          );
        }
        return FileActionResult.fileNotFound;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: fileName,
        ),
      );
      return FileActionResult.success;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
      return FileActionResult.error;
    }
  }
}

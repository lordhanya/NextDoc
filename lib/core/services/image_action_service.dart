import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'file_action_service.dart';

final class ImageActionService {
  ImageActionService._();

  static Future<FileActionResult> openImage(
    BuildContext context,
    String path,
    List<String> imagePaths,
  ) async {
    try {
      final target = imagePaths.isNotEmpty ? imagePaths.first : path;
      final file = File(target);
      if (!await file.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image file not found')),
          );
        }
        return FileActionResult.fileNotFound;
      }

      final result = await OpenFilex.open(target);
      if (!context.mounted) return FileActionResult.success;

      if (result.type == ResultType.noAppToOpen) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image viewer available')),
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

  static Future<FileActionResult> shareImages(
    BuildContext context,
    List<String> imagePaths,
  ) async {
    try {
      if (imagePaths.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No images to share')),
          );
        }
        return FileActionResult.error;
      }

      final files = imagePaths
          .map((p) => XFile(p, mimeType: 'image/jpeg'))
          .toList();

      await SharePlus.instance.share(
        ShareParams(
          files: files,
          text: '${imagePaths.length} image${imagePaths.length > 1 ? "s" : ""}',
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

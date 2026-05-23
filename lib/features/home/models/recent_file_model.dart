import 'package:flutter/material.dart';

final class RecentFile {
  final String name;
  final String path;
  final String size;
  final DateTime modifiedAt;
  final IconData icon;
  final Color iconColor;

  const RecentFile({
    required this.name,
    required this.path,
    required this.size,
    required this.modifiedAt,
    required this.icon,
    required this.iconColor,
  });

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(modifiedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${modifiedAt.month}/${modifiedAt.day}/${modifiedAt.year}';
  }
}

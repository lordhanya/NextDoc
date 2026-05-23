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

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${modifiedAt.month}/${modifiedAt.day}/${modifiedAt.year}';
  }
}

final List<RecentFile> fakeRecentFiles = [
  RecentFile(
    name: 'Project_Proposal.pdf',
    path: '/Documents/Work',
    size: '2.4 MB',
    modifiedAt: DateTime.now().subtract(const Duration(minutes: 15)),
    icon: Icons.picture_as_pdf_rounded,
    iconColor: const Color(0xFFEF5350),
  ),
  RecentFile(
    name: 'Meeting_Notes.pdf',
    path: '/Documents/Work',
    size: '856 KB',
    modifiedAt: DateTime.now().subtract(const Duration(hours: 2)),
    icon: Icons.description_rounded,
    iconColor: const Color(0xFF42A5F5),
  ),
  RecentFile(
    name: 'Invoice_2026_05.pdf',
    path: '/Documents/Finance',
    size: '1.2 MB',
    modifiedAt: DateTime.now().subtract(const Duration(days: 1)),
    icon: Icons.receipt_rounded,
    iconColor: const Color(0xFF66BB6A),
  ),
  RecentFile(
    name: 'Contract_Draft.pdf',
    path: '/Documents/Legal',
    size: '3.1 MB',
    modifiedAt: DateTime.now().subtract(const Duration(days: 3)),
    icon: Icons.article_rounded,
    iconColor: const Color(0xFFFFA726),
  ),
];

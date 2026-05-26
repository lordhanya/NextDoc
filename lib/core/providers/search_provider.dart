import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/recent_file_entity.dart';
import 'recent_files_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredRecentFilesProvider = FutureProvider<List<RecentFileEntity>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final files = await ref.watch(recentFilesProvider.future);

  if (query.isEmpty) return files;

  return files
      .where((f) => f.fileName.toLowerCase().contains(query))
      .toList();
});

TextSpan highlightText(String text, String query, TextStyle baseStyle, TextStyle highlightStyle) {
  if (query.isEmpty) {
    return TextSpan(text: text, style: baseStyle);
  }

  final lower = text.toLowerCase();
  final q = query.toLowerCase();
  final spans = <TextSpan>[];
  var start = 0;

  while (true) {
    final idx = lower.indexOf(q, start);
    if (idx == -1) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
      break;
    }
    if (idx > start) {
      spans.add(TextSpan(text: text.substring(start, idx), style: baseStyle));
    }
    spans.add(TextSpan(text: text.substring(idx, idx + q.length), style: highlightStyle));
    start = idx + q.length;
  }

  return TextSpan(children: spans);
}

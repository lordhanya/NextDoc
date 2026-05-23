import 'dart:async';

final class FakeProcessingService {
  Stream<double> process(String fileName) async* {
    final steps = 100;
    for (var i = 0; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 40));
      yield i / steps;
    }
  }
}

final class ProcessingResult {
  final String fileName;
  final String originalSize;
  final String newSize;
  final String toolName;

  const ProcessingResult({
    required this.fileName,
    required this.originalSize,
    required this.newSize,
    required this.toolName,
  });
}

ProcessingResult generateFakeResult({
  required String fileName,
  required String toolName,
}) {
  final sizes = ['1.2 MB', '2.4 MB', '3.1 MB', '856 KB', '4.5 MB'];
  final reduced = ['468 KB', '892 KB', '1.1 MB', '340 KB', '1.8 MB'];
  final index = DateTime.now().millisecondsSinceEpoch % sizes.length;

  return ProcessingResult(
    fileName: fileName,
    originalSize: sizes[index],
    newSize: reduced[index],
    toolName: toolName,
  );
}

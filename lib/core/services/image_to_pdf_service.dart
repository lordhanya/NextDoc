import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'metadata_service.dart';

final class PdfConversionResult {
  final String filePath;
  final String fileName;
  final int fileSize;
  final int pageCount;

  const PdfConversionResult({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.pageCount,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

final class ImageToPdfService {
  Future<PdfConversionResult> convert({
    required List<String> imagePaths,
    required String outputPath,
    required void Function(double progress) onProgress,
  }) async {
    final port = ReceivePort();
    await Isolate.spawn(
      _runConversion,
      _IsolateArgs(
        imagePaths: imagePaths,
        outputPath: outputPath,
        sendPort: port.sendPort,
      ),
    );

    await for (final message in port) {
      if (message is double) {
        onProgress(message);
      } else if (message is String && message == 'done') {
        break;
      } else if (message is String && message.startsWith('error:')) {
        throw Exception(message.substring(6));
      } else if (message is _IsolateResult) {
        onProgress(1.0);
        final result = message;
        return PdfConversionResult(
          filePath: result.filePath,
          fileName: p.basename(result.filePath),
          fileSize: result.fileSize,
          pageCount: result.pageCount,
        );
      }
    }

    final file = File(outputPath);
    return PdfConversionResult(
      filePath: outputPath,
      fileName: p.basename(outputPath),
      fileSize: await file.length(),
      pageCount: imagePaths.length,
    );
  }
}

final class _IsolateArgs {
  final List<String> imagePaths;
  final String outputPath;
  final SendPort sendPort;

  const _IsolateArgs({
    required this.imagePaths,
    required this.outputPath,
    required this.sendPort,
  });
}

final class _IsolateResult {
  final String filePath;
  final int fileSize;
  final int pageCount;

  const _IsolateResult({
    required this.filePath,
    required this.fileSize,
    required this.pageCount,
  });
}

void _runConversion(_IsolateArgs args) async {
  final paths = args.imagePaths;
  final outPath = args.outputPath;
  final sendPort = args.sendPort;

  try {
    final pdf = MetadataService.createPdfDocument(
        title: 'Image to PDF',
        subject: 'Converted from ${paths.length} image(s)',
        keywords: 'NextDoc, Image to PDF',
      );

    for (var i = 0; i < paths.length; i++) {
      final bytes = await File(paths[i]).readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) {
        sendPort.send('error:Failed to decode image ${paths[i]}');
        return;
      }

      final resized = _resizeImage(original);
      final jpegBytes = img.encodeJpg(resized, quality: 85);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            resized.width.toDouble(),
            resized.height.toDouble(),
          ),
          margin: const pw.EdgeInsets.all(0),
          build: (context) => pw.Center(
            child: pw.Image(pw.MemoryImage(jpegBytes)),
          ),
        ),
      );

      sendPort.send((i + 1) / paths.length);
    }

    final outFile = File(outPath);
    await outFile.writeAsBytes(await pdf.save());

    sendPort.send(_IsolateResult(
      filePath: outPath,
      fileSize: await outFile.length(),
      pageCount: paths.length,
    ));
  } catch (e) {
    sendPort.send('error:${e.toString()}');
  }
}

img.Image _resizeImage(img.Image image) {
  const maxDim = 2000;
  var w = image.width;
  var h = image.height;

  if (w <= maxDim && h <= maxDim) return image;

  final ratio = maxDim / (w > h ? w : h);
  w = (w * ratio).round();
  h = (h * ratio).round();

  return img.copyResize(image, width: w, height: h);
}

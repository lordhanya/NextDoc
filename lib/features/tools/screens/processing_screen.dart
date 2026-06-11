import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/isar_service.dart';
import '../../../core/database/recent_file_entity.dart';
import '../../../core/models/selected_file_model.dart';
import '../../../core/providers/recent_files_provider.dart';
import '../../../core/services/compress_pdf_service.dart';
import '../../../core/services/image_to_pdf_service.dart';
import '../../../core/services/merge_pdf_service.dart';
import '../../../core/services/split_pdf_service.dart';
import '../../../core/services/pdf_to_image_service.dart';
import '../../../core/services/pdf_protection_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/task_service.dart';
import '../../../core/theme/typography.dart';

final class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

final class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  final _taskService = TaskService();
  final _imageToPdfService = ImageToPdfService();
  final _mergeService = MergePdfService();
  final _compressService = CompressPdfService();
  final _splitService = SplitPdfService();
  final _pdfToImageService = PdfToImageService();
  final _pdfProtectionService = PdfProtectionService();
  StreamSubscription<TaskProgress>? _taskSubscription;
  StreamSubscription<double>? _realSubscription;
  TaskProgress _taskProgress = const TaskProgress();
  String _fileName = 'document.pdf';
  SelectedFileModel? _fileData;
  bool _dataExtracted = false;
  bool _isImageToPdf = false;
  bool _isMerge = false;
  bool _isCompress = false;
  bool _isSplit = false;
  bool _isPdfToImage = false;
  bool _isProtect = false;
  bool _isUnlock = false;
  String? _protectInputPath;
  String? _protectPassword;
  List<String> _imagePaths = [];
  List<String> _mergePaths = [];
  String? _compressPath;
  CompressionLevel _compressionLevel = CompressionLevel.medium;
  int _originalSize = 0;
  int? _pageCount;
  String? _splitPath;
  List<int> _selectedPages = [];
  SplitMode _splitMode = SplitMode.extract;
  String? _pdfToImagePath;
  List<int> _pdfToImageSelectedPages = [];
  ExportQuality _pdfToImageQuality = ExportQuality.standard;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataExtracted) {
      _dataExtracted = true;
      _extractData();
      _startProcessing();
    }
  }

  void _extractData() {
    final extra = GoRouterState.of(context).extra;
    if (extra is Map) {
      final type = extra['type'] as String?;
      if (type == 'image_to_pdf') {
        _isImageToPdf = true;
        _imagePaths = List<String>.from(extra['imagePaths'] as List);
        _fileName = extra['fileName'] as String? ?? 'NextDoc_output.pdf';
        return;
      }
      if (type == 'merge') {
        _isMerge = true;
        _mergePaths = List<String>.from(extra['paths'] as List);
        _fileName = extra['fileName'] as String? ?? 'Merged.pdf';
        return;
      }
      if (type == 'compress') {
        _isCompress = true;
        _compressPath = extra['path'] as String?;
        _fileName = extra['fileName'] as String? ?? 'Compressed.pdf';
        _originalSize = extra['originalSize'] as int? ?? 0;
        _pageCount = extra['pageCount'] as int?;
        final levelName = extra['compressionLevel'] as String? ?? 'medium';
        _compressionLevel = CompressionLevel.values.firstWhere(
          (e) => e.name == levelName,
          orElse: () => CompressionLevel.medium,
        );
        return;
      }
      if (type == 'split') {
        _isSplit = true;
        _splitPath = extra['path'] as String?;
        _fileName = extra['fileName'] as String? ?? 'document.pdf';
        _selectedPages = List<int>.from(extra['selectedPages'] as List);
        final modeName = extra['splitMode'] as String? ?? 'extract';
        _splitMode = SplitMode.values.firstWhere(
          (e) => e.name == modeName,
          orElse: () => SplitMode.extract,
        );
        return;
      }
      if (type == 'protect') {
        _isProtect = true;
        _protectInputPath = extra['path'] as String?;
        _fileName = extra['fileName'] as String? ?? 'document.pdf';
        _protectPassword = extra['password'] as String?;
        _originalSize = extra['fileSize'] as int? ?? 0;
        _pageCount = extra['pageCount'] as int?;
        return;
      }
      if (type == 'unlock') {
        _isUnlock = true;
        _protectInputPath = extra['path'] as String?;
        _fileName = extra['fileName'] as String? ?? 'document.pdf';
        _protectPassword = extra['password'] as String?;
        _originalSize = extra['fileSize'] as int? ?? 0;
        _pageCount = extra['pageCount'] as int?;
        return;
      }
      if (type == 'pdf_to_image') {
        _isPdfToImage = true;
        _pdfToImagePath = extra['filePath'] as String?;
        _fileName = extra['fileName'] as String? ?? 'document.pdf';
        _pdfToImageSelectedPages = List<int>.from(extra['selectedPages'] as List);
        final qualityName = extra['exportQuality'] as String? ?? 'standard';
        _pdfToImageQuality = ExportQuality.values.firstWhere(
          (e) => e.name == qualityName,
          orElse: () => ExportQuality.standard,
        );
        return;
      }
    }
    if (extra is SelectedFileModel) {
      _fileData = extra;
      _fileName = extra.fileName;
    }
  }

  Future<void> _startProcessing() async {
    if (_isImageToPdf && _imagePaths.isNotEmpty) {
      _startRealConversion();
    } else if (_isMerge && _mergePaths.isNotEmpty) {
      _startRealMerge();
    } else if (_isCompress && _compressPath != null) {
      _startRealCompress();
    } else if (_isSplit && _splitPath != null) {
      _startRealSplit();
    } else if (_isPdfToImage && _pdfToImagePath != null) {
      _startRealPdfToImage();
    } else if (_isProtect && _protectInputPath != null) {
      _startRealProtect();
    } else if (_isUnlock && _protectInputPath != null) {
      _startRealUnlock();
    } else {
      _startFakeTask();
    }
  }

  Future<void> _startRealConversion() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputDir = '${dir.path}/NextDoc/Image_to_PDF/$timestamp';
      await Directory(outputDir).create(recursive: true);
      final outputPath = '$outputDir/$_fileName';

      await _imageToPdfService.convert(
        imagePaths: _imagePaths,
        outputPath: outputPath,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _taskProgress = TaskProgress(
              progress: progress,
              statusText: _realStatusText(progress),
              status: TaskStatus.running,
            );
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _taskProgress = const TaskProgress(
          progress: 1.0,
          statusText: 'Complete',
          status: TaskStatus.completed,
        );
      });
      await _onRealComplete(outputPath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _taskProgress = TaskProgress(
          progress: 0,
          statusText: 'Failed: ${e.toString()}',
          status: TaskStatus.failed,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversion failed: ${e.toString()}')),
      );
    }
  }

  String _realStatusText(double progress) {
    if (progress < 0.2) return 'Reading images...';
    if (progress < 0.5) return 'Processing images...';
    if (progress < 0.8) return 'Generating PDF...';
    if (progress < 1.0) return 'Finalizing...';
    return 'Complete!';
  }

  Future<void> _onRealComplete(String outputPath) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final file = File(outputPath);
    final fileSize = await file.length();

    final isarService = IsarService.instance;
    await isarService.saveRecentFile(RecentFileEntity(
      fileName: _fileName,
      filePath: outputPath,
      fileSize: fileSize,
      fileType: 'pdf',
      createdAt: DateTime.now(),
      pageCount: _imagePaths.length,
    ));

    if (!mounted) return;
    refreshRecentFiles(ref);
    if (!mounted) return;

    context.pushReplacement('/success', extra: {
      'type': 'image_to_pdf',
      'filePath': outputPath,
      'fileName': _fileName,
      'fileSize': fileSize,
      'pageCount': _imagePaths.length,
      'saveFolder': 'NextDoc/Image_to_PDF/',
    });
  }

  Future<void> _startRealMerge() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputDir = '${dir.path}/NextDoc/Merge_PDF/$timestamp';
      await Directory(outputDir).create(recursive: true);
      final outputPath = '$outputDir/$_fileName';

      await _mergeService.mergePdfs(
        inputPaths: _mergePaths,
        outputPath: outputPath,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _taskProgress = TaskProgress(
              progress: progress,
              statusText: _mergeStatusText(progress),
              status: TaskStatus.running,
            );
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _taskProgress = const TaskProgress(
          progress: 1.0,
          statusText: 'Complete',
          status: TaskStatus.completed,
        );
      });
      await _onMergeComplete(outputPath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _taskProgress = TaskProgress(
          progress: 0,
          statusText: 'Failed: ${e.toString()}',
          status: TaskStatus.failed,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Merge failed: ${e.toString()}')),
      );
    }
  }

  String _mergeStatusText(double progress) {
    if (progress < 0.2) return 'Reading PDF files...';
    if (progress < 0.5) return 'Merging pages...';
    if (progress < 0.8) return 'Building document...';
    if (progress < 1.0) return 'Saving...';
    return 'Complete!';
  }

  Future<void> _onMergeComplete(String outputPath) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final file = File(outputPath);
    final fileSize = await file.length();
    final pdfService = ref.read(pdfServiceProvider);
    final metadata = await pdfService.getMetadata(outputPath);
    final pageCount = metadata?.pageCount ?? 0;

    final isarService = IsarService.instance;
    await isarService.saveRecentFile(RecentFileEntity(
      fileName: _fileName,
      filePath: outputPath,
      fileSize: fileSize,
      fileType: 'pdf',
      createdAt: DateTime.now(),
      pageCount: pageCount,
    ));

    if (!mounted) return;
    refreshRecentFiles(ref);
    if (!mounted) return;

    context.pushReplacement('/success', extra: {
      'type': 'merge',
      'toolName': 'PDF Merge',
      'filePath': outputPath,
      'fileName': _fileName,
      'fileSize': fileSize,
      'pageCount': pageCount,
      'saveFolder': 'NextDoc/Merge_PDF/',
    });
  }

  Future<void> _startRealCompress() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputDir = '${dir.path}/NextDoc/Compress_PDF/$timestamp';
      await Directory(outputDir).create(recursive: true);
      final outputPath = '$outputDir/$_fileName';

      await _compressService.compressPdf(
        inputPath: _compressPath!,
        outputPath: outputPath,
        level: _compressionLevel,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _taskProgress = TaskProgress(
              progress: progress,
              statusText: _compressStatusText(progress),
              status: TaskStatus.running,
            );
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _taskProgress = const TaskProgress(
          progress: 1.0,
          statusText: 'Complete',
          status: TaskStatus.completed,
        );
      });
      await _onCompressComplete(outputPath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _taskProgress = TaskProgress(
          progress: 0,
          statusText: 'Failed: ${e.toString()}',
          status: TaskStatus.failed,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compression failed: ${e.toString()}')),
      );
    }
  }

  String _compressStatusText(double progress) {
    if (progress < 0.2) return 'Reading PDF...';
    if (progress < 0.5) return 'Rendering pages...';
    if (progress < 0.8) return 'Building compressed PDF...';
    if (progress < 1.0) return 'Saving...';
    return 'Complete!';
  }

  Future<void> _onCompressComplete(String outputPath) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final file = File(outputPath);
    final compressedSize = await file.length();

    final isarService = IsarService.instance;
    await isarService.saveRecentFile(RecentFileEntity(
      fileName: _fileName,
      filePath: outputPath,
      fileSize: compressedSize,
      fileType: 'pdf',
      createdAt: DateTime.now(),
      pageCount: _pageCount ?? 0,
    ));

    if (!mounted) return;
    refreshRecentFiles(ref);
    if (!mounted) return;

    context.pushReplacement('/success', extra: {
      'type': 'compress',
      'toolName': 'PDF Compress',
      'filePath': outputPath,
      'fileName': _fileName,
      'fileSize': compressedSize,
      'pageCount': _pageCount ?? 0,
      'originalSize': _originalSize,
      'saveFolder': 'NextDoc/Compress_PDF/',
    });
  }

  SplitResult? _splitResult;

  Future<void> _startRealSplit() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputDirPath = '${dir.path}/NextDoc/Split_PDF/$timestamp';
      await Directory(outputDirPath).create(recursive: true);

      final result = await _splitService.splitPdf(
        inputPath: _splitPath!,
        outputDir: outputDirPath,
        selectedPageIndices: _selectedPages,
        mode: _splitMode,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _taskProgress = TaskProgress(
              progress: progress,
              statusText: _splitStatusText(progress),
              status: TaskStatus.running,
            );
          });
        },
      );
      _splitResult = result;

      if (!mounted) return;
      setState(() {
        _taskProgress = const TaskProgress(
          progress: 1.0,
          statusText: 'Complete',
          status: TaskStatus.completed,
        );
      });
      await _onSplitComplete();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _taskProgress = TaskProgress(
          progress: 0,
          statusText: 'Failed: ${e.toString()}',
          status: TaskStatus.failed,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Split failed: ${e.toString()}')),
      );
    }
  }

  String _splitStatusText(double progress) {
    if (progress < 0.2) return 'Reading PDF...';
    if (progress < 0.5) return 'Rendering pages...';
    if (progress < 0.8) return 'Building PDF${_splitMode == SplitMode.splitAll ? "s" : ""}...';
    if (progress < 1.0) return 'Saving...';
    return 'Complete!';
  }

  Future<void> _onSplitComplete() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final result = _splitResult;
    final isarService = IsarService.instance;

    if (result != null && result.files.isNotEmpty) {
      for (final file in result.files) {
        await isarService.saveRecentFile(RecentFileEntity(
          fileName: file.fileName,
          filePath: file.filePath,
          fileSize: file.fileSize,
          fileType: 'pdf',
          createdAt: DateTime.now(),
          pageCount: file.pageCount,
        ));
      }
    }

    if (!mounted) return;
    refreshRecentFiles(ref);
    if (!mounted) return;

    final firstFile = result?.files.isNotEmpty == true ? result!.files.first : null;

    context.pushReplacement('/success', extra: {
      'type': 'split',
      'toolName': 'PDF Split',
      'filePath': firstFile?.filePath ?? _splitPath ?? '',
      'fileName': firstFile?.fileName ?? _fileName,
      'fileSize': result?.totalSize ?? 0,
      'fileCount': result?.fileCount ?? 0,
      'pageCount': result?.totalPages ?? _selectedPages.length,
      'saveFolder': 'NextDoc/Split_PDF/',
    });
  }

  Future<void> _startRealPdfToImage() async {
    try {
      final service = _pdfToImageService;
      final result = await service.convert(
        filePath: _pdfToImagePath!,
        selectedPages: _pdfToImageSelectedPages,
        quality: _pdfToImageQuality,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _taskProgress = TaskProgress(
              progress: progress,
              statusText: _pdfToImageStatusText(progress),
              status: TaskStatus.running,
            );
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _taskProgress = const TaskProgress(
          progress: 1.0,
          statusText: 'Complete',
          status: TaskStatus.completed,
        );
      });
      await _onPdfToImageComplete(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _taskProgress = TaskProgress(
          progress: 0,
          statusText: 'Failed: ${e.toString()}',
          status: TaskStatus.failed,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: ${e.toString()}')),
      );
    }
  }

  String _pdfToImageStatusText(double progress) {
    if (progress < 0.2) return 'Reading PDF...';
    if (progress < 0.5) return 'Rendering pages...';
    if (progress < 0.8) return 'Exporting images...';
    if (progress < 1.0) return 'Finalizing...';
    return 'Complete!';
  }

  Future<void> _onPdfToImageComplete(PdfToImageResult result) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final isarService = IsarService.instance;
    await isarService.saveRecentFile(RecentFileEntity(
      fileName: '${_fileName.replaceAll('.pdf', '')}_images',
      filePath: result.imagePaths.isNotEmpty ? result.imagePaths.first : result.outputDir,
      fileSize: result.totalSize,
      fileType: 'image_export',
      createdAt: DateTime.now(),
      pageCount: result.imageCount,
    ));

    if (!mounted) return;
    refreshRecentFiles(ref);
    if (!mounted) return;

    context.pushReplacement('/success', extra: {
      'type': 'pdf_to_image',
      'toolName': 'PDF to JPG',
      'filePath': result.imagePaths.isNotEmpty ? result.imagePaths.first : result.outputDir,
      'fileName': '${_fileName.replaceAll('.pdf', '')}_images',
      'fileSize': result.totalSize,
      'fileCount': result.imageCount,
      'pageCount': result.imageCount,
      'imagePaths': result.imagePaths,
      'saveFolder': 'NextDoc/PDF_to_JPG/',
    });
  }

  Future<void> _startRealProtect() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputDir = '${dir.path}/NextDoc/Protect_PDF/$timestamp';
      await Directory(outputDir).create(recursive: true);
      final outputName = '${_fileName.replaceAll('.pdf', '')}_protected.pdf';
      final outputPath = '$outputDir/$outputName';

      final result = await _pdfProtectionService.protectPdf(
        inputPath: _protectInputPath!,
        outputPath: outputPath,
        password: _protectPassword!,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _taskProgress = TaskProgress(
              progress: progress,
              statusText: _protectStatusText(progress),
              status: TaskStatus.running,
            );
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _taskProgress = const TaskProgress(
          progress: 1.0,
          statusText: 'Complete',
          status: TaskStatus.completed,
        );
      });
      await _onProtectComplete(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _taskProgress = TaskProgress(
          progress: 0,
          statusText: 'Failed: ${e.toString()}',
          status: TaskStatus.failed,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Protection failed: ${e.toString()}')),
      );
    }
  }

  String _protectStatusText(double progress) {
    if (progress < 0.2) return 'Reading PDF...';
    if (progress < 0.4) return 'Applying encryption...';
    if (progress < 0.7) return 'Saving protected PDF...';
    if (progress < 1.0) return 'Finalizing...';
    return 'Complete!';
  }

  Future<void> _onProtectComplete(ProtectionResult result) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final isarService = IsarService.instance;
    await isarService.saveRecentFile(RecentFileEntity(
      fileName: result.fileName,
      filePath: result.filePath,
      fileSize: result.fileSize,
      fileType: 'pdf',
      createdAt: DateTime.now(),
      pageCount: result.pageCount,
    ));

    if (!mounted) return;
    refreshRecentFiles(ref);
    if (!mounted) return;

    context.pushReplacement('/success', extra: {
      'type': 'protect',
      'toolName': 'PDF Protection',
      'filePath': result.filePath,
      'fileName': result.fileName,
      'fileSize': result.fileSize,
      'pageCount': result.pageCount,
      'saveFolder': 'NextDoc/Protect_PDF/',
    });
  }

  Future<void> _startRealUnlock() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputDir = '${dir.path}/NextDoc/Protect_PDF/$timestamp';
      await Directory(outputDir).create(recursive: true);
      final outputName = '${_fileName.replaceAll('.pdf', '')}_unlocked.pdf';
      final outputPath = '$outputDir/$outputName';

      final result = await _pdfProtectionService.unlockPdf(
        inputPath: _protectInputPath!,
        outputPath: outputPath,
        password: _protectPassword!,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _taskProgress = TaskProgress(
              progress: progress,
              statusText: _unlockStatusText(progress),
              status: TaskStatus.running,
            );
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _taskProgress = const TaskProgress(
          progress: 1.0,
          statusText: 'Complete',
          status: TaskStatus.completed,
        );
      });
      await _onUnlockComplete(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _taskProgress = TaskProgress(
          progress: 0,
          statusText: 'Failed: ${e.toString()}',
          status: TaskStatus.failed,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unlock failed: ${e.toString()}')),
      );
    }
  }

  String _unlockStatusText(double progress) {
    if (progress < 0.1) return 'Reading PDF...';
    if (progress < 0.5) return 'Decrypting pages...';
    if (progress < 0.8) return 'Rebuilding document...';
    if (progress < 1.0) return 'Saving...';
    return 'Complete!';
  }

  Future<void> _onUnlockComplete(ProtectionResult result) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final isarService = IsarService.instance;
    await isarService.saveRecentFile(RecentFileEntity(
      fileName: result.fileName,
      filePath: result.filePath,
      fileSize: result.fileSize,
      fileType: 'pdf',
      createdAt: DateTime.now(),
      pageCount: result.pageCount,
    ));

    if (!mounted) return;
    refreshRecentFiles(ref);
    if (!mounted) return;

    context.pushReplacement('/success', extra: {
      'type': 'unlock',
      'toolName': 'PDF Protection',
      'filePath': result.filePath,
      'fileName': result.fileName,
      'fileSize': result.fileSize,
      'pageCount': result.pageCount,
      'saveFolder': 'NextDoc/Protect_PDF/',
    });
  }

  Future<void> _startFakeTask() async {
    _taskSubscription = _taskService.runFakeTask(label: _fileName).listen(
      (progress) {
        if (!mounted) return;
        setState(() => _taskProgress = progress);
        if (progress.status == TaskStatus.completed) {
          _onFakeComplete();
        }
      },
    );
  }

  Future<void> _onFakeComplete() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    int pageCount = 0;
    final filePath = _fileData?.filePath;
    if (filePath != null && filePath.isNotEmpty) {
      final pdfService = ref.read(pdfServiceProvider);
      final metadata = await pdfService.getMetadata(filePath);
      pageCount = metadata?.pageCount ?? 0;
    }

    final isarService = IsarService.instance;
    await isarService.saveRecentFile(RecentFileEntity(
      fileName: _fileName,
      filePath: filePath ?? '',
      fileSize: _fileData?.fileSize ?? 0,
      fileType: _fileData?.fileType ?? 'pdf',
      createdAt: DateTime.now(),
      pageCount: pageCount,
    ));

    if (!mounted) return;
    refreshRecentFiles(ref);
    if (!mounted) return;
    context.pushReplacement('/success');
  }

  @override
  void dispose() {
    _taskService.dispose();
    _taskSubscription?.cancel();
    _realSubscription?.cancel();
    _mergeService.cancel();
    _compressService.cancel();
    _splitService.cancel();
    _pdfToImageService.cancel();
    _pdfProtectionService.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cancelled = _taskProgress.status == TaskStatus.cancelled;
    final failed = _taskProgress.status == TaskStatus.failed;
    final progress = _taskProgress.progress;

    return Scaffold(
      backgroundColor: isLight ? AppColors.lightBackground : AppColors.darkBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularProgress(isLight),
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  failed ? 'Failed' : cancelled ? 'Cancelled' : 'Processing...',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _fileName,
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  failed ? 'Error' : '${(progress * 100).toInt()}%',
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _taskProgress.statusText,
                  style: AppTextStyles.caption,
                ),
                if (!failed && !cancelled && progress > 0 && progress < 1) ...[
                  const SizedBox(height: AppSpacing.xxxl),
                  TextButton.icon(
                    onPressed: () {
                      _taskService.cancel();
                      _mergeService.cancel();
                      _compressService.cancel();
                      _splitService.cancel();
                      _pdfProtectionService.cancel();
                      if (mounted) context.pop();
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Cancel'),
                  ),
                ],
                if (failed) ...[
                  const SizedBox(height: AppSpacing.xxxl),
                  TextButton.icon(
                    onPressed: () {
                      if (mounted) context.pop();
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Go Back'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularProgress(bool isLight) {
    final progress = _taskProgress.progress;
    final cancelled = _taskProgress.status == TaskStatus.cancelled;
    final failed = _taskProgress.status == TaskStatus.failed;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: (cancelled || failed) ? null : progress,
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              backgroundColor: isLight ? AppColors.lightSurface2 : AppColors.darkSurface2,
              valueColor: AlwaysStoppedAnimation(
                failed
                    ? AppColors.error
                    : cancelled
                        ? (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted)
                        : AppColors.primary,
              ),
            ),
          ),
          Icon(
            failed
                ? Icons.error_outline_rounded
                : cancelled
                    ? Icons.close_rounded
                    : Icons.description_rounded,
            size: 40,
            color: failed
                ? AppColors.error.withAlpha(180)
                : cancelled
                    ? (isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted).withAlpha(180)
                    : AppColors.primary.withAlpha(180),
          ),
        ],
      ),
    );
  }
}

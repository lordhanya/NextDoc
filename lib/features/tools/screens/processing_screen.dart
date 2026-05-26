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
import '../../../core/services/image_to_pdf_service.dart';
import '../../../core/services/merge_pdf_service.dart';
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
  StreamSubscription<TaskProgress>? _taskSubscription;
  StreamSubscription<double>? _realSubscription;
  TaskProgress _taskProgress = const TaskProgress();
  String _fileName = 'document.pdf';
  SelectedFileModel? _fileData;
  bool _dataExtracted = false;
  bool _isImageToPdf = false;
  bool _isMerge = false;
  List<String> _imagePaths = [];
  List<String> _mergePaths = [];

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
    } else {
      _startFakeTask();
    }
  }

  Future<void> _startRealConversion() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final outputPath = '${dir.path}/$_fileName';

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
    });
  }

  Future<void> _startRealMerge() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final outputPath = '${dir.path}/$_fileName';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cancelled = _taskProgress.status == TaskStatus.cancelled;
    final failed = _taskProgress.status == TaskStatus.failed;
    final progress = _taskProgress.progress;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularProgress(),
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

  Widget _buildCircularProgress() {
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
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(
                failed
                    ? AppColors.error
                    : cancelled
                        ? AppColors.textHint
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
                    ? AppColors.textHint.withAlpha(180)
                    : AppColors.primary.withAlpha(180),
          ),
        ],
      ),
    );
  }
}

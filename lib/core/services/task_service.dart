import 'dart:async';

enum TaskStatus { idle, running, completed, cancelled, failed }

final class TaskProgress {
  final double progress;
  final String statusText;
  final TaskStatus status;

  const TaskProgress({
    this.progress = 0,
    this.statusText = '',
    this.status = TaskStatus.idle,
  });
}

final class TaskService {
  StreamSubscription<double>? _subscription;
  bool _isCancelled = false;

  bool get isRunning => _subscription != null;

  Stream<TaskProgress> runFakeTask({
    required String label,
    int durationMs = 4000,
  }) async* {
    _isCancelled = false;
    final steps = 100;
    final stepDelay = durationMs ~/ steps;

    yield TaskProgress(
      progress: 0,
      statusText: 'Starting $label...',
      status: TaskStatus.running,
    );

    for (var i = 1; i <= steps; i++) {
      if (_isCancelled) {
        yield TaskProgress(
          progress: 0,
          statusText: 'Cancelled',
          status: TaskStatus.cancelled,
        );
        return;
      }

      await Future.delayed(Duration(milliseconds: stepDelay));
      yield TaskProgress(
        progress: i / steps,
        statusText: _statusText(i / steps),
        status: TaskStatus.running,
      );
    }

    yield TaskProgress(
      progress: 1.0,
      statusText: 'Complete',
      status: TaskStatus.completed,
    );
  }

  void cancel() {
    _isCancelled = true;
    _subscription?.cancel();
    _subscription = null;
  }

  String _statusText(double progress) {
    if (progress < 0.2) return 'Initializing...';
    if (progress < 0.4) return 'Processing...';
    if (progress < 0.6) return 'Optimizing...';
    if (progress < 0.8) return 'Finalizing...';
    return 'Almost done...';
  }

  void dispose() {
    cancel();
  }
}

import "dart:async";
import "dart:collection";

// SimpleTaskQueue is a simple task queue that allows you to add tasks
// and run them concurrently up to a specified limit. It doesn't support
// task cancellation or timeout, but it can be used for simple
// asynchronous task management.
// See [TaskQueue] for a more advanced implementation with
class SimpleTaskQueue {
  final int maxConcurrent;
  final Queue<Future<void> Function()> _queue = Queue();
  int _runningTasks = 0;

  SimpleTaskQueue({this.maxConcurrent = 5});

  Future<void> add(Future<void> Function() task) async {
    final completer = Completer<void>();
    _queue.add(() async {
      try {
        await task();
        completer.complete();
      } catch (e) {
        completer.completeError(e);
      } finally {
        _runningTasks--;
        _processQueue();
      }
      return completer.future;
    });
    _processQueue();
    return completer.future;
  }

  void _processQueue() {
    while (_runningTasks < maxConcurrent && _queue.isNotEmpty) {
      final task = _queue.removeFirst();
      _runningTasks++;
      task();
    }
  }
}

import 'dart:async';

class ReplayFrame {
  ReplayFrame({
    required this.offset,
    required this.payload,
  });

  final Duration offset;
  final Map<String, dynamic> payload;
}

typedef ReplayCallback = FutureOr<void> Function(ReplayFrame frame);

/// Deterministic scheduler that replays recorded sessions with real-time pacing.
class RealtimeReplay {
  RealtimeReplay({
    required List<ReplayFrame> frames,
    this.onFrame,
  }) : _frames = frames..sort((a, b) => a.offset.compareTo(b.offset));

  final List<ReplayFrame> _frames;
  final ReplayCallback? onFrame;
  Timer? _timer;
  int _index = 0;
  DateTime? _startedAt;
  Completer<void>? _completer;

  Future<void> start() {
    if (_completer != null) {
      return _completer!.future;
    }
    _completer = Completer<void>();
    _startedAt = DateTime.now();
    _scheduleNext();
    return _completer!.future;
  }

  void stop() {
    _timer?.cancel();
    _completer?.complete();
    _timer = null;
    _startedAt = null;
  }

  void _scheduleNext() {
    if (_index >= _frames.length) {
      _completer?.complete();
      return;
    }
    final now = DateTime.now();
    final targetOffset = _frames[_index].offset;
    final elapsed = now.difference(_startedAt!);
    final delay = targetOffset - elapsed;
    if (delay <= Duration.zero) {
      _dispatchFrame();
    } else {
      _timer = Timer(delay, _dispatchFrame);
    }
  }

  void _dispatchFrame() {
    if (_index >= _frames.length) {
      _completer?.complete();
      return;
    }
    final frame = _frames[_index++];
    if (onFrame != null) {
      onFrame!(frame);
    }
    _scheduleNext();
  }
}


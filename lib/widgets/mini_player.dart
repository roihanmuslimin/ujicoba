import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class MiniPlayer extends StatefulWidget {
  final VoidCallback? onStop;

  const MiniPlayer({super.key, this.onStop});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  final AudioService _audio = AudioService.instance;
  StreamSubscription? _stateSub;
  StreamSubscription? _indexSub;
  PlayState _state = PlayState.stopped;
  int? _currentIndex;
  int _totalItems = 0;
  late Timer _timer;
  double _visualPhase = 0;

  @override
  void initState() {
    super.initState();
    _state = _audio.state;
    _currentIndex = _audio.currentIndex;
    _totalItems = _audio.totalItems;

    _stateSub = _audio.stateStream.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    _indexSub = _audio.indexStream.listen((idx) {
      if (mounted)
        setState(() {
          _currentIndex = idx;
          _totalItems = _audio.totalItems;
        });
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && _state == PlayState.playing) {
        setState(() => _visualPhase += 0.15);
      }
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _indexSub?.cancel();
    _timer.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_state == PlayState.playing) {
      _audio.pause();
    } else if (_state == PlayState.paused) {
      _audio.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == PlayState.stopped) return const SizedBox.shrink();

    final isPlaying = _state == PlayState.playing;
    final isPaused = _state == PlayState.paused;
    final isLoading = _state == PlayState.loading;
    if (!(isPlaying || isPaused || isLoading)) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2030),
        border: Border(top: BorderSide(color: Colors.grey[800]!, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _VisualizerBars(phase: _visualPhase, isPlaying: isPlaying),
          const SizedBox(width: 4),
          Text(
            _currentIndex != null ? 'Ayat ${_currentIndex! + 1}' : '',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.skip_previous,
              color: Colors.white,
              size: 22,
            ),
            onPressed: _currentIndex != null && _currentIndex! > 0
                ? () => _audio.previous()
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isLoading
                    ? Icons.hourglass_top
                    : (isPlaying ? Icons.pause : Icons.play_arrow),
                color: Colors.white,
                size: 22,
              ),
              onPressed: isLoading ? null : _togglePlayPause,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 22),
            onPressed: _currentIndex != null && _currentIndex! + 1 < _totalItems
                ? () => _audio.next()
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: Icon(
              Icons.repeat,
              color: _audio.loopMode
                  ? const Color(0xFF2E7D32)
                  : Colors.grey[500],
              size: 22,
            ),
            onPressed: () {
              _audio.toggleLoop();
              setState(() {});
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.white, size: 22),
            onPressed: () {
              _audio.stop();
              widget.onStop?.call();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

class _VisualizerBars extends StatelessWidget {
  final double phase;
  final bool isPlaying;

  const _VisualizerBars({required this.phase, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        painter: _BarPainter(phase: phase, isPlaying: isPlaying),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final double phase;
  final bool isPlaying;

  _BarPainter({required this.phase, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isPlaying) return;

    final paint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final heights = [0.3, 0.7, 0.4, 0.9, 0.5, 0.8, 0.35, 0.6];
    final count = heights.length;
    final spacing = size.width / count;
    final midY = size.height / 2;

    for (int i = 0; i < count; i++) {
      final x = spacing * i + spacing / 2;
      final h = heights[i] * (0.5 + 0.5 * sin(phase + i * 0.8));
      final barH = size.height * h * 0.4;
      canvas.drawLine(
        Offset(x, midY - barH / 2),
        Offset(x, midY + barH / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.phase != phase || old.isPlaying != isPlaying;
}

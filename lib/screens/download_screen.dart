import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../services/quran_api.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';

enum _ItemState { waiting, downloading, done, error }

class _DownloadTask {
  final Surah surah;
  _ItemState state = _ItemState.waiting;
  double progress = 0;
  int ayatDone = 0;
  int ayatTotal = 0;
  String? errorMsg;
  _DownloadTask(this.surah);
}

class DownloadScreen extends StatefulWidget {
  final List<Surah> surahs;
  const DownloadScreen({super.key, required this.surahs});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final QuranApi _api = QuranApi();
  final AudioService _audio = AudioService.instance;
  late List<_DownloadTask> _tasks;
  bool _running = true;
  bool _paused = false;
  int _overallDone = 0;
  int _overallTotal = 0;

  @override
  void initState() {
    super.initState();
    _tasks = widget.surahs.map((s) => _DownloadTask(s)).toList();
    _overallTotal = widget.surahs.fold(0, (sum, s) => sum + s.versesCount);
    _startAll();
  }

  Future<void> _startAll() async {
    final qariId = await SettingsService.getQariId();
    final dir = await _audio.getDownloadDir();
    final audioDir = Directory('$dir/quran_audio');
    if (!await audioDir.exists()) await audioDir.create(recursive: true);

    for (int i = 0; i < _tasks.length; i++) {
      if (!_running || _paused) break;
      await _downloadSurah(i, qariId, audioDir.path);
    }

    if (mounted) setState(() => _running = false);
  }

  Future<void> _downloadSurah(
    int taskIndex,
    int qariId,
    String audioDir,
  ) async {
    final task = _tasks[taskIndex];
    if (!mounted) return;
    setState(() {
      task.state = _ItemState.downloading;
      task.ayatTotal = task.surah.versesCount;
      task.progress = 0;
    });

    try {
      final data = await _api.getSurahDetail(
        task.surah.id,
        recitationId: qariId,
      );
      final ayat = data['ayat'] as List;

      for (int i = 0; i < ayat.length; i++) {
        if (!_running || _paused) return;

        final ayahNum = (ayat[i]['verse_number'] ?? i + 1) as int;
        final audioPath = ayat[i]['audio']?['url'] ?? '';
        final url = audioPath.isNotEmpty
            ? 'https://verses.quran.com/$audioPath'
            : '';
        if (url.isEmpty) continue;

        final s = task.surah.id.toString().padLeft(3, '0');
        final a = ayahNum.toString().padLeft(3, '0');
        final fileName = '${SettingsService.getQariPath(qariId)}_${s}_$a';

        final filePath = '$audioDir/$fileName.mp3';
        if (await File(filePath).exists()) {
          if (mounted)
            setState(() {
              task.ayatDone = i + 1;
              task.progress = (i + 1) / ayat.length;
              _overallDone++;
            });
          continue;
        }

        bool downloaded = false;
        int retries = 2;
        while (!downloaded && retries > 0 && _running && !_paused) {
          final result = await _audio.downloadAudio(
            url,
            fileName,
            onProgress: (p) {
              if (mounted)
                setState(() {
                  task.progress = (i + p) / ayat.length;
                });
            },
          );
          if (result != null) {
            downloaded = true;
          } else {
            retries--;
            if (retries > 0) await Future.delayed(const Duration(seconds: 2));
          }
        }

        if (!downloaded && _running) {
          if (mounted)
            setState(() {
              task.state = _ItemState.error;
              task.errorMsg = 'Gagal unduh ayat $ayahNum';
              _running = false;
            });
          return;
        }

        if (mounted)
          setState(() {
            task.ayatDone = i + 1;
            task.progress = (i + 1) / ayat.length;
            _overallDone++;
          });
      }

      if (mounted) setState(() => task.state = _ItemState.done);
    } catch (e) {
      if (mounted)
        setState(() {
          task.state = _ItemState.error;
          task.errorMsg = 'Gagal memuat data';
          _running = false;
        });
    }
  }

  void _retry(int index) {
    setState(() {
      _tasks[index].state = _ItemState.waiting;
      _tasks[index].progress = 0;
      _tasks[index].ayatDone = 0;
      _tasks[index].errorMsg = null;
      _running = true;
    });
    _startAll();
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (!_paused) _startAll();
  }

  @override
  Widget build(BuildContext context) {
    final done = _tasks.where((t) => t.state == _ItemState.done).length;
    final total = _tasks.length;

    return Scaffold(
      backgroundColor: const Color(0xFF131420),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131420),
        elevation: 0,
        title: const Text(
          'Unduhan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _paused ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
            ),
            onPressed: _togglePause,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => setState(() => _running = false),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1E2030),
            child: Column(
              children: [
                Text(
                  '$done / $total surah',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _overallTotal > 0 ? _overallDone / _overallTotal : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2E7D32),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_overallDone / $_overallTotal ayat',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _tasks.length,
              itemBuilder: (_, i) => _buildTaskTile(_tasks[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(_DownloadTask task, int index) {
    IconData icon;
    Color color;
    String status;

    switch (task.state) {
      case _ItemState.waiting:
        icon = Icons.hourglass_empty;
        color = Colors.grey[500]!;
        status = 'Menunggu';
      case _ItemState.downloading:
        icon = Icons.download_rounded;
        color = const Color(0xFF2E7D32);
        status = '${(task.progress * 100).toInt()}%';
      case _ItemState.done:
        icon = Icons.check_circle;
        color = const Color(0xFF2E7D32);
        status = 'Selesai';
      case _ItemState.error:
        icon = Icons.error;
        color = Colors.red[300]!;
        status = task.errorMsg ?? 'Gagal';
    }

    return Card(
      color: const Color(0xFF1E2030),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.surah.nameSimple,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(status, style: TextStyle(color: color, fontSize: 12)),
                  if (task.state == _ItemState.downloading) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: task.progress,
                        minHeight: 4,
                        backgroundColor: Colors.grey[800],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (task.state == _ItemState.error)
              TextButton(
                onPressed: () => _retry(index),
                child: const Text(
                  'Ulangi',
                  style: TextStyle(color: Color(0xFF2E7D32)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

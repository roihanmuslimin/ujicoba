import 'dart:io';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../models/surah.dart';
import '../services/quran_api.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final AudioService _audio = AudioService.instance;
  final QuranApi _api = QuranApi();
  List<Surah> _surahList = [];
  Set<int> _downloadedSurahs = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _surahList = await _api.getSurahList();
      await _scanDownloaded();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _scanDownloaded() async {
    final dir = await _audio.getDownloadDir();
    final audioDir = Directory('$dir/quran_audio');
    if (!await audioDir.exists()) {
      _downloadedSurahs = {};
      return;
    }

    final files = await audioDir.list().toList();
    final surahIds = <int>{};
    for (final f in files) {
      final name = f.uri.pathSegments.last;
      final parts = name.split('_');
      if (parts.length >= 2) {
        final surahStr = parts[parts.length - 2];
        final id = int.tryParse(surahStr);
        if (id != null) surahIds.add(id);
      }
    }
    _downloadedSurahs = surahIds;
  }

  Future<void> _deleteSurah(int surahId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2030),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus unduhan?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'File audio surah ini akan dihapus.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final dir = await _audio.getDownloadDir();
    final audioDir = Directory('$dir/quran_audio');
    if (!await audioDir.exists()) return;

    final files = await audioDir.list().toList();
    for (final f in files) {
      final name = f.uri.pathSegments.last;
      final parts = name.split('_');
      if (parts.length >= 2) {
        final surahStr = parts[parts.length - 2];
        final id = int.tryParse(surahStr);
        if (id == surahId) await File(f.path).delete();
      }
    }
    await _scanDownloaded();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131420),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131420),
        elevation: 0,
        title: const Text(
          'Unduhan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            )
          : _downloadedSurahs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_done, color: Colors.grey[600], size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada unduhan',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Download surah untuk baca offline',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: _surahList
                  .where((s) => _downloadedSurahs.contains(s.id))
                  .map(
                    (s) => Card(
                      color: const Color(0xFF1E2030),
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2E7D32,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${s.id}',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          s.nameSimple,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${s.versesCount} Ayat',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _deleteSurah(s.id),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

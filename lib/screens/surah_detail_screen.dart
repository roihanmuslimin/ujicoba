import 'dart:async';
import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../services/quran_api.dart';
import '../services/audio_service.dart';

class SurahDetailScreen extends StatefulWidget {
  final Surah surah;

  const SurahDetailScreen({super.key, required this.surah});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final QuranApi _api = QuranApi();
  final AudioService _audioService = AudioService();
  late Future<Map<String, dynamic>> _detailFuture;
  StreamSubscription? _stateSub;
  int? _playingAyahIndex;

  @override
  void initState() {
    super.initState();
    _detailFuture = _api.getSurahDetail(widget.surah.nomor);
    _stateSub = _audioService.stateStream.listen((state) {
      if (state == AudioState.stopped || state == AudioState.error) {
        setState(() => _playingAyahIndex = null);
      }
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1D2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1D2B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.surah.namaLatin,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat ayat',
                style: TextStyle(color: Colors.grey[300]),
              ),
            );
          }

          final data = snapshot.data!;
          final surah = data['surah'] as Surah;
          final ayatList = data['ayat'] as List<Ayah>;

          return Column(
            children: [
              _Header(surah: surah),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: ayatList.length,
                  itemBuilder: (context, index) {
                    final ayah = ayatList[index];
                    return _AyahCard(
                      ayah: ayah,
                      isPlaying: _playingAyahIndex == index,
                      onPlay: () => _togglePlay(ayah, index),
                      onDownload: () => _downloadAudio(ayah, index),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _togglePlay(Ayah ayah, int index) async {
    final url = ayah.audio?.primaryAudio;
    if (url == null) return;

    if (_playingAyahIndex == index) {
      await _audioService.pause();
      setState(() => _playingAyahIndex = null);
      return;
    }

    setState(() => _playingAyahIndex = index);
    String fileName = '${widget.surah.nomor}_${ayah.nomor}';
    String? localPath = await _audioService.getLocalPath(fileName);

    if (localPath != null) {
      await _audioService.playLocal(localPath);
    } else {
      await _audioService.playUrl(url);
    }
  }

  Future<void> _downloadAudio(Ayah ayah, int index) async {
    final url = ayah.audio?.primaryAudio;
    if (url == null) return;

    String fileName = '${widget.surah.nomor}_${ayah.nomor}';
    String? path = await _audioService.downloadAudio(url, fileName);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path != null ? 'Audio tersimpan' : 'Gagal download'),
          backgroundColor: path != null ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

class _Header extends StatelessWidget {
  final Surah surah;

  const _Header({required this.surah});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B7FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Text(
            surah.nama,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            surah.namaLatin,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${surah.arti} • ${surah.jumlahAyat} Ayat • ${surah.tempatTurun}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _AyahCard extends StatelessWidget {
  final Ayah ayah;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onDownload;

  const _AyahCard({
    required this.ayah,
    required this.isPlaying,
    required this.onPlay,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isPlaying ? const Color(0xFF2E3040) : const Color(0xFF222438),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPlaying
            ? const BorderSide(color: Color(0xFF6C63FF), width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${ayah.nomor}',
                      style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (ayah.audio?.primaryAudio != null) ...[
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_circle : Icons.play_circle,
                          color: isPlaying
                              ? const Color(0xFF6C63FF)
                              : Colors.grey[400],
                          size: 28,
                        ),
                        onPressed: onPlay,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.download,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        onPressed: onDownload,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              ayah.arab,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                height: 1.8,
                fontFamily: 'me_quran',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ayah.latin,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1D2B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ayah.terjemahan,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

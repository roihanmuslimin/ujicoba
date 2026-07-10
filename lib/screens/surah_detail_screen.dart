import 'dart:async';
import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../services/quran_api.dart';
import '../services/audio_service.dart';
import '../widgets/tajwid_text.dart';

class SurahDetailScreen extends StatefulWidget {
  final Surah surah;
  const SurahDetailScreen({super.key, required this.surah});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final QuranApi _api = QuranApi();
  final AudioService _audio = AudioService();
  List<Ayah>? _ayatList;
  bool _loading = true;
  String? _error;
  StreamSubscription? _stateSub;
  int? _playingIndex;
  bool _isPlayingAll = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _stateSub = _audio.stateStream.listen((s) {
      if (mounted) {
        if (s == PlayState.stopped || s == PlayState.error) {
          setState(() {
            _playingIndex = null;
            _isPlayingAll = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getSurahDetail(widget.surah.nomor);
      setState(() {
        _ayatList = data['ayat'] as List<Ayah>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat ayat';
        _loading = false;
      });
    }
  }

  String _getAyahAudioUrl(int ayahNum) {
    final s = widget.surah.nomor.toString().padLeft(3, '0');
    final a = ayahNum.toString().padLeft(3, '0');
    return 'https://cdn.equran.id/audio/ayah/$s$a.mp3';
  }

  Future<void> _togglePlay(int index) async {
    if (_isPlayingAll) {
      await _audio.stop();
      return;
    }

    final ayah = _ayatList![index];
    final url = _getAyahAudioUrl(ayah.nomor);

    if (_playingIndex == index) {
      await _audio.pause();
      setState(() => _playingIndex = null);
      return;
    }

    setState(() => _playingIndex = index);
    final fileName = '${widget.surah.nomor}_${ayah.nomor}';
    final local = await _audio.getLocalPath(fileName);
    if (local != null) {
      await _audio.playLocal(local);
    } else {
      await _audio.play(url);
    }

    if (_audio.state == PlayState.error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal putar audio. Coba download dulu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playAll() async {
    if (_isPlayingAll) {
      await _audio.stop();
      return;
    }

    final urls = _ayatList!.map((a) => _getAyahAudioUrl(a.nomor)).toList();
    setState(() {
      _isPlayingAll = true;
      _playingIndex = 0;
    });

    await _audio.playList(urls);

    if (_audio.state == PlayState.error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal putar audio. Periksa koneksi.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isPlayingAll = false;
          _playingIndex = null;
        });
      }
    }
  }

  Future<void> _download(int index) async {
    final ayah = _ayatList![index];
    final url = _getAyahAudioUrl(ayah.nomor);
    final fileName = '${widget.surah.nomor}_${ayah.nomor}';
    final path = await _audio.download(url, fileName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path != null ? 'Audio tersimpan' : 'Gagal download'),
          backgroundColor: path != null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  String _getSurahAudioUrl() {
    return 'https://cdn.equran.id/audio-full/Misyari-Rasyid-Al-Afasi/${widget.surah.nomor.toString().padLeft(3, '0')}.mp3';
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey[300])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final list = _ayatList!;
    return Column(
      children: [
        _Header(surah: widget.surah),
        _PlayAllBar(isPlaying: _isPlayingAll, onPlayAll: _playAll),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) => _AyahCard(
              ayah: list[i],
              isPlaying: _playingIndex == i,
              onPlay: () => _togglePlay(i),
              onDownload: () => _download(i),
            ),
          ),
        ),
      ],
    );
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B7FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
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
            '${surah.arti} \u2022 ${surah.jumlahAyat} Ayat \u2022 ${surah.tempatTurun}',
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

class _PlayAllBar extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayAll;

  const _PlayAllBar({required this.isPlaying, required this.onPlayAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPlayAll,
          icon: Icon(isPlaying ? Icons.stop : Icons.play_circle_fill),
          label: Text(isPlaying ? 'Berhenti' : 'Putar Semua'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            TajwidText(text: ayah.arab, fontSize: 24, height: 1.8),
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

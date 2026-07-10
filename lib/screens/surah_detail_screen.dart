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
      final data = await _api.getSurahDetail(widget.surah.id);
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

  void _showAyahOptions(int index) {
    final ayah = _ayatList![index];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2030),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AyahBottomSheet(
        ayah: ayah,
        surahId: widget.surah.id,
        audioService: _audio,
        onPlayFromHere: () async {
          Navigator.pop(ctx);
          await _playFromIndex(index);
        },
      ),
    );
  }

  Future<void> _playFromIndex(int startIndex) async {
    if (_ayatList == null || startIndex >= _ayatList!.length) return;

    final urls = _ayatList!
        .skip(startIndex)
        .map((a) => a.audioUrl)
        .where((u) => u.isNotEmpty)
        .toList();

    if (urls.isEmpty) return;

    setState(() {
      _isPlayingAll = true;
      _playingIndex = startIndex;
    });
    final ok = await _audio.playList(urls);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memutar audio'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isPlayingAll = false;
        _playingIndex = null;
      });
    }
  }

  String _revelationPlace(String place) {
    switch (place) {
      case 'makkah':
        return 'Makkiyah';
      case 'madinah':
        return 'Madaniyah';
      default:
        return place;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131420),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131420),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.surah.nameSimple,
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
        _Header(
          surah: widget.surah,
          revelationPlace: _revelationPlace(widget.surah.revelationPlace),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) => _AyahCard(
              ayah: list[i],
              isPlaying: _playingIndex == i,
              isPlayingAll: _isPlayingAll,
              onTap: () => _showAyahOptions(i),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final Surah surah;
  final String revelationPlace;
  const _Header({required this.surah, required this.revelationPlace});

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
            surah.nameArabic,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            surah.nameSimple,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${surah.translatedName} \u2022 ${surah.versesCount} Ayat \u2022 $revelationPlace',
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
  final bool isPlayingAll;
  final VoidCallback onTap;

  const _AyahCard({
    required this.ayah,
    required this.isPlaying,
    required this.isPlayingAll,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = isPlaying && isPlayingAll;
    return Card(
      color: highlight ? const Color(0xFF2E3040) : const Color(0xFF1A1C2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: highlight
            ? const BorderSide(color: Color(0xFF6C63FF), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _VerseNumber(nomor: ayah.nomor, isActive: highlight),
                  if (isPlaying && isPlayingAll)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow,
                            color: Color(0xFF6C63FF),
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Memutar',
                            style: TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TajwidText(text: ayah.arab, fontSize: 24, height: 1.8),
              if (ayah.terjemahan.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131420),
                    borderRadius: BorderRadius.circular(10),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseNumber extends StatelessWidget {
  final int nomor;
  final bool isActive;
  const _VerseNumber({required this.nomor, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF6C63FF)
            : const Color(0xFF6C63FF).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$nomor',
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF6C63FF),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _AyahBottomSheet extends StatefulWidget {
  final Ayah ayah;
  final int surahId;
  final AudioService audioService;
  final VoidCallback onPlayFromHere;

  const _AyahBottomSheet({
    required this.ayah,
    required this.surahId,
    required this.audioService,
    required this.onPlayFromHere,
  });

  @override
  State<_AyahBottomSheet> createState() => _AyahBottomSheetState();
}

class _AyahBottomSheetState extends State<_AyahBottomSheet> {
  double? _downloadProgress;
  bool _downloading = false;

  String get _fileName => '${widget.surahId}_${widget.ayah.nomor}';

  @override
  void initState() {
    super.initState();
    _checkDownloaded();
  }

  Future<void> _checkDownloaded() async {
    final ok = await widget.audioService.isDownloaded(_fileName);
    if (mounted && !ok) setState(() {});
  }

  Future<void> _downloadAndPlay() async {
    if (widget.ayah.audioUrl.isEmpty) return;

    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });

    final path = await widget.audioService.downloadAudio(
      widget.ayah.audioUrl,
      _fileName,
      onProgress: (p) {
        if (mounted)
          setState(() {
            _downloadProgress = p;
          });
      },
    );

    if (!mounted) return;

    if (path != null) {
      setState(() {
        _downloadProgress = 1;
        _downloading = false;
      });
      widget.onPlayFromHere();
    } else {
      setState(() {
        _downloading = false;
        _downloadProgress = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengunduh audio'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ayah = widget.ayah;
    final isDownloaded = _downloadProgress == 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          TajwidText(text: ayah.arab, fontSize: 26, height: 1.6),
          const SizedBox(height: 8),
          Text(
            ayah.terjemahan,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 24),

          if (_downloading &&
              _downloadProgress != null &&
              _downloadProgress! < 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _downloadProgress,
                      minHeight: 6,
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF6C63FF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mengunduh ${(_downloadProgress! * 100).toInt()}%',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.play_circle_fill,
                  label: 'Putar Disini',
                  subtitle: 'Dari ayat ini sampai selesai',
                  color: const Color(0xFF6C63FF),
                  onTap: () async {
                    if (!isDownloaded && !_downloading) {
                      await _downloadAndPlay();
                    } else {
                      widget.onPlayFromHere();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.menu_book_rounded,
                  label: 'Hanya Baca',
                  subtitle: 'Lihat ayat tanpa audio',
                  color: Colors.grey[600]!,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

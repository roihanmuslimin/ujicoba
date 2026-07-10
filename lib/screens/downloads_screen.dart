import 'dart:io';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class _DownloadedSurah {
  final int surahId;
  final String nameSimple;
  final String nameArabic;
  final List<File> files;
  int get ayahCount => files.length;

  _DownloadedSurah({
    required this.surahId,
    required this.nameSimple,
    required this.nameArabic,
    required this.files,
  });
}

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final AudioService _audio = AudioService.instance;
  List<_DownloadedSurah> _surahs = [];
  bool _loading = true;
  bool _playing = false;
  int? _playingSurahId;

  static const List<String> _surahNames = [
    '',
    'Al-Fatihah',
    'Al-Baqarah',
    'Ali Imran',
    'An-Nisa\'',
    'Al-Ma\'idah',
    'Al-An\'am',
    'Al-A\'raf',
    'Al-Anfal',
    'At-Taubah',
    'Yunus',
    'Hud',
    'Yusuf',
    'Ar-Ra\'d',
    'Ibrahim',
    'Al-Hijr',
    'An-Nahl',
    'Al-Isra\'',
    'Al-Kahf',
    'Maryam',
    'Taha',
    'Al-Anbiya\'',
    'Al-Hajj',
    'Al-Mu\'minun',
    'An-Nur',
    'Al-Furqan',
    'Asy-Syu\'ara\'',
    'An-Naml',
    'Al-Qasas',
    'Al-\'Ankabut',
    'Ar-Rum',
    'Luqman',
    'As-Sajdah',
    'Al-Ahzab',
    'Saba\'',
    'Fatir',
    'Yasin',
    'As-Saffat',
    'Sad',
    'Az-Zumar',
    'Al-Mu\'min',
    'Fussilat',
    'Asy-Syura',
    'Az-Zukhruf',
    'Ad-Dukhan',
    'Al-Jasiyah',
    'Al-Ahqaf',
    'Muhammad',
    'Al-Fath',
    'Al-Hujurat',
    'Qaf',
    'Az-Zariyat',
    'At-Tur',
    'An-Najm',
    'Al-Qamar',
    'Ar-Rahman',
    'Al-Waqi\'ah',
    'Al-Hadid',
    'Al-Mujadilah',
    'Al-Hasyr',
    'Al-Mumtahanah',
    'As-Saff',
    'Al-Jumu\'ah',
    'Al-Munafiqun',
    'At-Taghabun',
    'At-Talaq',
    'At-Tahrim',
    'Al-Mulk',
    'Al-Qalam',
    'Al-Haqqah',
    'Al-Ma\'arij',
    'Nuh',
    'Al-Jinn',
    'Al-Muzzammil',
    'Al-Muddassir',
    'Al-Qiyamah',
    'Al-Insan',
    'Al-Mursalat',
    'An-Naba\'',
    'An-Nazi\'at',
    '\'Abasa',
    'At-Takwir',
    'Al-Infitar',
    'Al-Mutaffifin',
    'Al-Insyiqaq',
    'Al-Buruj',
    'At-Tariq',
    'Al-A\'la',
    'Al-Gasyiyah',
    'Al-Fajr',
    'Al-Balad',
    'Asy-Syams',
    'Al-Lail',
    'Ad-Duha',
    'Asy-Syarh',
    'At-Tin',
    'Al-\'Alaq',
    'Al-Qadr',
    'Al-Bayyinah',
    'Az-Zalzalah',
    'Al-\'Adiyat',
    'Al-Qari\'ah',
    'At-Takasur',
    'Al-\'Asr',
    'Al-Humazah',
    'Al-Fil',
    'Quraisy',
    'Al-Ma\'un',
    'Al-Kausar',
    'Al-Kafirun',
    'An-Nasr',
    'Al-Lahab',
    'Al-Ikhlas',
    'Al-Falaq',
    'An-Nas',
  ];

  static const List<String> _arabicNames = [
    '',
    '\uFEEB\uFEEE\uFEDD\uFE8D',
    '\uFEE3\uFEB0\uFEDB\uFE8D',
    '\uFEFB\uFEEA\uFEE0\uFEDF\uFE94',
    '\uFEF4\uFEE1\uFEDB\uFE8D',
    '\uFEE3\uFE99\uFEEA\uFEDF\uFE8D',
    '\uFEF4\uFEE1\uFEE8\uFED6\uFE8D',
    '\uFEFC\uFE91\uFEE7\uFEDF\uFE8D',
    '\uFEF4\uFEE3\uFE8E\uFEDB\uFE8D',
    '\uFEE0\uFEDB\uFE8D',
    '\uFEEF\uFE9B\uFEE6\uFEDB\uFE8D',
    '\uFEDB\uFEA3\uFEEC\uFE8D',
    '\uFEEF\uFE9B\uFEE6\uFEDF\uFE98',
    '\uFEEB\uFEAE\uFEDB\uFE8D',
    '\uFEF1\uFEEB\uFEA3\uFEDF\uFE8D',
    '\uFEE3\uFEB3\uFED8\uFE8D',
    '\uFEF4\uFEE0\uFEA2\uFEDF\uFE8D',
    '\uFEFC\uFEE1\uFEB3\uFEDF\uFE8D',
    '\uFEFC\uFEE1\uFEE8\uFEDF\uFE8D',
    '\uFEEB\uFEE8\uFEB8\uFEDF\uFE8D',
    '\uFEE3\uFEEF\uFEDF\uFE92',
    '\uFEE0\uFEEF\uFEDF\uFE92',
    '\uFEFB\uFEE1\uFE8E\uFEDF\uFE8D',
    '\uFEE3\uFE91\uFED8\uFE8D',
    '\uFEF4\uFEE1\uFE8E\uFEDF\uFE8D',
    '\uFEF5\uFEEA\uFEDB\uFE8D',
    '\uFEE3\uFEA3\uFEEA\uFEDF\uFE8D',
    '\uFEF6\uFEEA\uFEDB\uFE8D',
    '\uFEF4\uFEE1\uFEB7\uFEDF\uFE8D',
    '\uFEEB\uFEE8\uFEB8\uFEDF\uFE98',
    '\uFEF3\uFEEC\uFEDF\uFE98',
    '\uFEEF\uFEAA\uFEDB\uFE8D',
    '\uFEEF\uFEE1\uFEDF\uFE92',
    '\uFEE3\uFEEA\uFEDF\uFE8D',
    '\uFEE0\uFED8\uFE8D',
    '\uFEE3\uFEE3\uFEDF\uFE8D',
    '\uFEF6\uFEE3\uFEA3\uFEDF\uFE8D',
    '\uFEE3\uFEEB\uFEE0\uFEDF\uFE8D',
    '\uFEE0\uFEE1\uFEDF\uFE92',
    '\uFEF6\uFEE3\uFED8\uFE8D',
    '\uFEEF\uFEDB\uFE8D',
    '\uFEE3\uFEB0\uFEE0\uFEDF\uFE8D',
    '\uFEF6\uFEE3\uFEA3\uFEDF\uFE98',
    '\uFEF3\uFEEA\uFEDF\uFE98',
    '\uFEF4\uFEE3\uFED6\uFE8D',
    '\uFEEF\uFEE8\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEF5\uFEEB\uFEDB\uFE8D',
    '\uFEEF\uFEE1\uFEDF\uFE92',
    '\uFEE3\uFEE3\uFEDF\uFE92',
    '\uFEE3\uFEB0\uFEDB\uFE8D',
    '\uFEE3\uFEE1\uFEA2\uFEDF\uFE8D',
    '\uFEE3\uFEB2\uFEDF\uFE98',
    '\uFEF4\uFEE0\uFEDF\uFE8D',
    '\uFEE3\uFEE1\uFEE6\uFEDB\uFE8D',
    '\uFEE0\uFEDF\uFE98',
    '\uFEEB\uFEEA\uFEDF\uFE98',
    '\uFEE3\uFEB1\uFEDB\uFE8D',
    '\uFEE3\uFEE1\uFEDF\uFE92',
    '\uFEE3\uFEB1\uFEDF\uFE98',
    '\uFEE3\uFEE3\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEA3\uFEDF\uFE98',
    '\uFEE3\uFEE0\uFEDB\uFE8D',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEEB\uFEE0\uFEDB\uFE8D',
    '\uFEEF\uFEE3\uFEDF\uFE92',
    '\uFEFB\uFEEB\uFEDF\uFE98',
    '\uFEF4\uFEE0\uFEA2\uFEDF\uFE98',
    '\uFEE3\uFEEA\uFEDF\uFE98',
    '\uFEFB\uFEE3\uFEDF\uFE98',
    '\uFEFB\uFEE1\uFEDF\uFE92',
    '\uFEE3\uFEEA\uFEDF\uFE8D',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEF4\uFEE0\uFEA2\uFEDF\uFE8D',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEEF\uFEDB\uFE8D',
    '\uFEF4\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE8D',
    '\uFEE3\uFEE0\uFEDB\uFE8D',
    '\uFEF4\uFEE3\uFED6\uFE8D',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEE3\uFEDF\uFE8D',
    '\uFEE0\uFEDB\uFE8D',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE8D',
    '\uFEE3\uFEEA\uFEDF\uFE8D',
    '\uFEE3\uFEEB\uFEDF\uFE98',
    '\uFEF4\uFEE3\uFED6\uFE8D',
    '\uFEF3\uFEEA\uFEDF\uFE8D',
    '\uFEF3\uFEEA\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEEB\uFEDF\uFE98',
    '\uFEE3\uFEB0\uFEDF\uFE8D',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE8D',
    '\uFEE3\uFEE3\uFEDF\uFE8D',
    '\uFEE3\uFEB2\uFEDF\uFE98',
    '\uFEF4\uFEE3\uFED6\uFE8D',
    '\uFEE3\uFEB2\uFEDF\uFE8D',
    '\uFEF4\uFEE1\uFEDF\uFE8D',
    '\uFEE3\uFEB0\uFEDB\uFE8D',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEEA\uFEDF\uFE8D',
    '\uFEF5\uFEEB\uFEDB\uFE8D',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE8D',
    '\uFEEF\uFEDB\uFE8D',
    '\uFEF4\uFEE1\uFEDB\uFE8D',
    '\uFEF4\uFEE0\uFEDB\uFE8D',
    '\uFEFB\uFEE3\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE8D',
    '\uFEE3\uFEEA\uFEDF\uFE8D',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEEB\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEF4\uFEE1\uFEDF\uFE98',
    '\uFEFB\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE8D',
    '\uFEF5\uFEEB\uFEDB\uFE8D',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE8D',
    '\uFEF4\uFEE3\uFED6\uFE8D',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEE3\uFEDF\uFE8D',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE8D',
    '\uFEEF\uFEE1\uFEDF\uFE8D',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE8D',
    '\uFEE3\uFEB0\uFEDB\uFE8D',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEF4\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE8D',
    '\uFEF4\uFEE1\uFEDB\uFE8D',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE8D',
    '\uFEFB\uFEE3\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEEB\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE98',
    '\uFEE3\uFEE1\uFEDF\uFE8D',
  ];

  @override
  void initState() {
    super.initState();
    _scanDownloads();
  }

  Future<void> _scanDownloads() async {
    setState(() {
      _loading = true;
      _surahs = [];
    });

    try {
      final dir = await _audio.getDownloadDir();
      final audioDir = Directory('$dir/quran_audio');
      if (!await audioDir.exists()) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final files = await audioDir
          .list()
          .where((f) => f.path.endsWith('.mp3'))
          .toList();

      final Map<int, List<File>> surahMap = {};

      for (final file in files) {
        final name = file.uri.pathSegments.last.replaceAll('.mp3', '');
        final parts = name.split('_');
        if (parts.length >= 3) {
          final surahId = int.tryParse(parts[parts.length - 2]);
          if (surahId != null && surahId >= 1 && surahId <= 114) {
            surahMap.putIfAbsent(surahId, () => []);
            surahMap[surahId]!.add(file as File);
          }
        }
      }

      final surahs = surahMap.entries.map((e) {
        final id = e.key;
        final name = id < _surahNames.length ? _surahNames[id] : 'Surah $id';
        final arabic = id < _arabicNames.length ? _arabicNames[id] : '';
        e.value.sort((a, b) => a.path.compareTo(b.path));
        return _DownloadedSurah(
          surahId: id,
          nameSimple: name,
          nameArabic: arabic,
          files: e.value,
        );
      }).toList()
        ..sort((a, b) => a.surahId.compareTo(b.surahId));

      if (mounted) setState(() { _surahs = surahs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _playSurah(_DownloadedSurah surah) async {
    final paths = surah.files.map((f) => f.path).toList();
    setState(() { _playingSurahId = surah.surahId; _playing = true; });
    await _audio.playLocalList(paths);
  }

  Future<void> _deleteSurah(_DownloadedSurah surah) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2030),
        title: const Text('Hapus Unduhan?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Hapus semua audio ${surah.nameSimple}?',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final file in surah.files) {
        await file.delete();
      }
      _scanDownloads();
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
        title: const Text(
          'Unduhan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _scanDownloads,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      );
    }

    if (_surahs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_done_rounded,
                color: Colors.grey[600], size: 64),
            const SizedBox(height: 16),
            Text(
              'Belum ada unduhan',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih surah lalu tekan "Download & Putar"',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1E2030),
          child: Row(
            children: [
              const Icon(Icons.folder_rounded,
                  color: Color(0xFF2E7D32), size: 20),
              const SizedBox(width: 8),
              Text(
                '${_surahs.length} surah \u2022 ${_surahs.fold(0, (sum, s) => sum + s.ayahCount)} ayat',
                style: TextStyle(color: Colors.grey[300], fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _surahs.length,
            itemBuilder: (_, i) => _buildSurahCard(_surahs[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildSurahCard(_DownloadedSurah surah) {
    final isPlaying = _playingSurahId == surah.surahId && _playing;

    return Card(
      color: isPlaying
          ? const Color(0xFF1B3A1B)
          : const Color(0xFF1E2030),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPlaying
            ? const BorderSide(color: Color(0xFF2E7D32), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withAlpha(38),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${surah.surahId}',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameSimple,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${surah.ayahCount} ayat terunduh',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              surah.nameArabic,
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.stop_circle : Icons.play_circle_fill_rounded,
                color: const Color(0xFF2E7D32),
                size: 32,
              ),
              onPressed: () {
                if (isPlaying) {
                  _audio.stop();
                  setState(() { _playing = false; _playingSurahId = null; });
                } else {
                  _playSurah(surah);
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Colors.grey[500], size: 22),
              onPressed: () => _deleteSurah(surah),
            ),
          ],
        ),
      ),
    );
  }
}

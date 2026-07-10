import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../services/quran_api.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../widgets/tajwid_text.dart';
import '../widgets/mini_player.dart';

class SurahDetailScreen extends StatefulWidget {
  final Surah surah;
  const SurahDetailScreen({super.key, required this.surah});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final QuranApi _api = QuranApi();
  final AudioService _audio = AudioService.instance;
  final ScrollController _scrollCtrl = ScrollController();
  List<Ayah>? _ayatList;
  bool _loading = true;
  String? _error;
  StreamSubscription? _stateSub;
  StreamSubscription? _indexSub;
  bool _isPlaying = false;
  int _playStartOffset = 0;
  final Map<int, GlobalKey> _itemKeys = {};
  bool _manualScroll = false;
  Timer? _manualScrollTimer;

  int _selectedQari = 7;
  double _arabicFontSize = 24;
  double _translationFontSize = 14;

  @override
  void initState() {
    super.initState();
    _loadQari();
    _loadData();
    _stateSub = _audio.stateStream.listen((s) {
      if (mounted) {
        setState(
          () => _isPlaying = s == PlayState.playing || s == PlayState.paused,
        );
        if (s == PlayState.stopped) {
          setState(() => _playStartOffset = 0);
        }
      }
    });
    _indexSub = _audio.indexStream.listen((idx) {
      if (!mounted || _ayatList == null) return;
      setState(() {});
      if (idx != null) {
        final verseIdx = _playStartOffset + idx;
        if (verseIdx < _ayatList!.length) {
          _ensureVisible(verseIdx);
        }
      }
    });
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    _manualScroll = true;
    _manualScrollTimer?.cancel();
    _manualScrollTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _manualScroll = false;
    });
  }

  void _ensureVisible(int verseIdx) {
    if (_manualScroll) return;
    final ctx = _itemKeys[verseIdx]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      alignment: 0.15,
    );
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _indexSub?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _manualScrollTimer?.cancel();
    super.dispose();
  }

  int get _activeVerseIndex {
    final idx = _audio.currentIndex;
    if (idx == null || _ayatList == null) return -1;
    return _playStartOffset + idx;
  }

  Future<void> _loadQari() async {
    final id = await SettingsService.getQariId();
    final arab = await SettingsService.getArabicFontSize();
    final trans = await SettingsService.getTranslationFontSize();
    if (mounted)
      setState(() {
        _selectedQari = id;
        _arabicFontSize = arab;
        _translationFontSize = trans;
      });
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
      for (int i = 0; i < _ayatList!.length; i++) {
        _itemKeys[i] = GlobalKey();
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat ayat';
        _loading = false;
      });
    }
  }

  String _ayahAudioUrl(int ayahNum) {
    return SettingsService.audioUrl(_selectedQari, widget.surah.id, ayahNum);
  }

  String _audioFileName(int ayahNum) {
    final s = widget.surah.id.toString().padLeft(3, '0');
    final a = ayahNum.toString().padLeft(3, '0');
    return '${SettingsService.getQariPath(_selectedQari)}_${s}_$a';
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
        onPlayFromHere: () {
          Navigator.pop(ctx);
          _downloadAndPlay(index);
        },
      ),
    );
  }

  Future<void> _downloadAndPlay(int startIndex) async {
    if (_ayatList == null || startIndex >= _ayatList!.length) return;

    final ayat = _ayatList!.skip(startIndex).toList();
    final dir = await _audio.getDownloadDir();
    final audioDir = Directory('$dir/quran_audio');
    if (!await audioDir.exists()) await audioDir.create(recursive: true);

    List<String> localFiles = [];
    List<_DownloadItem> needDownload = [];

    for (int i = 0; i < ayat.length; i++) {
      final ayah = ayat[i];
      final fileName = _audioFileName(ayah.nomor);
      final localPath = '${audioDir.path}/$fileName.mp3';
      if (await File(localPath).exists()) {
        localFiles.add(localPath);
      } else {
        needDownload.add(
          _DownloadItem(
            index: i,
            ayahNum: ayah.nomor,
            url: _ayahAudioUrl(ayah.nomor),
            fileName: fileName,
          ),
        );
        localFiles.add(localPath);
      }
    }

    if (needDownload.isEmpty) {
      setState(() => _playStartOffset = startIndex);
      await _audio.playLocalList(localFiles);
      return;
    }

    if (!mounted) return;
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) => _DownloadProgressDialog(
        items: needDownload,
        totalItems: ayat.length,
        audioService: _audio,
        onComplete: (allPaths) async {
          Navigator.of(ctx).pop();
          if (mounted) {
            setState(() => _playStartOffset = startIndex);
            await _audio.playLocalList(allPaths);
          }
        },
      ),
    );
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
    final activeIdx = _activeVerseIndex;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.only(
              top: 12,
              left: 12,
              right: 12,
              bottom: 8,
            ),
            itemCount: list.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return Column(
                  children: [
                    _Header(
                      surah: widget.surah,
                      revelationPlace: _revelationPlace(
                        widget.surah.revelationPlace,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }
              final idx = i - 1;
              final ayah = list[idx];
              return _AyahCard(
                key: _itemKeys[idx],
                ayah: ayah,
                isPlaying: activeIdx == idx,
                arabicFontSize: _arabicFontSize,
                translationFontSize: _translationFontSize,
                onTap: () => _showAyahOptions(idx),
              );
            },
          ),
        ),
        MiniPlayer(onStop: () => setState(() => _playStartOffset = 0)),
      ],
    );
  }
}

class _DownloadItem {
  final int index;
  final int ayahNum;
  final String url;
  final String fileName;
  _DownloadItem({
    required this.index,
    required this.ayahNum,
    required this.url,
    required this.fileName,
  });
}

class _DownloadProgressDialog extends StatefulWidget {
  final List<_DownloadItem> items;
  final int totalItems;
  final AudioService audioService;
  final void Function(List<String> allPaths) onComplete;

  const _DownloadProgressDialog({
    required this.items,
    required this.totalItems,
    required this.audioService,
    required this.onComplete,
  });

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  int _currentItem = 0;
  double _itemProgress = 0;
  bool _downloading = true;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    final dir = await widget.audioService.getDownloadDir();
    final audioDir = '$dir/quran_audio';

    for (int i = 0; i < widget.items.length; i++) {
      if (!mounted) return;
      setState(() {
        _currentItem = i;
        _itemProgress = 0;
      });

      final item = widget.items[i];
      await widget.audioService.downloadAudio(
        item.url,
        item.fileName,
        onProgress: (p) {
          if (mounted) setState(() => _itemProgress = p);
        },
      );
    }

    if (!mounted) return;
    setState(() => _downloading = false);

    final allPaths = <String>[];
    for (int i = 0; i < widget.items.length; i++) {
      allPaths.add('$audioDir/${widget.items[i].fileName}.mp3');
    }
    widget.onComplete(allPaths);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;
    final done = _currentItem + (_itemProgress >= 1 ? 1 : 0);
    final overallProgress = total > 0 ? done / total : 0.0;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E2030),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.download_rounded,
              color: Color(0xFF6C63FF),
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              _downloading ? 'Mengunduh...' : 'Selesai!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ayat ${_currentItem + 1} dari $total',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: overallProgress,
                minHeight: 8,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF6C63FF),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(overallProgress * 100).toInt()}%',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Ayat ini: ${(_itemProgress * 100).toInt()}%',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ),
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
  final double arabicFontSize;
  final double translationFontSize;
  final VoidCallback onTap;

  const _AyahCard({
    super.key,
    required this.ayah,
    required this.isPlaying,
    this.arabicFontSize = 24,
    this.translationFontSize = 14,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isPlaying ? const Color(0xFF2E3040) : const Color(0xFF1A1C2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isPlaying
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
                  _VerseNumber(nomor: ayah.nomor, isActive: isPlaying),
                  if (isPlaying)
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
              TajwidText(
                text: ayah.arab,
                fontSize: arabicFontSize,
                height: 1.8,
              ),
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
                      fontSize: translationFontSize,
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

class _AyahBottomSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
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

          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.download_rounded,
                  label: 'Download & Putar',
                  subtitle: 'Download dulu, putar offline',
                  color: const Color(0xFF6C63FF),
                  onTap: onPlayFromHere,
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

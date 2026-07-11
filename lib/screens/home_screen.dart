import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../services/quran_api.dart';
import 'surah_reader_screen.dart';
import 'settings_screen.dart';
import 'download_screen.dart';
import 'downloads_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final QuranApi _api = QuranApi();
  List<Surah>? _surahList;
  bool _loading = true;
  String? _error;
  bool _selectionMode = false;
  final Set<int> _selectedSurahs = {};
  bool _showWelcome = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.getSurahList();
      setState(() {
        _surahList = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data.\nPeriksa koneksi internet.';
        _loading = false;
      });
    }
  }

  void _toggleSelection(Surah surah) {
    setState(() {
      if (_selectedSurahs.contains(surah.id)) {
        _selectedSurahs.remove(surah.id);
      } else {
        _selectedSurahs.add(surah.id);
      }
    });
  }

  void _startDownload() {
    if (_selectedSurahs.isEmpty) return;
    final surahs =
        _surahList!.where((s) => _selectedSurahs.contains(s.id)).toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DownloadScreen(surahs: surahs)),
    ).then(
      (_) => setState(() {
        _selectionMode = false;
        _selectedSurahs.clear();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131420),
      appBar: _showWelcome
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF131420),
              elevation: 0,
              leading: _selectionMode
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() {
                        _selectionMode = false;
                        _selectedSurahs.clear();
                      }),
                    )
                  : null,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectionMode ? 'Pilih Surah' : 'Al-Qur\'an',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_selectionMode)
                    Text(
                      'Bacalah dengan nama Tuhanmu',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  if (_selectionMode)
                    Text(
                      '${_selectedSurahs.length} terpilih',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                ],
              ),
              actions: [
                if (!_selectionMode) ...[
                  IconButton(
                    icon: const Icon(Icons.download_done, color: Colors.white),
                    tooltip: 'Unduhan',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DownloadsScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_rounded, color: Colors.white),
                    tooltip: 'Pilih & Download',
                    onPressed: () => setState(() => _selectionMode = true),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
      body: _showWelcome ? _buildWelcome() : _buildBody(),
      bottomNavigationBar: _selectionMode && _selectedSurahs.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E2030),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _startDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Download ${_selectedSurahs.length} Surah'),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Color(0xFF2E7D32),
                size: 52,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Al-Qur\'an',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bacalah dengan nama Tuhanmu',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: () => setState(() => _showWelcome = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Masuk',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  Text(
                    'Audio oleh everyayah.com',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Data terjemahan oleh Quran.com API',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, color: Colors.red[300], size: 64),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final list = _surahList!;
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF2E7D32),
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: list.length,
              itemBuilder: (_, i) => _SurahCard(
                surah: list[i],
                selected: _selectedSurahs.contains(list[i].id),
                selectionMode: _selectionMode,
                onTap: _selectionMode
                    ? () => _toggleSelection(list[i])
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SurahReaderScreen(surahs: list, initialIndex: i),
                        ),
                      ),
                onLongPress: !_selectionMode
                    ? () => setState(() {
                        _selectionMode = true;
                        _selectedSurahs.add(list[i].id);
                      })
                    : null,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[800]!, width: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'everyayah.com',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SurahCard extends StatelessWidget {
  final Surah surah;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _SurahCard({
    required this.surah,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? const Color(0xFF1B3A1B) : const Color(0xFF222438),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? const BorderSide(color: Color(0xFF2E7D32), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected
                        ? const Color(0xFF2E7D32)
                        : Colors.grey[600],
                    size: 24,
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${surah.id}',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.nameSimple,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${surah.translatedName} \u2022 ${surah.versesCount} Ayat \u2022 ${surah.revelationPlace}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (!selectionMode)
                Text(
                  surah.nameArabic,
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

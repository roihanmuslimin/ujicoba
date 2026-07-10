import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/audio_service.dart';
import '../services/quran_api.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedQari = 7;
  double _arabicSize = 24;
  double _translationSize = 14;
  String _storagePath = '';
  bool _loading = true;
  late Map<int, String> _qariList;
  int? _previewQari;
  bool _previewPlaying = false;
  StreamSubscription? _previewSub;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _previewSub?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    _qariList = await SettingsService.getQariList();
    _selectedQari = await SettingsService.getQariId();
    _arabicSize = await SettingsService.getArabicFontSize();
    _translationSize = await SettingsService.getTranslationFontSize();
    _storagePath = await AudioService.instance.getDownloadDir();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _previewQariSample(int qariId) async {
    setState(() {
      _previewQari = qariId;
      _previewPlaying = true;
    });

    _previewSub?.cancel();
    _previewSub = AudioService.instance.stateStream.listen((s) {
      if (s == PlayState.stopped && mounted) {
        setState(() {
          _previewQari = null;
          _previewPlaying = false;
        });
      }
    });

    final api = QuranApi();
    String url = await api.getVerseAudioUrl(1, 1, qariId);
    if (url.isEmpty) url = SettingsService.sampleUrl(qariId);

    final ok = await AudioService.instance.playUrl(url);
    if (!ok && mounted) {
      setState(() {
        _previewQari = null;
        _previewPlaying = false;
      });
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
        title: const Text('Pengaturan', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionCard(
                  icon: Icons.person,
                  title: 'Qari / Pembaca',
                  child: _buildQariSelector(),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  icon: Icons.text_fields,
                  title: 'Ukuran Teks Arab',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '${_arabicSize.toInt()} pt',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          TajwidPreview(
                            text: 'بِسْمِ ٱللَّٰهِ',
                            size: _arabicSize,
                          ),
                        ],
                      ),
                      Slider(
                        value: _arabicSize,
                        min: 16,
                        max: 40,
                        divisions: 24,
                        activeColor: const Color(0xFF2E7D32),
                        inactiveColor: Colors.grey[700],
                        onChanged: (v) => setState(() => _arabicSize = v),
                        onChangeEnd: (v) =>
                            SettingsService.setArabicFontSize(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  icon: Icons.translate,
                  title: 'Ukuran Terjemahan',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '${_translationSize.toInt()} pt',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Dengan nama Allah',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: _translationSize,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _translationSize,
                        min: 10,
                        max: 28,
                        divisions: 18,
                        activeColor: const Color(0xFF2E7D32),
                        inactiveColor: Colors.grey[700],
                        onChanged: (v) => setState(() => _translationSize = v),
                        onChangeEnd: (v) =>
                            SettingsService.setTranslationFontSize(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  icon: Icons.folder,
                  title: 'Penyimpanan Audio',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _storagePath,
                      style: TextStyle(color: Colors.grey[300], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Folder audio offline',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    trailing: const Icon(
                      Icons.edit,
                      color: Color(0xFF2E7D32),
                      size: 20,
                    ),
                    onTap: _pickStorageFolder,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildQariSelector() {
    final entries = _qariList.entries.toList();
    return Column(
      children: List.generate(entries.length, (i) {
        final entry = entries[i];
        final isSelected = _selectedQari == entry.key;
        final isPreview = _previewQari == entry.key && _previewPlaying;
        final isLast = i == entries.length - 1;
        return Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                await SettingsService.setQariId(entry.key);
                setState(() => _selectedQari = entry.key);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFF2E7D32)
                            : Colors.grey[700],
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[300],
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isPreview
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_outline,
                        color: const Color(0xFF2E7D32),
                        size: 24,
                      ),
                      onPressed: () => _previewQariSample(entry.key),
                    ),
                  ],
                ),
              ),
            ),
            if (!isLast) Divider(height: 1, color: Colors.grey[800]),
          ],
        );
      }),
    );
  }

  Future<void> _pickStorageFolder() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2030),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Pilih Lokasi',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StorageOption(
              icon: Icons.phone_android,
              label: 'Penyimpanan Internal',
              subtitle: '/storage/emulated/0/quran_audio',
              onTap: () => Navigator.pop(ctx, 'internal'),
            ),
            const SizedBox(height: 8),
            _StorageOption(
              icon: Icons.sd_storage,
              label: 'SD Card',
              subtitle: '/storage/XXXX-XXXX/quran_audio',
              onTap: () => Navigator.pop(ctx, 'sdcard'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      String path;
      if (result == 'internal') {
        path = '/storage/emulated/0/quran_audio';
      } else {
        path = '/storage/0000-0000/quran_audio';
      }
      final dir = Directory(path);
      if (!await dir.exists()) await dir.create(recursive: true);
      await AudioService.instance.setDownloadDir(path);
      setState(() => _storagePath = path);
    }
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E2030),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF2E7D32), size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StorageOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _StorageOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF131420),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TajwidPreview extends StatelessWidget {
  final String text;
  final double size;
  const TajwidPreview({required this.text, required this.size});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: size, color: Colors.white),
    );
  }
}

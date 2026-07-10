import 'dart:io';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/audio_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedQari = 7;
  String _storagePath = '';
  bool _loading = true;
  late Map<int, String> _qariList;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _qariList = await SettingsService.getQariList();
    _selectedQari = await SettingsService.getQariId();
    _storagePath = await AudioService.instance.getDownloadDir();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickFolder() async {
    // On Android, we can use getExternalStorageDirectory
    // For simplicity, toggle between internal and SD card
    final current = await AudioService.instance.getDownloadDir();
    final newPath = current.contains('Android')
        ? '/storage/emulated/0/quran_audio'
        : (await AudioService.instance.getDownloadDir());
    await AudioService.instance.setDownloadDir(newPath);
    setState(() => _storagePath = newPath);
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
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionHeader(label: 'Qari / Pembaca'),
                const SizedBox(height: 8),
                ..._qariList.entries.map(
                  (entry) => _QariTile(
                    id: entry.key,
                    name: entry.value,
                    selected: _selectedQari == entry.key,
                    onTap: () async {
                      await SettingsService.setQariId(entry.key);
                      setState(() => _selectedQari = entry.key);
                    },
                  ),
                ),

                const SizedBox(height: 32),
                _SectionHeader(label: 'Penyimpanan Audio'),
                const SizedBox(height: 8),
                Card(
                  color: const Color(0xFF1E2030),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.folder, color: Color(0xFF6C63FF)),
                    title: Text(
                      _storagePath,
                      style: TextStyle(color: Colors.grey[300], fontSize: 13),
                    ),
                    subtitle: Text(
                      'Folder audio',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.grey),
                    onTap: () async {
                      final dirs = [
                        'Penyimpanan Internal',
                        'SD Card (Jika tersedia)',
                      ];
                      final result = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1E2030),
                          title: const Text(
                            'Pilih Lokasi',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: dirs
                                .map(
                                  (d) => ListTile(
                                    title: Text(
                                      d,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    leading: const Icon(
                                      Icons.storage,
                                      color: Color(0xFF6C63FF),
                                    ),
                                    onTap: () => Navigator.pop(ctx, d),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      );
                      if (result != null) {
                        final docDir = Directory(
                          '/storage/emulated/0/quran_audio',
                        );
                        if (!await docDir.exists()) {
                          await docDir.create(recursive: true);
                        }
                        await AudioService.instance.setDownloadDir(docDir.path);
                        setState(() => _storagePath = docDir.path);
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF6C63FF),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _QariTile extends StatelessWidget {
  final int id;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _QariTile({
    required this.id,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? const Color(0xFF2E3040) : const Color(0xFF1E2030),
      margin: const EdgeInsets.only(bottom: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: selected
            ? const BorderSide(color: Color(0xFF6C63FF), width: 1)
            : BorderSide.none,
      ),
      child: ListTile(
        title: Text(
          name,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[300],
            fontSize: 14,
          ),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle, color: Color(0xFF6C63FF), size: 20)
            : null,
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/surah.dart';
import 'surah_detail_screen.dart';

class SurahReaderScreen extends StatefulWidget {
  final List<Surah> surahs;
  final int initialIndex;
  const SurahReaderScreen({
    super.key,
    required this.surahs,
    required this.initialIndex,
  });

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  late PageController _pageCtrl;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
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
        title: GestureDetector(
          onTap: () => _showSurahPicker(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.surahs[_currentIndex].nameSimple,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: const Color(0xFF1A1C2A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentIndex > 0)
                  TextButton.icon(
                    onPressed: () => _pageCtrl.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF2E7D32),
                      size: 20,
                    ),
                    label: Text(
                      widget.surahs[_currentIndex - 1].nameSimple,
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  '${_currentIndex + 1} / ${widget.surahs.length}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                if (_currentIndex < widget.surahs.length - 1)
                  TextButton.icon(
                    onPressed: () => _pageCtrl.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                    label: Text(
                      widget.surahs[_currentIndex + 1].nameSimple,
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    icon: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF2E7D32),
                      size: 20,
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemCount: widget.surahs.length,
              itemBuilder: (_, i) => SurahDetailScreen(surah: widget.surahs[i]),
            ),
          ),
        ],
      ),
    );
  }

  void _showSurahPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2030),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: 400,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Daftar Surah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.surahs.length,
                itemBuilder: (_, i) {
                  final s = widget.surahs[i];
                  return ListTile(
                    selected: i == _currentIndex,
                    selectedTileColor: const Color(
                      0xFF2E7D32,
                    ).withValues(alpha: 0.15),
                    title: Text(
                      '${s.id}. ${s.nameSimple}',
                      style: TextStyle(
                        color: i == _currentIndex
                            ? const Color(0xFF2E7D32)
                            : Colors.white,
                        fontWeight: i == _currentIndex
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      s.translatedName,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    trailing: Text(
                      s.nameArabic,
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pageCtrl.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

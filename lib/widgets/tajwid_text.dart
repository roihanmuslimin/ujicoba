import 'package:flutter/material.dart';

class TajwidText extends StatelessWidget {
  final String text;
  final double fontSize;
  final double height;

  const TajwidText({
    super.key,
    required this.text,
    this.fontSize = 24,
    this.height = 1.8,
  });

  static const _maddColor = Color(0xFFE53935);
  static const _ghunnahColor = Color(0xFF43A047);
  static const _qalqalahColor = Color(0xFF1E88E5);
  static const _defaultColor = Colors.white;

  static const _arabicLetters =
      '\u0621\u0622\u0623\u0624\u0625\u0626\u0627'
      '\u0628\u0629\u062A\u062B\u062C\u062D\u062E\u062F\u0630'
      '\u0631\u0632\u0633\u0634\u0635\u0636\u0637\u0638\u0639'
      '\u063A\u0641\u0642\u0643\u0644\u0645\u0646\u0647\u0648\u064A';

  static const _fathah = '\u064E';
  static const _kasrah = '\u0650';
  static const _dammah = '\u064F';
  static const _sukun = '\u0652';
  static const _shaddah = '\u0651';
  static const _maddah = '\u0653';
  static const _alifMaddah = '\u0622';

  static const _qalqalahLetters = '\u0642\u0637\u0628\u062C\u062F';

  List<TextSpan> _parse() {
    if (text.isEmpty) return [const TextSpan(text: '')];

    List<_TajwidSegment> segments = [];
    int i = 0;

    while (i < text.length) {
      String ch = text[i];
      bool found = false;

      if (_isQalqalah(ch)) {
        String next = i + 1 < text.length ? text[i + 1] : '';
        if (next == _sukun) {
          segments.add(_TajwidSegment(ch, _qalqalahColor));
          segments.add(_TajwidSegment(next, _qalqalahColor));
          i += 2;
          found = true;
          continue;
        }
        if (i + 1 < text.length && _isShaddahWithSukun(text, i)) {
          segments.add(_TajwidSegment(ch, _qalqalahColor));
          i++;
          found = true;
          continue;
        }
      }

      if ((ch == '\u0646' || ch == '\u0645') && _hasShaddah(text, i)) {
        String seg = _collectWithDiacritics(text, i);
        segments.add(_TajwidSegment(seg, _ghunnahColor));
        i += seg.length;
        found = true;
        continue;
      }

      if (_isMaddLetter(ch)) {
        String prevDiac = i > 0 ? text[i - 1] : '';
        if (prevDiac == _fathah || prevDiac == _kasrah || prevDiac == _dammah) {
          String seg = _collectWithDiacritics(text, i);
          segments.add(_TajwidSegment(seg, _maddColor));
          i += seg.length;
          found = true;
          continue;
        }
      }

      if (ch == _alifMaddah) {
        String seg = _collectWithDiacritics(text, i);
        segments.add(_TajwidSegment(seg, _maddColor));
        i += seg.length;
        found = true;
        continue;
      }

      if (!found) {
        segments.add(_TajwidSegment(ch, _defaultColor));
        i++;
      }
    }

    return segments
        .map(
          (s) => TextSpan(
            text: s.text,
            style: TextStyle(color: s.color),
          ),
        )
        .toList();
  }

  bool _isArabicLetter(String ch) {
    return ch.codeUnitAt(0) >= 0x0621 && ch.codeUnitAt(0) <= 0x064A;
  }

  bool _isDiacritic(String ch) {
    int c = ch.codeUnitAt(0);
    return (c >= 0x064B && c <= 0x065F) || c == 0x0670;
  }

  bool _isQalqalah(String ch) {
    return _qalqalahLetters.contains(ch);
  }

  bool _isMaddLetter(String ch) {
    return ch == '\u0627' || ch == '\u0648' || ch == '\u064A';
  }

  bool _hasShaddah(String text, int index) {
    for (int j = index + 1; j < text.length; j++) {
      String ch = text[j];
      if (ch == _shaddah) return true;
      if (_isArabicLetter(ch)) return false;
    }
    return false;
  }

  bool _isShaddahWithSukun(String text, int index) {
    for (int j = index + 1; j < text.length; j++) {
      String ch = text[j];
      if (ch == _shaddah) {
        if (j + 1 < text.length && text[j + 1] == _sukun) return true;
        return false;
      }
      if (_isArabicLetter(ch)) return false;
    }
    return false;
  }

  String _collectWithDiacritics(String text, int start) {
    int end = start + 1;
    while (end < text.length && _isDiacritic(text[end])) {
      end++;
    }
    return text.substring(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: TextStyle(
          color: _defaultColor,
          fontSize: fontSize,
          height: height,
        ),
        children: _parse(),
      ),
    );
  }
}

class _TajwidSegment {
  final String text;
  final Color color;
  _TajwidSegment(this.text, this.color);
}

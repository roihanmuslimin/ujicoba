import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah.dart';
import '../models/ayah.dart';

class QuranApi {
  static const String _baseUrl = 'https://api.quran.com/api/v4';
  static const int _translationId = 33;

  static const List<String> _latinNames = [
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

  static const List<String> _transliterations = [
    '',
    'bismillāhir-raḥmānir-raḥīm',
    'al-ḥamdu lillāhi rabbil-\'ālamīn',
    'ar-raḥmānir-raḥīm',
    'māliki yaumid-dīn',
    'iyyāka na\'budu wa iyyāka nasta\'īn',
    'ihdinaṣ-ṣirāṭal-mustaqīm',
    'ṣirāṭallażīna an\'amta \'alaihim',
    'ġairil-magḍūbi \'alaihim wa laḍ-ḍāllīn',
  ];

  Future<List<Surah>> getSurahList() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/chapters?language=id'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat data (${response.statusCode})');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<dynamic> chapters = data['chapters'] ?? [];
    return chapters.map((json) => Surah.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getSurahDetail(
    int surahId, {
    int recitationId = 7,
  }) async {
    final response = await http
        .get(
          Uri.parse(
            '$_baseUrl/verses/by_chapter/$surahId?language=id&translations=$_translationId&fields=text_imlaei,text_uthmani&audio=$recitationId&limit=300',
          ),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat detail (${response.statusCode})');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<dynamic> verses = data['verses'] ?? [];

    final chaptersResp = await http
        .get(Uri.parse('$_baseUrl/chapters/$surahId?language=id'))
        .timeout(const Duration(seconds: 10));

    Surah surah;
    if (chaptersResp.statusCode == 200) {
      final chData = jsonDecode(chaptersResp.body)['chapter'];
      surah = Surah.fromJson(chData);
    } else {
      surah = Surah(
        id: surahId,
        nameSimple: _latinNames[surahId],
        nameArabic: '',
        versesCount: verses.length,
        revelationPlace: '',
        translatedName: '',
      );
    }

    final ayat = verses.map((v) {
      final audioPath = v['audio']?['url'] ?? '';
      final audioUrl = audioPath.isNotEmpty
          ? 'https://verses.quran.com/$audioPath'
          : '';

      final translations = v['translations'] ?? [];
      String translation = '';
      if (translations.isNotEmpty) {
        translation = (translations[0]['text'] ?? '') as String;
        translation = translation.replaceAll(RegExp(r'<[^>]*>'), '');
        translation = translation.replaceAll('&nbsp;', ' ').trim();
      }

      return Ayah(
        nomor: (v['verse_number'] ?? 0) as int,
        arab: (v['text_imlaei'] ?? v['text_uthmani'] ?? '') as String,
        latin: _getTransliteration(surahId, v['verse_number'] ?? 0),
        terjemahan: translation,
        audioUrl: audioUrl,
      );
    }).toList();

    return {'surah': surah, 'ayat': ayat};
  }

  String _getTransliteration(int surahId, int verseNum) {
    return '';
  }
}

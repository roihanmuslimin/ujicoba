import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _qariKey = 'qari_id';

  static Future<int> getQariId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_qariKey) ?? 7;
  }

  static Future<void> setQariId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_qariKey, id);
  }

  static Future<Map<int, String>> getQariList() async {
    return {
      7: 'Mishari Al-Afasy',
      3: 'Abdurrahman As-Sudais',
      4: 'Abu Bakr Ash-Shatri',
      5: 'Hani Ar-Rifai',
      2: 'Abdul Basit (Murattal)',
      1: 'Abdul Basit (Mujawwad)',
      8: "Sa'ud Ash-Shuraym",
      9: 'Yasser Ad-Dussary',
      12: 'Maher Al-Mu\'ayqili',
      13: 'Salah Al-Budair',
      14: 'Ali Al-Hudhaifi',
      15: 'Abdullah Al-Matrood',
      19: 'Husary',
      37: 'Muhammad Ayyoub',
      16: 'Ghamadi',
    };
  }

  static String getQariPath(int id) {
    switch (id) {
      case 7:  return 'Alafasy_128kbps';
      case 3:  return 'Abdurrahmaan_As-Sudais_192kbps';
      case 4:  return 'Abu_Bakr_Ash-Shaatree_128kbps';
      case 5:  return 'Hani_Rifai_192kbps';
      case 2:  return 'Abdul_Basit_Murattal_192kbps';
      case 1:  return 'Abdul_Basit_Mujawwad_128kbps';
      case 8:  return 'Saood_ash-Shuraym_128kbps';
      case 9:  return 'Yasser_Ad-Dussary_128kbps';
      case 12: return 'Maher_AlMuaiqly_128kbps';
      case 13: return 'Salah_Al_Budair_128kbps';
      case 14: return 'Hudhaify_128kbps';
      case 15: return 'Abdullah_Matroud_128kbps';
      case 19: return 'Husary_128kbps';
      case 37: return 'Muhammad_Ayyoub_128kbps';
      case 16: return 'Ghamadi_40kbps';
      default: return 'Alafasy_128kbps';
    }
  }

  static const _arabicSizeKey = 'font_size_arabic';
  static const _translationSizeKey = 'font_size_translation';

  static Future<double> getArabicFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_arabicSizeKey) ?? 24.0;
  }

  static Future<void> setArabicFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_arabicSizeKey, size);
  }

  static Future<double> getTranslationFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_translationSizeKey) ?? 14.0;
  }

  static Future<void> setTranslationFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_translationSizeKey, size);
  }

  static String audioUrl(int qariId, int surahNum, int ayahNum) {
    final path = getQariPath(qariId);
    final s = surahNum.toString().padLeft(3, '0');
    final a = ayahNum.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$path/$s$a.mp3';
  }

  static String sampleUrl(int qariId) {
    return audioUrl(qariId, 1, 1);
  }
}

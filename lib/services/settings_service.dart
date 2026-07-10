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
      7: 'Mishari Rashid Al-Afasy',
      3: 'Abdur-Rahman as-Sudais',
      4: 'Abu Bakr al-Shatri',
      5: 'Hani ar-Rifai',
      2: 'AbdulBaset AbdulSamad (Murattal)',
      1: 'AbdulBaset AbdulSamad (Mujawwad)',
      8: 'Sa\'ud ash-Shuraym',
      9: 'Yasser ad-Dussary',
      10: 'Muhammad al-Luhaidan',
      12: 'Maher al-Mu\'ayqili',
      13: 'Salah al-Budair',
      14: 'Ali al-Hudhaifi',
      15: 'Abdullah al-Matrood',
    };
  }

  static String getQariPath(int id) {
    switch (id) {
      case 7:
        return 'Alafasy';
      case 3:
        return 'sudais';
      case 4:
        return 'shatri';
      case 5:
        return 'Rifai';
      case 2:
        return 'abdul_baset';
      case 1:
        return 'abdul_baset_mujawwad';
      case 8:
        return 'shuraym';
      case 9:
        return 'dussary';
      case 10:
        return 'luhaidan';
      case 12:
        return 'muqayli';
      case 13:
        return 'budair';
      case 14:
        return 'hudhaifi';
      case 15:
        return 'matrood';
      default:
        return 'Alafasy';
    }
  }
}

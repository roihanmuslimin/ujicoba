import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah.dart';
import '../models/ayah.dart';

class QuranApi {
  static const String _baseUrl = 'https://equran.id/api';

  Future<List<Surah>> getSurahList() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/surat'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat data (${response.statusCode})');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Surah.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getSurahDetail(int nomor) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/surat/$nomor'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat detail (${response.statusCode})');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<dynamic> ayatList = data['ayat'] ?? [];
    final ayah = ayatList.map((json) => Ayah.fromJson(json)).toList();

    return {
      'surah': Surah.fromJson(data),
      'ayat': ayah,
    };
  }
}

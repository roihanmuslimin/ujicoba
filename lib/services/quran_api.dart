import 'package:dio/dio.dart';
import '../models/surah.dart';
import '../models/ayah.dart';

class QuranApi {
  static const String _baseUrl = 'https://equran.id/api';

  final Dio _dio;

  QuranApi() : _dio = Dio(BaseOptions(baseUrl: _baseUrl));

  Future<List<Surah>> getSurahList() async {
    final response = await _dio.get('/surat');
    final List<dynamic> data = response.data;
    return data.map((json) => Surah.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getSurahDetail(int nomor) async {
    final response = await _dio.get('/surat/$nomor');
    final data = response.data;
    final List<dynamic> ayatList = data['ayat'];
    final ayat = ayatList.map((json) => Ayah.fromJson(json)).toList();
    return {
      'surah': Surah.fromJson(data),
      'ayat': ayat,
    };
  }
}

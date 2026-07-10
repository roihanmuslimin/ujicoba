class Surah {
  final int id;
  final String nameSimple;
  final String nameArabic;
  final int versesCount;
  final String revelationPlace;
  final String translatedName;

  Surah({
    required this.id,
    required this.nameSimple,
    required this.nameArabic,
    required this.versesCount,
    required this.revelationPlace,
    required this.translatedName,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    final translated = json['translated_name'] ?? {};
    return Surah(
      id: (json['id'] ?? 0) as int,
      nameSimple: (json['name_simple'] ?? '') as String,
      nameArabic: (json['name_arabic'] ?? '') as String,
      versesCount: (json['verses_count'] ?? 0) as int,
      revelationPlace: (json['revelation_place'] ?? '') as String,
      translatedName: (translated['name'] ?? '') as String,
    );
  }
}

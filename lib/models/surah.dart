class Surah {
  final int nomor;
  final String nama;
  final String namaLatin;
  final int jumlahAyat;
  final String tempatTurun;
  final String arti;
  final String audioUrl;

  Surah({
    required this.nomor,
    required this.nama,
    required this.namaLatin,
    required this.jumlahAyat,
    required this.tempatTurun,
    required this.arti,
    required this.audioUrl,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      nomor: (json['nomor'] ?? 0) as int,
      nama: (json['nama'] ?? '') as String,
      namaLatin: (json['nama_latin'] ?? '') as String,
      jumlahAyat: (json['jumlah_ayat'] ?? 0) as int,
      tempatTurun: (json['tempat_turun'] ?? '') as String,
      arti: (json['arti'] ?? '') as String,
      audioUrl: (json['audio'] ?? '') as String,
    );
  }
}

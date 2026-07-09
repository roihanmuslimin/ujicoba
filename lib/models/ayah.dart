class Ayah {
  final int nomor;
  final String arab;
  final String latin;
  final String terjemahan;

  Ayah({
    required this.nomor,
    required this.arab,
    required this.latin,
    required this.terjemahan,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      nomor: (json['nomor'] ?? 0) as int,
      arab: (json['ar'] ?? '') as String,
      latin: (json['tr'] ?? '') as String,
      terjemahan: (json['idn'] ?? '') as String,
    );
  }
}

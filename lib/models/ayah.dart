class Ayah {
  final int nomor;
  final String arab;
  final String latin;
  final String terjemahan;
  final AudioInfo? audio;

  Ayah({
    required this.nomor,
    required this.arab,
    required this.latin,
    required this.terjemahan,
    this.audio,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      nomor: json['nomor'] ?? 0,
      arab: json['ar'] ?? '',
      latin: json['tr'] ?? '',
      terjemahan: json['idn'] ?? '',
      audio: json['audio'] != null
          ? AudioInfo.fromJson(json['audio'])
          : null,
    );
  }
}

class AudioInfo {
  final String? alafasy;
  final String? abdurrahmanAsSudais;
  final String? misharyAlafasy;
  final String? abuBakarAlShatri;

  AudioInfo({
    this.alafasy,
    this.abdurrahmanAsSudais,
    this.misharyAlafasy,
    this.abuBakarAlShatri,
  });

  factory AudioInfo.fromJson(Map<String, dynamic> json) {
    return AudioInfo(
      alafasy: json['01'] ?? json['alafasy'],
      abdurrahmanAsSudais: json['02'] ?? json['abdurrahman_as_sudais'],
      misharyAlafasy: json['03'] ?? json['mishary_alafasy'],
      abuBakarAlShatri: json['04'] ?? json['abu_bakar_al_shatri'],
    );
  }

  String? get primaryAudio => misharyAlafasy ?? alafasy ?? abdurrahmanAsSudais ?? abuBakarAlShatri;
}

part of 'main.dart';

class CropProfile {
  final String name;
  final String subtitle;
  final String description;
  final String icon;
  final double phMin;
  final double phMax;
  final List<String> textures;
  final List<String> moisture;
  final List<String> fertility;
  final List<String> drainage;
  final List<String> sunlight;
  final String tips;

  const CropProfile({
    required this.name,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.phMin,
    required this.phMax,
    required this.textures,
    required this.moisture,
    required this.fertility,
    required this.drainage,
    required this.sunlight,
    required this.tips,
  });
}

class CropMatch {
  final CropProfile crop;
  final int score;
  final List<String> matches;
  final List<String> cautions;

  const CropMatch({
    required this.crop,
    required this.score,
    required this.matches,
    required this.cautions,
  });

  String get grade {
    if (score >= 85) return uiText('S1 • Sangat sesuai');
    if (score >= 70) return uiText('S2 • Cukup sesuai');
    if (score >= 50) return uiText('S3 • Sesuai marginal');
    return uiText('N • Kurang sesuai');
  }
}

class AnalysisRecord {
  final DateTime createdAt;
  String landName;
  final double ph;
  final String texture;
  final String moisture;
  final String fertility;
  final String drainage;
  final String sunlight;
  final List<CropMatch> results;

  AnalysisRecord({
    required this.createdAt,
    required this.landName,
    required this.ph,
    required this.texture,
    required this.moisture,
    required this.fertility,
    required this.drainage,
    required this.sunlight,
    required this.results,
  });
}

const List<CropProfile> cropProfiles = [
  CropProfile(
    name: 'Jagung',
    subtitle: 'Pangan • serealia',
    description: 'Membutuhkan cahaya matahari cukup, air yang memadai, dan drainase yang baik.',
    icon: '🌽',
    phMin: 5.5,
    phMax: 7.0,
    textures: ['Lempung', 'Lempung berpasir'],
    moisture: ['Sedang'],
    fertility: ['Sedang', 'Tinggi'],
    drainage: ['Baik', 'Sedang'],
    sunlight: ['Matahari penuh'],
    tips: 'Pastikan air tersedia selama pertumbuhan. Hindari lahan yang tergenang lama dan periksa kebutuhan pupuk berdasarkan kondisi tanah.',
  ),
  CropProfile(
    name: 'Padi',
    subtitle: 'Pangan • serealia',
    description: 'Kebutuhan airnya relatif tinggi, terutama untuk sistem budidaya padi sawah.',
    icon: '🌾',
    phMin: 5.0,
    phMax: 7.0,
    textures: ['Lempung', 'Liat'],
    moisture: ['Basah'],
    fertility: ['Sedang', 'Tinggi'],
    drainage: ['Sedang', 'Buruk'],
    sunlight: ['Matahari penuh'],
    tips: 'Rekomendasi ini paling relevan untuk konteks padi sawah. Jenis padi, sistem sawah, ketersediaan air, dan kondisi drainase tetap perlu diperiksa.',
  ),
  CropProfile(
    name: 'Cabai',
    subtitle: 'Hortikultura • buah',
    description: 'Umumnya lebih sesuai pada tanah yang gembur, cukup subur, dan tidak tergenang.',
    icon: '🌶️',
    phMin: 5.5,
    phMax: 6.8,
    textures: ['Lempung', 'Lempung berpasir'],
    moisture: ['Sedang'],
    fertility: ['Sedang', 'Tinggi'],
    drainage: ['Baik'],
    sunlight: ['Matahari penuh'],
    tips: 'Jaga kelembapan tetap cukup tanpa membuat tanah jenuh air. Perhatikan varietas, musim, serta risiko penyakit tanaman.',
  ),
  CropProfile(
    name: 'Kedelai',
    subtitle: 'Pangan • legum',
    description: 'Cocok dipertimbangkan pada tanah gembur dengan kelembapan memadai dan drainase yang baik.',
    icon: '🫘',
    phMin: 5.5,
    phMax: 7.0,
    textures: ['Lempung', 'Lempung berpasir'],
    moisture: ['Sedang'],
    fertility: ['Sedang', 'Tinggi'],
    drainage: ['Baik', 'Sedang'],
    sunlight: ['Matahari penuh'],
    tips: 'Perhatikan drainase dan kondisi air pada fase berbunga serta pengisian polong. Data varietas lokal dapat mengubah tingkat kesesuaian.',
  ),
  CropProfile(
    name: 'Singkong',
    subtitle: 'Pangan • umbi',
    description: 'Relatif toleran terhadap kondisi lebih kering, tetapi tetap memerlukan lahan yang sesuai dan tidak mudah tergenang.',
    icon: '🥔',
    phMin: 5.0,
    phMax: 7.5,
    textures: ['Pasir', 'Lempung berpasir', 'Lempung'],
    moisture: ['Kering', 'Sedang'],
    fertility: ['Rendah', 'Sedang'],
    drainage: ['Baik', 'Sedang'],
    sunlight: ['Matahari penuh'],
    tips: 'Hindari tanah tergenang dan periksa kedalaman tanah, varietas, serta kondisi musim sebelum menentukan penanaman.',
  ),
  CropProfile(
    name: 'Tomat',
    subtitle: 'Hortikultura • buah',
    description: 'Membutuhkan cahaya cukup, kelembapan relatif stabil, dan tanah dengan drainase baik.',
    icon: '🍅',
    phMin: 5.5,
    phMax: 7.0,
    textures: ['Lempung', 'Lempung berpasir'],
    moisture: ['Sedang'],
    fertility: ['Sedang', 'Tinggi'],
    drainage: ['Baik'],
    sunlight: ['Matahari penuh'],
    tips: 'Hindari genangan dan perubahan kelembapan yang ekstrem. Pastikan dukungan ajir, nutrisi, dan pengendalian penyakit tersedia.',
  ),
  CropProfile(
    name: 'Kacang tanah',
    subtitle: 'Pangan • legum',
    description: 'Umumnya membutuhkan tanah gembur yang memudahkan pembentukan dan pengembangan polong.',
    icon: '🥜',
    phMin: 5.5,
    phMax: 7.0,
    textures: ['Pasir', 'Lempung berpasir'],
    moisture: ['Kering', 'Sedang'],
    fertility: ['Rendah', 'Sedang'],
    drainage: ['Baik'],
    sunlight: ['Matahari penuh'],
    tips: 'Periksa tekstur dan kegemburan lapisan tanah, karena polong berkembang di dalam tanah. Hindari genangan berkepanjangan.',
  ),
  CropProfile(
    name: 'Bayam',
    subtitle: 'Hortikultura • sayuran daun',
    description: 'Pertimbangkan tanah yang cukup subur dengan kelembapan yang memadai.',
    icon: '🥬',
    phMin: 6.0,
    phMax: 7.5,
    textures: ['Lempung', 'Lempung berpasir'],
    moisture: ['Sedang', 'Basah'],
    fertility: ['Sedang', 'Tinggi'],
    drainage: ['Baik', 'Sedang'],
    sunlight: ['Matahari penuh', 'Matahari sebagian'],
    tips: 'Jaga pasokan air dan unsur hara. Gunakan rentang pH sebagai penyaringan awal, bukan satu-satunya dasar keputusan.',
  ),
];

class LandRecord {
  String name;
  String location;
  double? areaSqm;
  String notes;
  double? ph;
  String texture;
  String moisture;
  String fertility;
  String drainage;
  String sunlight;
  String? crop;
  DateTime updatedAt;

  LandRecord({
    required this.name,
    this.location = '',
    this.areaSqm,
    this.notes = '',
    this.ph,
    this.texture = 'Belum dicatat',
    this.moisture = 'Belum dicatat',
    this.fertility = 'Belum dicatat',
    this.drainage = 'Belum dicatat',
    this.sunlight = 'Belum dicatat',
    this.crop,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();
}

class IrrigationLog {
  final DateTime date;
  final String landName;
  final String crop;
  final String moistureBefore;
  final double? amountLiters;
  final String note;

  const IrrigationLog({
    required this.date,
    required this.landName,
    required this.crop,
    required this.moistureBefore,
    required this.amountLiters,
    required this.note,
  });
}

class IrrigationPlan {
  String landName;
  final DateTime date;
  final String note;
  bool completed;

  IrrigationPlan({
    required this.landName,
    required this.date,
    required this.note,
    this.completed = false,
  });
}


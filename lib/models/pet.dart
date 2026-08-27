

/// 宠物模型
class Pet {
  final String id;
  final String name;
  final PetSpecies species;
  final String breed;
  final PetGender gender;
  final int ageYears;
  final double weight;
  final DateTime birthDate;
  final String? avatarUrl;
  final List<String> allergies;
  final List<String> chronicConditions;
  final bool isNeutered;
  final bool isVaccinated;
  final String? emergencyContact;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.gender,
    required this.ageYears,
    required this.weight,
    required this.birthDate,
    this.avatarUrl,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.isNeutered = false,
    this.isVaccinated = false,
    this.emergencyContact,
  });

  int get recommendedExerciseMinutes {
    if (species == PetSpecies.cat) {
      return 15 + (ageYears < 2 ? 15 : (ageYears > 7 ? -5 : 0));
    }
    if (breed.contains('柯基') || breed.contains('法斗') || breed.contains('吉娃娃')) {
      return ageYears < 1 ? 20 : (ageYears > 8 ? 15 : 30);
    }
    if (breed.contains('金毛') || breed.contains('拉布拉多') || breed.contains('边牧')) {
      return ageYears < 1 ? 40 : (ageYears > 8 ? 30 : 60);
    }
    return ageYears < 1 ? 25 : (ageYears > 8 ? 20 : 40);
  }

  String get speciesEmoji => species == PetSpecies.dog ? '🐕' : '🐈';
  String get genderText => gender == PetGender.male ? '公' : '母';

  /// 年龄文本（如 "3岁" 或 "6个月"）
  String get age {
    final now = DateTime.now();
    final years = now.year - birthDate.year;
    if (years < 1) {
      final months = now.month - birthDate.month + (now.day < birthDate.day ? -1 : 0);
      return '${months < 1 ? 1 : months}个月';
    }
    return '$years岁';
  }

  /// 疫苗接种记录
  List<String> get vaccinations => isVaccinated ? ['狂犬疫苗', '犬瘟热疫苗', '细小病毒疫苗'] : [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'species': species.index,
    'breed': breed,
    'gender': gender.index,
    'ageYears': ageYears,
    'weight': weight,
    'birthDate': birthDate.toIso8601String(),
    'avatarUrl': avatarUrl,
    'allergies': allergies,
    'chronicConditions': chronicConditions,
    'isNeutered': isNeutered,
    'isVaccinated': isVaccinated,
    'emergencyContact': emergencyContact,
  };

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
    id: json['id'] as String,
    name: json['name'] as String,
    species: PetSpecies.values[json['species'] as int? ?? 0],
    breed: json['breed'] as String? ?? '',
    gender: PetGender.values[json['gender'] as int? ?? 0],
    ageYears: json['ageYears'] as int? ?? 0,
    weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
    birthDate: DateTime.parse(json['birthDate'] as String),
    avatarUrl: json['avatarUrl'] as String?,
    allergies: (json['allergies'] as List<dynamic>?)?.cast<String>() ?? [],
    chronicConditions: (json['chronicConditions'] as List<dynamic>?)?.cast<String>() ?? [],
    isNeutered: json['isNeutered'] as bool? ?? false,
    isVaccinated: json['isVaccinated'] as bool? ?? false,
    emergencyContact: json['emergencyContact'] as String?,
  );
}

enum PetSpecies { dog, cat }
enum PetGender { male, female }

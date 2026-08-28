import '../pet.dart';
import 'wire_enums.dart';

/// 服务端 PetDTO ↔ 本地 Pet 转换（契约 §3 PetDTO / §4.4）。
///
/// - 枚举走字符串（dog/cat、male/female），未知值宽容降级；
/// - birthDate 为 `yyyy-MM-dd` 日期串（DateTime.tryParse 按本地时区解析）；
/// - `recommendedExerciseMinutes` 由服务端下发、本地 getter 同公式推导，
///   转换层刻意**忽略线上值**，避免两侧各存一份真相（契约 §3 注释）。
class PetDto {
  const PetDto._();

  static Pet fromWire(Map<String, dynamic> j) => Pet(
        id: (j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        species: speciesFromWire('${j['species'] ?? 'dog'}'),
        breed: (j['breed'] ?? '') as String,
        gender: genderFromWire('${j['gender'] ?? 'male'}'),
        ageYears: _asInt(j['ageYears']) ?? 0,
        weight: _asDouble(j['weight']) ?? 0,
        birthDate:
            DateTime.tryParse('${j['birthDate'] ?? ''}') ?? DateTime.now(),
        avatarUrl: j['avatarUrl'] as String?,
        allergies: _strList(j['allergies']),
        chronicConditions: _strList(j['chronicConditions']),
        isNeutered: j['isNeutered'] as bool? ?? false,
        isVaccinated: j['isVaccinated'] as bool? ?? false,
        emergencyContact: j['emergencyContact'] as String?,
      );

  /// 可写字段集（POST 全量必填校验在服务端；PATCH 均可选）。
  /// 不含 id / createdAt / recommendedExerciseMinutes。
  static Map<String, dynamic> toWire(Pet p) => {
        'name': p.name,
        'species': speciesToWire(p.species),
        'breed': p.breed,
        'gender': genderToWire(p.gender),
        'ageYears': p.ageYears,
        'birthDate': _dateOnly(p.birthDate),
        'weight': p.weight,
        'avatarUrl': p.avatarUrl,
        'allergies': p.allergies,
        'chronicConditions': p.chronicConditions,
        'isNeutered': p.isNeutered,
        'isVaccinated': p.isVaccinated,
        'emergencyContact': p.emergencyContact,
      };

  static String _dateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}'
      '-${d.day.toString().padLeft(2, '0')}';

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}');
  }

  static double? _asDouble(Object? v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}');
  }

  static List<String> _strList(Object? v) => v is List
      ? v.map((e) => '$e').where((s) => s.isNotEmpty).toList()
      : const [];
}

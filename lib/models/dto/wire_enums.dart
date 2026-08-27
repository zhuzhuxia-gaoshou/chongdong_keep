import '../exercise_record.dart' show ExerciseType;
import '../pet.dart' show PetGender, PetSpecies;

/// 契约线上的字符串枚举 ↔ Dart 枚举映射（契约 4.4）。
///
/// 解析方向对未知值**宽容降级**到默认项，绝不抛异常——
/// 保证服务端未来新增枚举值时旧版本 APP 不至于崩溃。
/// M2–M4 的 PetDto/RecordDto 将直接复用本文件。

PetSpecies speciesFromWire(String v) =>
    v == 'cat' ? PetSpecies.cat : PetSpecies.dog;

String speciesToWire(PetSpecies s) => s == PetSpecies.cat ? 'cat' : 'dog';

PetGender genderFromWire(String v) =>
    v == 'female' ? PetGender.female : PetGender.male;

String genderToWire(PetGender g) => g == PetGender.female ? 'female' : 'male';

ExerciseType exerciseTypeFromWire(String v) =>
    v == 'catPlay' ? ExerciseType.catPlay : ExerciseType.walkDog;

String exerciseTypeToWire(ExerciseType t) =>
    t == ExerciseType.catPlay ? 'catPlay' : 'walkDog';

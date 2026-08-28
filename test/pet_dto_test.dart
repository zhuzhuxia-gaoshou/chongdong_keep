import 'package:chongdong_keep/models/dto/pet_dto.dart';
import 'package:chongdong_keep/models/pet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PetDto.fromWire', () {
    test('完整线上结构 → 本地模型：字符串枚举/日期/派生字段忽略', () {
      final pet = PetDto.fromWire({
        'id': 'p_1001',
        'name': '可乐',
        'species': 'dog',
        'breed': '金毛',
        'gender': 'male',
        'ageYears': 3,
        'birthDate': '2023-05-01',
        'weight': 28.5,
        'avatarUrl': null,
        'allergies': ['鸡肉'],
        'chronicConditions': <String>[],
        'isNeutered': false,
        'isVaccinated': true,
        'emergencyContact': null,
        // 服务端下发的派生字段刻意忽略，本地 getter 同公式推导
        'recommendedExerciseMinutes': 999,
      });
      expect(pet.id, 'p_1001');
      expect(pet.species, PetSpecies.dog);
      expect(pet.gender, PetGender.male);
      expect(pet.birthDate.year, 2023);
      expect(pet.birthDate.month, 5);
      expect(pet.weight, 28.5);
      expect(pet.allergies, ['鸡肉']);
      expect(pet.isVaccinated, isTrue);
      expect(pet.recommendedExerciseMinutes, 60); // 金毛·3岁 → 60，非线上 999
    });

    test('未知枚举/脏数值宽容降级，绝不抛异常', () {
      final pet = PetDto.fromWire({
        'id': 'p_x',
        'name': '咪咪',
        'species': 'parrot', // 未来新枚举
        'gender': 'unknown',
        'weight': '4.2', // 字符串数字
        'ageYears': '2',
        'birthDate': '',
        'allergies': null,
      });
      expect(pet.species, PetSpecies.dog); // 未知物种降级（名称保留）
      expect(pet.name, '咪咪');
      expect(pet.gender, PetGender.male);
      expect(pet.weight, 4.2);
      expect(pet.ageYears, 2);
      expect(pet.birthDate.year, greaterThan(2000)); // 兜底当前时间
      expect(pet.allergies, isEmpty);
    });
  });

  group('PetDto.toWire', () {
    test('枚举转字符串、birthDate 为 yyyy-MM-dd、不含 id', () {
      final wire = PetDto.toWire(Pet(
        id: 'pet_local_tmp_123',
        name: '豆豆',
        species: PetSpecies.cat,
        breed: '狸花猫',
        gender: PetGender.female,
        ageYears: 1,
        weight: 3.8,
        birthDate: DateTime(2025, 3, 9),
      ));
      expect(wire.containsKey('id'), isFalse);
      expect(wire['species'], 'cat');
      expect(wire['gender'], 'female');
      expect(wire['birthDate'], '2025-03-09');
      expect(wire['weight'], 3.8);
      expect(wire['allergies'], <String>[]);
    });

    test('往返保真：toWire → fromWire 关键字段无损', () {
      final original = Pet(
        id: 'p_9',
        name: '旺财',
        species: PetSpecies.dog,
        breed: '边牧',
        gender: PetGender.male,
        ageYears: 4,
        weight: 19.25,
        birthDate: DateTime(2022, 11, 2),
        allergies: const ['牛肉'],
        chronicConditions: const ['髋关节'],
        isNeutered: true,
        emergencyContact: '13800000000',
      );
      final back = PetDto.fromWire(PetDto.toWire(original));
      expect(back.id, ''); // toWire 不带 id，归属以服务端回包为准
      expect(back.name, original.name);
      expect(back.species, original.species);
      expect(back.gender, original.gender);
      expect(back.weight, original.weight);
      expect(back.birthDate.day, 2);
      expect(back.allergies, ['牛肉']);
      expect(back.chronicConditions, ['髋关节']);
      expect(back.isNeutered, isTrue);
      expect(back.emergencyContact, '13800000000');
    });
  });
}
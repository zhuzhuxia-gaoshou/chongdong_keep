import 'package:flutter_test/flutter_test.dart';
import 'package:chongdong_keep/models/dto/wire_enums.dart';
import 'package:chongdong_keep/models/exercise_record.dart';
import 'package:chongdong_keep/models/pet.dart';

void main() {
  test('物种 dog/cat 双向映射', () {
    expect(speciesToWire(PetSpecies.dog), 'dog');
    expect(speciesToWire(PetSpecies.cat), 'cat');
    expect(speciesFromWire('dog'), PetSpecies.dog);
    expect(speciesFromWire('cat'), PetSpecies.cat);
  });

  test('性别 male/female 双向映射', () {
    expect(genderToWire(PetGender.male), 'male');
    expect(genderToWire(PetGender.female), 'female');
    expect(genderFromWire('female'), PetGender.female);
  });

  test('运动类型 walkDog/catPlay 双向映射', () {
    expect(exerciseTypeToWire(ExerciseType.walkDog), 'walkDog');
    expect(exerciseTypeFromWire('catPlay'), ExerciseType.catPlay);
  });

  test('未知值宽容降级，绝不抛异常（前向兼容）', () {
    expect(speciesFromWire('hamster'), PetSpecies.dog);
    expect(genderFromWire('unknown'), PetGender.male);
    expect(exerciseTypeFromWire('swim'), ExerciseType.walkDog);
  });
}

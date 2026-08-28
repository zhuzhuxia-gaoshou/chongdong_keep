import 'package:chongdong_keep/models/pet.dart';
import 'package:chongdong_keep/network/api_client.dart';
import 'package:chongdong_keep/network/api_exception.dart';
import 'package:chongdong_keep/network/token_store.dart';
import 'package:chongdong_keep/repositories/auth_repository.dart';
import 'package:chongdong_keep/repositories/pet_repository.dart';
import 'package:chongdong_keep/services/mock/mock_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ApiClient, TokenStore, MockTransport)> _stack() async {
  SharedPreferences.setMockInitialValues({});
  final store = TokenStore(prefs: SharedPreferences.getInstance());
  final transport = MockTransport(delay: Duration.zero);
  return (ApiClient(transport, store), store, transport);
}

Future<void> _loginAs(ApiClient client, TokenStore store, String phone) async {
  final auth = AuthRepository(client, store);
  await auth.sendSmsCode(phone);
  await auth.login(phone, MockTransport.fixedSmsCode);
}

Pet _draft({String name = '团子', String breed = '泰迪', double weight = 6.0}) =>
    Pet(
      id: 'local_tmp', // 客户端临时 id，服务端应忽略并下发自己的 p_ id
      name: name,
      species: PetSpecies.dog,
      breed: breed,
      gender: PetGender.male,
      ageYears: 2,
      weight: weight,
      birthDate: DateTime(2024, 1, 15),
    );

void main() {
  test('未登录拉宠物 → 匿名 40101 原样上抛（不触发刷新/登出）', () async {
    final (client, _, _) = await _stack();
    await expectLater(
      PetRepository(client).fetchPets(),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', kCodeAccessExpired)),
    );
  });

  test('种子列表正序 + 新增走服务端 id + 编辑回包 + 软删后不可见', () async {
    final (client, store, _) = await _stack();
    final pets = PetRepository(client);
    await _loginAs(client, store, '13800008000');

    final seeded = await pets.fetchPets();
    expect(seeded.map((p) => p.name), ['可乐', '咪咪']); // 创建时间正序
    expect(seeded.first.recommendedExerciseMinutes, 60); // 金毛·3岁

    // 新增：客户端临时 id 被服务端 id 取代
    final created = await pets.createPet(_draft());
    expect(created.id, startsWith('p_'));
    expect(created.id, isNot('local_tmp'));
    expect((await pets.fetchPets()).length, 3);

    // 编辑：体重+绝育，派生字段随品种/年龄公式重算
    final patched = await pets.patchPet(
        created.copyWithSafe(weight: 7.5, isNeutered: true));
    expect(patched.weight, 7.5);
    expect(patched.isNeutered, isTrue);
    expect(patched.id, created.id);

    // 软删：列表不再出现，详情 40401（信封码，不经仓库解包）
    await pets.deletePet(patched.id);
    expect((await pets.fetchPets()).map((p) => p.id), isNot(contains(patched.id)));
    final detail = await client.get('/api/v1/pets/${patched.id}');
    expect(detail['code'], kCodePetNotFound);
  });

  test('校验与配额：体重≤0 → 40001；名称空 → 40001；第 21 只 → 40003', () async {
    final (client, store, _) = await _stack();
    final pets = PetRepository(client);
    await _loginAs(client, store, '13712345678'); // 新用户，空宠物

    expect(await pets.fetchPets(), isEmpty);
    await expectLater(
      pets.createPet(_draft(weight: 0)),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', kCodeParamInvalid)),
    );
    await expectLater(
      pets.createPet(_draft(name: '   ')),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', kCodeParamInvalid)),
    );
    for (var i = 0; i < 20; i++) {
      await pets.createPet(_draft(name: '狗$i'));
    }
    await expectLater(
      pets.createPet(_draft(name: '超限狗')),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', kCodePetLimit)),
    );
  });

  test('归属：B 用户 PATCH/DELETE A 用户的宠物 → 40301，数据不被篡改', () async {
    final (client, store, _) = await _stack();
    final pets = PetRepository(client);
    await _loginAs(client, store, '13800008000');
    final mine = (await pets.fetchPets()).first;

    // 同一 client 切换到另一账号
    await _loginAs(client, store, '13900009000');
    await expectLater(
      pets.patchPet(mine.copyWithSafe(name: '被偷改')),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', kCodeNotOwner)),
    );
    await expectLater(
      pets.deletePet(mine.id),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', kCodeNotOwner)),
    );
  });
}

/// 测试专用迷你 copyWith（Pet 本体刻意不可变且不预置该 API）。
extension PetTestPatch on Pet {
  Pet copyWithSafe({String? name, double? weight, bool? isNeutered}) => Pet(
        id: id,
        name: name ?? this.name,
        species: species,
        breed: breed,
        gender: gender,
        ageYears: ageYears,
        weight: weight ?? this.weight,
        birthDate: birthDate,
        avatarUrl: avatarUrl,
        allergies: allergies,
        chronicConditions: chronicConditions,
        isNeutered: isNeutered ?? this.isNeutered,
        isVaccinated: isVaccinated,
        emergencyContact: emergencyContact,
      );
}
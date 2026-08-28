import '../models/dto/pet_dto.dart';
import '../models/pet.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

/// 宠物域门面（契约 §4.4 ⑧–⑫）。
///
/// 写操作一律以**服务端回包为准**（服务端负责 id/createdAt/派生字段），
/// 网络与业务异常原样上抛，由调用方决定兜底文案。
class PetRepository {
  PetRepository(this._client);

  final ApiClient _client;

  /// 列表：创建时间正序（契约 §4.4）。
  Future<List<Pet>> fetchPets() async {
    final data = unwrapEnvelope(await _client.get('/api/v1/pets'));
    final list = (data['list'] as List?) ?? const [];
    return list
        .map((e) => PetDto.fromWire(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 新增：客户端临时 id 不参与线上协议，返回的 Pet 携带服务端 id。
  Future<Pet> createPet(Pet pet) async => PetDto.fromWire(
      unwrapEnvelope(
          await _client.post('/api/v1/pets', body: PetDto.toWire(pet))));

  Future<Pet> patchPet(Pet pet) async => PetDto.fromWire(unwrapEnvelope(
      await _client.patch('/api/v1/pets/${Uri.encodeComponent(pet.id)}',
          body: PetDto.toWire(pet))));

  Future<void> deletePet(String petId) async {
    unwrapEnvelope(
        await _client.delete('/api/v1/pets/${Uri.encodeComponent(petId)}'));
  }
}
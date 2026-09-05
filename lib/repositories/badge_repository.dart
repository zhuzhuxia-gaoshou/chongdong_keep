import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../models/dto/badge_dto.dart';

/// 徽章仓库（契约 §4.10 ㉓）。GET 时服务端惰性评估解锁事件。
class BadgeRepository {
  BadgeRepository(this._client);

  final ApiClient _client;

  Future<BadgeResult> fetchBadges() async {
    final data = unwrapEnvelope(await _client.get('/api/v1/badges'));
    return BadgeResult.fromWire(data);
  }
}

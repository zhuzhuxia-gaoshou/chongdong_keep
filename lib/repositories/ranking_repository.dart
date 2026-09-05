import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../models/dto/ranking_dto.dart';

/// 排行榜仓库（契约 §4.9 ㉒）。scope v0.1 仅 all。
class RankingRepository {
  RankingRepository(this._client);

  final ApiClient _client;

  /// [type] weekly（滚动近 7 天）| monthly（自然月）
  Future<RankingResult> fetchRanking({String type = 'weekly'}) async {
    final data = unwrapEnvelope(await _client
        .get('/api/v1/ranking', query: {'type': type, 'scope': 'all'}));
    return RankingResult.fromWire(data);
  }
}

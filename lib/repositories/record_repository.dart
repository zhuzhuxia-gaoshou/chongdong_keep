import '../models/dto/record_dto.dart';
import '../models/dto/wire_enums.dart';
import '../models/exercise_record.dart';
import '../models/user.dart' show CheckInRecord;
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../utils/iso_time.dart';

/// 运动记录 + 打卡域门面（契约 §4.6 ⑭⑮ / §4.7 ⑰）。
///
/// ⑭ 上报以 `clientRecordId` 为幂等键：同一记录弱网重试不会变两条；
/// ⑮ 列表回包的 route 已被服务端抽稀，全量轨迹属 ⑯（P0 后按需接）。
class RecordRepository {
  RecordRepository(this._client);

  final ApiClient _client;

  /// 上报一条记录，返回服务端权威回包（含服务端 id / 回显 clientRecordId）。
  ///
  /// 注意：本地 startPhotoPath（设备文件路径）不在 DTO 往返中，
  /// 调用方负责用 [ExerciseRecord.copyWith] 把它贴回结果。
  Future<ExerciseRecord> createRecord(ExerciseRecord local) async {
    final data = unwrapEnvelope(await _client
        .post('/api/v1/exercise-records', body: RecordDto.toWire(local)));
    return RecordDto.fromWire(data);
  }

  /// 分页查询（startTime 倒序）；日期闭区间按东八区，仅传日期部分。
  Future<List<ExerciseRecord>> fetchRecords({
    String? petId,
    ExerciseType? type,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (petId != null) 'petId': petId,
      if (type != null) 'type': exerciseTypeToWire(type),
      if (startDate != null) 'startDate': _dateOnly(startDate),
      if (endDate != null) 'endDate': _dateOnly(endDate),
    };
    final data = unwrapEnvelope(
        await _client.get('/api/v1/exercise-records', query: query));
    final list = (data['list'] as List?) ?? const [];
    return list
        .map((e) => RecordDto.fromWire(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 月历打卡（服务端判定：walkDog && isCompleted && duration≥300s）。
  Future<List<CheckInRecord>> fetchCalendar(int year, int month) async {
    final data = unwrapEnvelope(await _client.get(
      '/api/v1/checkins/calendar',
      query: {'year': '$year', 'month': '$month'},
    ));
    final days = (data['days'] as List?) ?? const [];
    return days.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final date =
          tryParseIsoWithOffset(m['date'] as String?) ?? DateTime(year, month);
      return CheckInRecord(date: date, isChecked: m['isChecked'] as bool? ?? false);
    }).toList();
  }

  static String _dateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}'
      '-${d.day.toString().padLeft(2, '0')}';
}

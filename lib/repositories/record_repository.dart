import 'package:image_picker/image_picker.dart';

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

  static const int _walkPhotoMaxBytes = 1 * 1024 * 1024; // 契约 ⑬ walkPhoto 上限

  /// 上报一条记录，返回服务端权威回包（含服务端 id / 回显 clientRecordId）。
  ///
  /// [startPhotoUrl]：图床 URL（由调用方先经 [uploadWalkPhoto] 拿到）。
  /// 注意：本地 startPhotoPath（设备文件路径）不在 DTO 往返中，
  /// 调用方负责用 [ExerciseRecord.copyWith] 把它贴回结果。
  Future<ExerciseRecord> createRecord(ExerciseRecord local,
      {String? startPhotoUrl}) async {
    final data = unwrapEnvelope(await _client.post('/api/v1/exercise-records',
        body: RecordDto.toWire(local, startPhotoUrl: startPhotoUrl)));
    return RecordDto.fromWire(data);
  }

  /// 出发照片上传（契约 §4.5 ⑬，businessType=walkPhoto，服务端上限 1MB）。
  /// 文件读取失败或格式不符抛 ApiException；调用方对照片失败应静默降级，
  /// 不阻塞运动记录上报。
  Future<String> uploadWalkPhoto(String path) async {
    final xfile = XFile(path);
    var ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';
    const allowed = {'jpg', 'jpeg', 'png', 'webp'};
    if (!allowed.contains(ext)) {
      // 无扩展名/临时地址（如 web 的 blob:）按 mimeType 兜底推断
      ext = switch (xfile.mimeType) {
        'image/jpeg' || 'image/jpg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
        _ => '',
      };
    }
    if (!allowed.contains(ext)) {
      throw ApiException(kCodeUploadType, '仅支持 JPG/PNG/WebP 图片');
    }
    final bytes = await xfile.readAsBytes();
    if (bytes.length > _walkPhotoMaxBytes) {
      throw ApiException(kCodeUploadSize, '照片大小超出 1MB 限制');
    }
    final data = unwrapEnvelope(await _client.upload('/api/v1/upload',
        bytes: bytes, filename: 'walk_photo.$ext',
        fields: {'businessType': 'walkPhoto'}));
    return data['url'] as String;
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

  /// ⑱ 今日打卡状态（服务端判定）
  Future<({bool isChecked, int todayMinutes})> fetchTodayStatus() async {
    final data =
        unwrapEnvelope(await _client.get('/api/v1/checkins/today'));
    return (
      isChecked: data['isChecked'] as bool? ?? false,
      todayMinutes: (data['todayMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  /// ⑲ 补签：服务端扣补签卡并写 makeup_checkins，返回新的剩余卡数。
  /// 错误：40305 卡不足 / 40004 该日已打卡或无需补签 / 40001 日期非法。
  Future<int> makeUpCheckin(DateTime date) async {
    final data = unwrapEnvelope(
        await _client.post('/api/v1/checkins/makeup', body: {
      'date': _dateOnly(date),
    }));
    return (data['signCardCount'] as num?)?.toInt() ?? 0;
  }

  static String _dateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}'
      '-${d.day.toString().padLeft(2, '0')}';
}

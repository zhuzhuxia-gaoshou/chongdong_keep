

/// 运动记录模型
class ExerciseRecord {
  final String id;
  final String petId;
  final String userId;
  final ExerciseType type;

  /// 猫玩玩法（仅 type=catPlay 有值，存枚举名如 'featherWand'，契约 ⑭）。
  final String? catPlayType;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final double distance;
  final int steps;
  final List<GeoPoint> route;
  final String? locationName;
  final String? startPhotoPath;

  /// 出发照片的图床 URL（⑬ 服务端归档）。本机记录以 [startPhotoPath] 展示，
  /// 重装/换设备后本地路径丢失时回退此 URL。
  final String? startPhotoUrl;
  final bool isCompleted;
  final bool isManual;

  /// 客户端生成的幂等键（契约 §4.6 ⑭）。M3 之前的存量本地记录为 null，
  /// 按开放问题#4 不回填、不上传。
  final String? clientRecordId;

  ExerciseRecord({
    required this.id,
    required this.petId,
    required this.userId,
    required this.type,
    this.catPlayType,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.distance = 0,
    this.steps = 0,
    this.route = const [],
    this.locationName,
    this.startPhotoPath,
    this.startPhotoUrl,
    this.isCompleted = true,
    this.isManual = false,
    this.clientRecordId,
  });

  int get durationMinutes => duration.inMinutes;
  bool get canCheckIn => durationMinutes >= 5;

  /// 打卡判定口径（契约 §4.7）：完成且 ≥300 秒即计入，**不限运动类型**
  /// （遛狗与猫玩均可，与既有 canCheckIn / 猫玩页文案一致）。服务端同规则。
  bool get countsAsCheckIn => isCompleted && duration.inSeconds >= 300;

  ExerciseRecord copyWith({String? startPhotoPath, String? startPhotoUrl}) =>
      ExerciseRecord(
        id: id,
        petId: petId,
        userId: userId,
        type: type,
        startTime: startTime,
        endTime: endTime,
        duration: duration,
        distance: distance,
        steps: steps,
        route: route,
        locationName: locationName,
        startPhotoPath: startPhotoPath ?? this.startPhotoPath,
        startPhotoUrl: startPhotoUrl ?? this.startPhotoUrl,
        isCompleted: isCompleted,
        isManual: isManual,
        clientRecordId: clientRecordId,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientRecordId': clientRecordId,
    'petId': petId,
    'userId': userId,
    'type': type.index,
    'catPlayType': catPlayType,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'duration': duration.inSeconds,
    'distance': distance,
    'steps': steps,
    'route': route.map((e) => e.toJson()).toList(),
    'locationName': locationName,
    'startPhotoPath': startPhotoPath,
    'startPhotoUrl': startPhotoUrl,
    'isCompleted': isCompleted,
    'isManual': isManual,
  };

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) => ExerciseRecord(
    id: json['id'] as String,
    petId: json['petId'] as String,
    userId: json['userId'] as String,
    type: ExerciseType.values[json['type'] as int? ?? 0],
    catPlayType: json['catPlayType'] as String?,
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: DateTime.parse(json['endTime'] as String),
    duration: Duration(seconds: json['duration'] as int? ?? 0),
    distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
    steps: json['steps'] as int? ?? 0,
    route: (json['route'] as List<dynamic>?)?.map((e) => GeoPoint.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    locationName: json['locationName'] as String?,
    startPhotoPath: json['startPhotoPath'] as String?,
    startPhotoUrl: json['startPhotoUrl'] as String?,
    isCompleted: json['isCompleted'] as bool? ?? true,
    isManual: json['isManual'] as bool? ?? false,
    clientRecordId: json['clientRecordId'] as String?,
  );
}

enum ExerciseType {
  walkDog,
  catPlay,
}

/// GPS轨迹点
class GeoPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;

  GeoPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'accuracy': accuracy,
  };

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
    accuracy: (json['accuracy'] as num?)?.toDouble(),
  );
}

/// 猫咪玩耍类型
enum CatPlayType {
  featherWand, // 逗猫棒
  laserPointer, // 激光笔
  yarnBall, // 毛线球
  electricMouse, // 电动鼠
  bouncyBall, // 弹力球
  boxAdventure, // 纸箱探险
}

extension CatPlayTypeExt on CatPlayType {  String get emoji => switch (this) {
    CatPlayType.featherWand => '🪶',
    CatPlayType.laserPointer => '🔴',
    CatPlayType.yarnBall => '🧶',
    CatPlayType.electricMouse => '🐁',
    CatPlayType.bouncyBall => '🎾',
    CatPlayType.boxAdventure => '📦',
  };

  /// 中文名。注意别用 `.name`——枚举自带的 name（如 featherWand）会遮蔽
  /// 同名扩展 getter，中文名一律走 [label]。
  String get label => switch (this) {
    CatPlayType.featherWand => '逗猫棒',
    CatPlayType.laserPointer => '激光笔',
    CatPlayType.yarnBall => '毛线球',
    CatPlayType.electricMouse => '电动鼠',
    CatPlayType.bouncyBall => '弹力球',
    CatPlayType.boxAdventure => '纸箱探险',
  };
}

extension ExerciseRecordDisplay on ExerciseRecord {
  /// 运动类型显示名：猫玩记录附带玩法（如「陪猫玩 · 逗猫棒」），
  /// 猫玩玩法落库见契约 ⑭ catPlayType。列表/详情/分享卡统一走这里。
  String get typeDisplayName {
    if (type != ExerciseType.catPlay) return '遛狗';
    if (catPlayType == null) return '陪猫玩';
    for (final t in CatPlayType.values) {
      if (t.name == catPlayType) return '陪猫玩 · ${t.label}';
    }
    return '陪猫玩';
  }
}

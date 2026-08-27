

/// 用户模型
class AppUser {
  final String id;
  final String phone;
  final String nickname;
  final String? avatarUrl;
  final DateTime createdAt;
  final int totalExerciseCount;
  final int streakDays;
  final int signCardCount;

  AppUser({
    required this.id,
    required this.phone,
    required this.nickname,
    this.avatarUrl,
    required this.createdAt,
    this.totalExerciseCount = 0,
    this.streakDays = 0,
    this.signCardCount = 3,
  });

  AppUser copyWith({
    String? nickname,
    String? avatarUrl,
    int? totalExerciseCount,
    int? streakDays,
    int? signCardCount,
  }) {
    return AppUser(
      id: id,
      phone: phone,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      totalExerciseCount: totalExerciseCount ?? this.totalExerciseCount,
      streakDays: streakDays ?? this.streakDays,
      signCardCount: signCardCount ?? this.signCardCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'nickname': nickname,
    'avatarUrl': avatarUrl,
    'createdAt': createdAt.toIso8601String(),
    'totalExerciseCount': totalExerciseCount,
    'streakDays': streakDays,
    'signCardCount': signCardCount,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    phone: json['phone'] as String,
    nickname: json['nickname'] as String,
    avatarUrl: json['avatarUrl'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    totalExerciseCount: json['totalExerciseCount'] as int? ?? 0,
    streakDays: json['streakDays'] as int? ?? 0,
    signCardCount: json['signCardCount'] as int? ?? 3,
  );
}

/// 打卡记录
class CheckInRecord {
  final DateTime date;
  final bool isChecked;
  final bool isSigned; // 是否补签

  CheckInRecord({
    required this.date,
    required this.isChecked,
    this.isSigned = false,
  });
}

/// 徽章
class Badge {
  final String id;
  final String name;
  final String emoji;
  final bool isUnlocked;
  final String description;

  Badge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.isUnlocked,
    required this.description,
  });
}

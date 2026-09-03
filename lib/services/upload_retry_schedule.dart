/// 上传失败后的退避重试间隔序列（30s → 1m → 2m → 5m 封顶循环）。
/// 幂等键 clientRecordId 保证重复提交安全（契约 §4.6）。
class UploadRetrySchedule {
  /// 各次失败后的等待时长
  static const List<Duration> backoffSequence = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
  ];

  /// 第 [failureCount] 次失败后应等待多久（failureCount 从 1 起；
  /// 超出序列后循环使用最后一级 5 分钟）
  static Duration nextDelay(int failureCount) {
    if (failureCount <= 0) return backoffSequence.first;
    final i = failureCount - 1;
    return i < backoffSequence.length
        ? backoffSequence[i]
        : backoffSequence.last;
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise_record.dart';
import '../../services/app_state.dart';
import '../../services/map_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/local_image.dart';
import '../share/share_card_page.dart';

/// 运动记录列表页
///
/// 数据源 = AppState.records：Mock 下为纯本地持久化；Live 下由
/// [AppState] 拉取服务端 ⑮ 并与本地未上报记录合并（服务端副本优先、
/// 幂等键去重），本页对数据源无感知、结构不随 M3 改变。
class RecordHistoryPage extends StatelessWidget {
  const RecordHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final records = state.records;

    return Scaffold(
      appBar: AppBar(title: const Text('运动记录')),
      body: records.isEmpty
          ? _buildEmpty(context)
          : _buildGroups(context, state, records),
    );
  }

  // ---- 空态 ----

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🐾', style: TextStyle(fontSize: 64)),
          const SizedBox(height: AppDimens.sp16),
          const Text('还没有运动记录',
              style: TextStyle(
                  fontSize: AppDimens.fsHeadline,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          const SizedBox(height: AppDimens.sp8),
          const Text('完成一次遛狗/陪玩后，就会出现在这里',
              style: TextStyle(
                  fontSize: AppDimens.fsBody, color: AppColors.textSoft)),
          const SizedBox(height: AppDimens.sp24),
          ElevatedButton(
            onPressed: () {
              context.read<AppState>().setIndex(1); // 切到运动 tab
              Navigator.pop(context);
            },
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.pets_rounded, size: 16), SizedBox(width: 6), Text('去遛一次')]),
          ),
        ],
      ),
    );
  }

  // ---- 按日分组 ----

  Widget _buildGroups(
      BuildContext context, AppState state, List<ExerciseRecord> records) {
    final sorted = List<ExerciseRecord>.of(records)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final groups = <DateTime, List<ExerciseRecord>>{};
    for (final r in sorted) {
      final day =
          DateTime(r.startTime.year, r.startTime.month, r.startTime.day);
      groups.putIfAbsent(day, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.sp16, vertical: AppDimens.sp8),
      children: [
        for (final entry in groups.entries) ...[
          _buildDayHeader(entry.key, entry.value),
          for (final r in entry.value) _buildRecordCard(context, state, r),
        ],
        const SizedBox(height: AppDimens.sp24),
      ],
    );
  }

  Widget _buildDayHeader(DateTime day, List<ExerciseRecord> group) {
    final checkedIn = group.any((r) => r.canCheckIn);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.sp4, AppDimens.sp16, AppDimens.sp4, AppDimens.sp8),
      child: Row(
        children: [
          Text(
            '${_dayLabel(day)} · ${group.length}次',
            style: const TextStyle(
                fontSize: AppDimens.fsFoot,
                fontWeight: FontWeight.w700,
                color: AppColors.textSoft),
          ),
          const Spacer(),
          if (checkedIn)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.sp8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.mintLight,
                borderRadius: BorderRadius.circular(AppDimens.rFull),
              ),
              child: const Text('已打卡',
                  style: TextStyle(
                      fontSize: AppDimens.fsCaption,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mint)),
            ),
        ],
      ),
    );
  }

  // ---- 记录卡 ----

  Widget _buildRecordCard(
      BuildContext context, AppState state, ExerciseRecord r) {
    final petName =
        state.pets.where((p) => p.id == r.petId).firstOrNull?.name ?? '宝贝';
    final typeName = r.type == ExerciseType.walkDog ? '遛狗' : '陪猫玩';
    final emoji = r.type == ExerciseType.walkDog ? '🐕' : '🐈';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showRecordDetail(context, r, petName, typeName, emoji),
        borderRadius: BorderRadius.circular(AppDimens.rLg),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppDimens.sp12),
          padding: const EdgeInsets.all(AppDimens.sp16),
          decoration: AppDimens.cardBox(borderColor: AppColors.line),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mintLight,
                      border: Border.all(color: AppColors.mint, width: 1.5),
                    ),
                    child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: AppDimens.sp12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$typeName · $petName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: AppDimens.fsSub,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppDimens.sp4),
                        Text(
                          '${_hhmm(r.startTime)} · ${MapService.formatDuration(r.duration)}',
                          style: const TextStyle(
                              fontSize: AppDimens.fsCaption,
                              color: AppColors.textSoft),
                        ),
                      ],
                    ),
                  ),
                  // 分享入口（直接生成分享卡片）
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ShareCardPage(record: r)),
                    ),
                    icon: const Icon(Icons.ios_share,
                        size: AppDimens.sp20, color: AppColors.textMute),
                    tooltip: '生成分享卡片',
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.sp12),
              Row(
                children: [
                  _miniStat(MapService.formatDuration(r.duration), '时长'),
                  _miniStat(MapService.formatDistance(r.distance), '距离'),
                  _miniStat('${r.steps}', '步数'),
                ],
              ),
              if (r.locationName != null && r.locationName!.isNotEmpty) ...[
                const SizedBox(height: AppDimens.sp8),
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: AppDimens.fsCaption * 1.4,
                        color: AppColors.textMute),
                    const SizedBox(width: AppDimens.sp4),
                    Expanded(
                      child: Text(
                        r.locationName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: AppDimens.fsCaption,
                            color: AppColors.textMute),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: AppDimens.fsBodyMid,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mint)),
          const SizedBox(height: AppDimens.sp4),
          Text(label,
              style: const TextStyle(
                  fontSize: AppDimens.fsMicro, color: AppColors.textSoft)),
        ],
      ),
    );
  }

  // ---- 详情弹窗 ----

  /// 出发照片：优先本地路径（本机产生的记录），丢失时回退服务端图床 URL
  /// （重装/换设备场景，⑬）。都没有则显示占位。
  Widget _startPhoto(ExerciseRecord r) {
    final local = r.startPhotoPath;
    final remote = r.startPhotoUrl;
    Widget child;
    if (local != null && local.isNotEmpty) {
      child = buildLocalImage(
        local,
        height: 160,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _remoteOrLost(remote),
      );
    } else {
      child = _remoteOrLost(remote);
    }
    return SizedBox(height: 160, width: double.infinity, child: child);
  }

  Widget _remoteOrLost(String? remote) {
    if (remote == null || remote.isEmpty) return _photoLost();
    return Image.network(
      remote,
      height: 160,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _photoLost(),
    );
  }

  Widget _photoLost() {
    return Container(
      height: 160,
      width: double.infinity,
      color: AppColors.sand,
      alignment: Alignment.center,
      child: const Text('📷 出发照片已丢失',
          style: TextStyle(fontSize: AppDimens.fsFoot, color: AppColors.textMute)),
    );
  }

  void _showRecordDetail(BuildContext context, ExerciseRecord r, String petName,
      String typeName, String emoji) {
    AppBottomSheet.show<void>(
      context,
      title: '$typeName · $petName',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (r.startPhotoPath != null || r.startPhotoUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.rMd),
              child: _startPhoto(r),
            ),
            const SizedBox(height: AppDimens.sp16),
          ],
          Text(
            '$emoji ${_dayLabel(r.startTime)} ${_hhmm(r.startTime)} · ${MapService.formatDuration(r.duration)}',
            style: const TextStyle(
                fontSize: AppDimens.fsFoot,
                fontWeight: FontWeight.w700,
                color: AppColors.mint),
          ),
          const SizedBox(height: AppDimens.sp16),
          Row(
            children: [
              _detailStat(MapService.formatDistance(r.distance), '距离'),
              _detailStat('${r.steps}', '步数'),
              _detailStat('${r.route.length}', '轨迹点'),
              _detailStat(r.canCheckIn ? '达标' : '—', '打卡'),
            ],
          ),
          if (r.locationName != null && r.locationName!.isNotEmpty) ...[
            const SizedBox(height: AppDimens.sp12),
            Text(
              '${r.locationName}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: AppDimens.fsCaption, color: AppColors.textSoft),
            ),
          ],
          const SizedBox(height: AppDimens.sp20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => ShareCardPage(record: r)),
              ),
              icon: const Icon(Icons.ios_share, size: AppDimens.fsSub),
              label: const Text('生成分享卡片'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: AppDimens.fsBodyMid,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          const SizedBox(height: AppDimens.sp4),
          Text(label,
              style: const TextStyle(
                  fontSize: AppDimens.fsMicro, color: AppColors.textSoft)),
        ],
      ),
    );
  }

  // ---- 时间格式化 ----

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _hhmm(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

  static String _dayLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (t.year != now.year) return '${t.year}年${t.month}月${t.day}日';
    return '${t.month}月${t.day}日';
  }
}

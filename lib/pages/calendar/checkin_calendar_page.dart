import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart' show CheckInRecord;
import '../../services/app_services.dart';
import '../../services/app_state.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/ui_kit.dart';

/// 打卡日历（2026-09-15 质感 v2 重做）：
/// PageHero 英雄头承载统计（连续/本月/补签卡），日期格改圆形状态语言——
/// 薄荷实心=已打卡、薄荷描边=今天、珊瑚票点=可补签。
/// 数据链路不变：M3 起 Live 读服务端 ⑰，Mock/不可达回退本地算法；
/// 补签（⑲）点击过去未打卡日期消耗补签卡。
/// 红线自查：无 stretch / Center 均在有界格内 / 无透明度入场动效。
class CheckInCalendarPage extends StatefulWidget {
  const CheckInCalendarPage({super.key});

  @override
  State<CheckInCalendarPage> createState() => _CheckInCalendarPageState();
}

class _CheckInCalendarPageState extends State<CheckInCalendarPage> {
  DateTime _currentMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  Future<List<CheckInRecord>> _days = Future.value(const []);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final state = context.read<AppState>();
    setState(() {
      _days = state.loadMonthlyCheckIns(_currentMonth.year, _currentMonth.month);
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    });
    _load();
  }

  /// 补签（契约 ⑲）：确认后消耗补签卡，恢复该日打卡与连续天数
  Future<void> _makeUpFor(DateTime date, List<CheckInRecord> checkIns) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final signCards = state.user?.signCardCount ?? 0;
    if (signCards <= 0) {
      messenger.showSnackBar(
          const SnackBar(content: Text('补签卡不足（每月 3 张），分享 APP 可以获得哦')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('使用补签卡'),
        content: Text(
            '为 ${date.month} 月 ${date.day} 日补签？\n将消耗 1 张补签卡（剩余 $signCards 张），'
            '并恢复当天的连续打卡天数。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认补签'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final remaining = await AppServices.instance.records.makeUpCheckin(date);
      if (!mounted) return;
      final user = state.user;
      if (user != null) {
        await state.updateUser(user.copyWith(signCardCount: remaining));
      }
      messenger.showSnackBar(SnackBar(
          content: Text('补签成功！剩余补签卡 $remaining 张')));
      _load();
    } on ApiException {
      // 具体原因（卡不足/已打卡）由服务端给出，静默失败页面自动刷新
      messenger.showSnackBar(const SnackBar(
          content: Text('补签没有成功，刷新后再试试哦')));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = DateTime.now();
    final weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final signCards = state.user?.signCardCount ?? 3;
    final streak = state.user?.streakDays ?? 0;

    return Scaffold(
      body: FutureBuilder<List<CheckInRecord>>(
        future: _days,
        builder: (context, snap) {
          final checkIns = snap.data ??
              state.getMonthlyCheckIns(
                  _currentMonth.year, _currentMonth.month);
          final checkedCount = checkIns.where((c) => c.isChecked).length;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 英雄头：品牌渐变 + 三项统计随头部浮在渐变上
                PageHero(
                  title: '打卡日历',
                  subtitle: streak > 0
                      ? '已经连续打卡 $streak 天啦，宝贝为你骄傲'
                      : '今天也要记得陪宝贝动一动哦',
                  leading: _heroBackButton(context),
                  child: Row(
                    children: [
                      Expanded(
                          child: _heroStat(
                              '$streak', '连续天数')),
                      const SizedBox(width: AppDimens.sp8),
                      Expanded(
                          child: _heroStat('$checkedCount', '本月打卡')),
                      const SizedBox(width: AppDimens.sp8),
                      Expanded(
                          child: _heroStat('$signCards', '补签卡')),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimens.sp16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 日历白卡：月份切换 + 星期头 + 日期格
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimens.sp12),
                        decoration: AppDimens.cardBox(),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _monthArrow(Icons.chevron_left,
                                    () => _shiftMonth(-1)),
                                Text(
                                    '${_currentMonth.year}年${_currentMonth.month}月',
                                    style: const TextStyle(
                                        fontSize: AppDimens.fsSub,
                                        fontWeight: FontWeight.w700)),
                                _monthArrow(Icons.chevron_right,
                                    () => _shiftMonth(1)),
                              ],
                            ),
                            const SizedBox(height: AppDimens.sp12),
                            Row(
                              children: [
                                for (final w in weekdays)
                                  Expanded(
                                    child: Center(
                                      child: Text(w,
                                          style: const TextStyle(
                                              fontSize: AppDimens.fsMicro,
                                              color: AppColors.textMute,
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppDimens.sp4),
                            GridView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 7,
                                      childAspectRatio: 1),
                              itemCount: firstWeekday + daysInMonth,
                              itemBuilder: (_, i) {
                                if (i < firstWeekday) {
                                  return const SizedBox();
                                }
                                final day = i - firstWeekday + 1;
                                final date = DateTime(_currentMonth.year,
                                    _currentMonth.month, day);
                                final isChecked =
                                    checkIns[day - 1].isChecked;
                                final isToday = date.year == today.year &&
                                    date.month == today.month &&
                                    date.day == today.day;
                                final isMakeupDay =
                                    !isChecked && date.isBefore(today);
                                // 票点只在还有卡时显示；点击任何过去未打卡日期都触发
                                // （无卡时由 _makeUpFor 弹"补签卡不足"解释，行为不回退）
                                final showTicket =
                                    isMakeupDay && signCards > 0;

                                return PressableScale(
                                  onTap: isMakeupDay
                                      ? () => _makeUpFor(date, checkIns)
                                      : null,
                                  child: _dayCell(
                                    day: day,
                                    checked: isChecked,
                                    isToday: isToday,
                                    canMakeup: showTicket,
                                    isFuture: date.isAfter(today) &&
                                        !isToday,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.sp16),
                      // 补签说明条：AppChip 珊瑚 tonal 说明形态（票点图标 + 主副文案）
                      AppChip(
                        label: '补签卡',
                        message: signCards > 0
                            ? '点日历上带票点的过去日期就能补上哦'
                            : '这个月的补签卡用完啦，分享 APP 可以获得哦',
                        leading: const Icon(Icons.confirmation_num_outlined,
                            size: AppDimens.iconMd, color: AppColors.coral),
                        background: AppColors.coralLight,
                        borderColor: AppColors.coralLine,
                        textColor: AppColors.coral,
                        radius: AppDimens.rMd,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---- 头部小件 ----

  Widget _heroBackButton(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.arrow_back_ios_new,
              size: AppDimens.iconMd, color: AppColors.onAccent),
        ),
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.sp8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppDimens.rMd),
      ),
      child: Column(
        children: [
          Text(value,
              style:
                  AppText.numericStat(color: AppColors.onAccent)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: AppDimens.fsMicro,
                  color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  Widget _monthArrow(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.sand,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: AppDimens.iconMd, color: AppColors.textSoft)),
      ),
    );
  }

  // ---- 日期格：圆形状态语言 ----

  Widget _dayCell({
    required int day,
    required bool checked,
    required bool isToday,
    required bool canMakeup,
    required bool isFuture,
  }) {
    final number = Text(
      '$day',
      style: TextStyle(
        fontSize: AppDimens.fsFoot,
        fontWeight: checked || isToday ? FontWeight.w700 : FontWeight.w500,
        color: checked
            ? AppColors.onAccent
            : isToday
                ? AppColors.mint
                : isFuture
                    ? AppColors.textMute
                    : AppColors.text,
      ),
    );

    BoxDecoration box;
    if (checked) {
      // 已打卡：薄荷实心圆
      box = const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.mint,
      );
    } else if (isToday) {
      // 今天：薄荷描边圈
      box = BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.card,
        border: Border.all(color: AppColors.mint, width: 2),
      );
    } else if (canMakeup) {
      // 可补签：沙底圆
      box = const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.sand,
      );
    } else {
      box = const BoxDecoration(shape: BoxShape.circle);
    }

    return Container(
      margin: const EdgeInsets.all(AppDimens.sp4),
      decoration: box,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          number,
          if (canMakeup)
            Container(
              margin: const EdgeInsets.only(top: 2),
              child: const Icon(Icons.confirmation_num,
                  size: 10, color: AppColors.coral),
            ),
        ],
      ),
    );
  }
}

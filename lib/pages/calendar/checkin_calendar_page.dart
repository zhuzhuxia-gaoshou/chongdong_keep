import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../models/user.dart' show CheckInRecord;
import '../../services/app_services.dart';
import '../../services/app_state.dart';

/// 打卡日历：M3 起 Live 模式读服务端 ⑰（跨设备一致），
/// Mock 或服务端不可达时回退本地算法（[AppState.getMonthlyCheckIns] 同规则）。
/// 补签（⑲）：点击过去未打卡的日期，消耗补签卡恢复连续天数。
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
        title: const Text('🎫 使用补签卡'),
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

    return Scaffold(
      appBar: AppBar(title: const Text('📅 打卡日历')),
      body: FutureBuilder<List<CheckInRecord>>(
        future: _days,
        builder: (context, snap) {
          final checkIns = snap.data ??
              state.getMonthlyCheckIns(
                  _currentMonth.year, _currentMonth.month);
          final checkedCount = checkIns.where((c) => c.isChecked).length;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 统计卡片
                Row(
                  children: [
                    Expanded(
                        child: _statCard(
                            '${state.user?.streakDays ?? 0}', '连续打卡')),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard('$checkedCount', '本月打卡')),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard('$signCards', '补签卡剩余')),
                  ],
                ),
                const SizedBox(height: 14),
                // 月份切换
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _shiftMonth(-1),
                    ),
                    Text('${_currentMonth.year}年${_currentMonth.month}月',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _shiftMonth(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 星期表头
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7, childAspectRatio: 1),
                  itemCount: 7,
                  itemBuilder: (_, i) => Center(
                      child: Text(weekdays[i],
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMute,
                              fontWeight: FontWeight.w600))),
                ),
                // 日历网格
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7, childAspectRatio: 1),
                  itemCount: firstWeekday + daysInMonth,
                  itemBuilder: (_, i) {
                    if (i < firstWeekday) return const SizedBox();
                    final day = i - firstWeekday + 1;
                    final date =
                        DateTime(_currentMonth.year, _currentMonth.month, day);
                    final isChecked = checkIns[day - 1].isChecked;
                    final isToday = date.year == today.year &&
                        date.month == today.month &&
                        date.day == today.day;

                    return GestureDetector(
                      onTap: (!isChecked && date.isBefore(today))
                          ? () => _makeUpFor(date, checkIns)
                          : null,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color:
                              isChecked ? AppColors.mintLight : AppColors.card,
                          border: Border.all(
                            color: isToday
                                ? AppColors.mint
                                : (isChecked ? AppColors.mint : AppColors.line),
                            width: isToday ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isChecked
                                      ? AppColors.mint
                                      : AppColors.text,
                                ),
                              ),
                              if (!isChecked &&
                                  date.isBefore(today) &&
                                  signCards > 0)
                                const Text('🎫',
                                    style: TextStyle(fontSize: 9)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                // 补签卡入口
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.coralLight,
                    border: Border.all(color: AppColors.coralLine),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🎫 补签卡',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.coral,
                                  fontWeight: FontWeight.w700)),
                          Text('点击日历上带 🎫 的日期即可补签',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.textSoft)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: signCards > 0
                            ? () => _toast('点击日历上带 🎫 的过去日期即可补签')
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                        ),
                        child:
                            const Text('补签', style: TextStyle(fontSize: 12)),
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

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mint)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, color: AppColors.textSoft)),
        ],
      ),
    );
  }
}

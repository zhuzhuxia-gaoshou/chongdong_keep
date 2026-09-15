import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

/// 收藏路线页（2026-09-15 质感 v2）：
/// 板外私造色（紫 0xFF7E57C2 / 青 0xFF26C6DA / Colors.amber）全部收回
/// 调色板（mint / skyDeep / coral / mintDeep），收藏星=珊瑚点缀色；
/// 路线卡白底浮起 + token 归档。当前为静态演示数据。
class RouteFavoritesPage extends StatelessWidget {
  const RouteFavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('收藏路线')),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppDimens.sp16),
        itemCount: 4,
        itemBuilder: (context, index) {
          final routes = [
            {
              'name': '朝阳公园环线',
              'distance': '2.8km',
              'duration': '约35分钟',
              'count': 12,
              'color': AppColors.mint
            },
            {
              'name': '奥森公园经典线',
              'distance': '5.2km',
              'duration': '约65分钟',
              'count': 8,
              'color': AppColors.coral
            },
            {
              'name': '小区漫步路线',
              'distance': '1.2km',
              'duration': '约15分钟',
              'count': 45,
              'color': AppColors.skyDeep
            },
            {
              'name': '河边步道',
              'distance': '3.5km',
              'duration': '约45分钟',
              'count': 6,
              'color': AppColors.mintDeep
            },
          ];
          final route = routes[index];
          return _buildRouteCard(route);
        },
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final color = route['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.sp12),
      decoration: AppDimens.cardBox(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            color: color.withValues(alpha: 0.1),
            child: Center(
              child: CustomPaint(
                size: const Size(200, 80),
                painter: _MiniRoutePainter(color),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimens.sp16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        route['name'] as String,
                        style: const TextStyle(
                            fontSize: AppDimens.fsSub,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.sp8, vertical: AppDimens.sp4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppDimens.rXs),
                      ),
                      child: Text('${route['count']}次',
                          style: TextStyle(
                              fontSize: AppDimens.fsCaption,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.sp12),
                Row(
                  children: [
                    _buildStat(Icons.route_rounded, route['distance'] as String),
                    const SizedBox(width: AppDimens.sp20),
                    _buildStat(Icons.access_time_rounded, route['duration'] as String),
                  ],
                ),
                const SizedBox(height: AppDimens.sp12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: color),
                          foregroundColor: color,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimens.rSm)),
                        ),
                        child: const Text('开始这条路线',
                            style:
                                TextStyle(fontSize: AppDimens.fsBody)),
                      ),
                    ),
                    const SizedBox(width: AppDimens.sp8),
                    IconButton(
                      // 收藏态=珊瑚点缀色（板外 Colors.amber 已退役）
                      icon:
                          const Icon(Icons.star_rounded, color: AppColors.coral, size: AppDimens.iconLg),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: AppDimens.iconSm, color: AppColors.textSoft),
        const SizedBox(width: AppDimens.sp4),
        Text(text,
            style: const TextStyle(
                fontSize: AppDimens.fsFoot, color: AppColors.textSoft)),
      ],
    );
  }
}

class _MiniRoutePainter extends CustomPainter {
  final Color color;

  _MiniRoutePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(20, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.2,
          size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.8,
          size.width * 0.85, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.95, size.height * 0.1,
          size.width - 20, size.height * 0.4);

    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(20, 56), 5, dotPaint);
    canvas.drawCircle(Offset(size.width - 20, size.height * 0.4), 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class RouteFavoritesPage extends StatelessWidget {
  const RouteFavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('收藏路线')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) {
          final routes = [
            {'name': '朝阳公园环线', 'distance': '2.8km', 'duration': '约35分钟', 'count': 12, 'color': AppColors.mint},
            {'name': '奥森公园经典线', 'distance': '5.2km', 'duration': '约65分钟', 'count': 8, 'color': AppColors.coral},
            {'name': '小区漫步路线', 'distance': '1.2km', 'duration': '约15分钟', 'count': 45, 'color': const Color(0xFF7E57C2)},
            {'name': '河边步道', 'distance': '3.5km', 'duration': '约45分钟', 'count': 6, 'color': const Color(0xFF26C6DA)},
          ];
          final route = routes[index];
          return _buildRouteCard(route);
        },
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: (route['color'] as Color).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(200, 80),
                painter: _MiniRoutePainter(route['color'] as Color),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        route['name'] as String,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (route['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${route['count']}次', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: route['color'] as Color)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStat(Icons.route, route['distance'] as String),
                    const SizedBox(width: 20),
                    _buildStat(Icons.access_time, route['duration'] as String),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: route['color'] as Color),
                          foregroundColor: route['color'] as Color,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('开始这条路线', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.star, color: Colors.amber, size: 24),
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
        Icon(icon, size: 16, color: AppColors.textSoft),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: AppColors.textSoft)),
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
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.2, size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.8, size.width * 0.85, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.95, size.height * 0.1, size.width - 20, size.height * 0.4);

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

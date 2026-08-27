import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_colors.dart';
import '../../models/exercise_record.dart';

class ShareCardPage extends StatefulWidget {
  final ExerciseRecord record;

  const ShareCardPage({super.key, required this.record});

  @override
  State<ShareCardPage> createState() => _ShareCardPageState();
}

class _ShareCardPageState extends State<ShareCardPage> {
  int _selectedTemplate = 0;
  bool _showLocation = false;

  final List<Map<String, dynamic>> _templates = [
    {'name': '可爱风', 'color': AppColors.mint, 'icon': '🐾'},
    {'name': '杂志风', 'color': const Color(0xFF7E57C2), 'icon': '📖'},
    {'name': '数据风', 'color': const Color(0xFF26C6DA), 'icon': '📊'},
    {'name': '夜景风', 'color': const Color(0xFF37474F), 'icon': '🌙'},
    {'name': '生日风', 'color': const Color(0xFFFF8A65), 'icon': '🎂'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分享卡片')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCardPreview(),
                  const SizedBox(height: 20),
                  const Text('选择模板', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  _buildTemplateSelector(),
                  const SizedBox(height: 16),
                  _buildOptions(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildCardPreview() {
    final template = _templates[_selectedTemplate];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: template['color'] as Color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(template['icon'] as String, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              const Text('宠动Keep', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('🐕 遛狗', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(200, 80),
                painter: _CardRoutePainter(Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCardStat('${widget.record.duration.inMinutes}', '分钟'),
              _buildCardStat('${widget.record.distance.toStringAsFixed(1)}', '公里'),
              _buildCardStat('${widget.record.steps}', '步'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            (widget.record.locationName?.isEmpty ?? true)
                ? ''
                : (_showLocation ? '📍 ${widget.record.locationName!}' : '📍 位置已隐藏'),
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text('坚持运动，和宝贝一起健康成长', style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildCardStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _buildTemplateSelector() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final template = _templates[index];
          final isSelected = _selectedTemplate == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedTemplate = index);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              width: 56,
              decoration: BoxDecoration(
                color: template['color'] as Color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.text : Colors.transparent,
                  width: isSelected ? 3 : 0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(template['icon'] as String, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 3),
                  Text(template['name'] as String, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off, size: 18, color: AppColors.textSoft),
          const SizedBox(width: 10),
          const Expanded(child: Text('显示位置', style: TextStyle(fontSize: 13))),
          Switch(
            value: _showLocation,
            onChanged: (v) => setState(() => _showLocation = v),
            activeColor: AppColors.mint,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('卡片已保存到相册')),
                );
              },
              child: const Text('💾 保存相册'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                await Share.share('我在宠动Keep完成了${widget.record.duration.inMinutes}分钟的运动，一起来关注宠物健康吧！');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.mint),
              child: const Text('📤 分享'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardRoutePainter extends CustomPainter {
  final Color color;

  _CardRoutePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(10, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.3, size.width * 0.5, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.9, size.width * 0.85, size.height * 0.2)
      ..lineTo(size.width - 10, size.height * 0.4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

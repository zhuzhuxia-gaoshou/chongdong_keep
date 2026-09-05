import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/pet.dart';
import '../../services/map_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/nearby_hospitals_section.dart';

/// 紧急就医页（PRD 4.5.2/4.5.3）：紧急联系人一键拨打 + 温柔风指引 +
/// 真实附近宠物医院。高风险症状（呕吐/瘸了/抽搐/出血等）直接跳转本页。
class EmergencyCarePage extends StatefulWidget {
  final Pet? pet;

  const EmergencyCarePage({super.key, this.pet});

  @override
  State<EmergencyCarePage> createState() => _EmergencyCarePageState();
}

class _EmergencyCarePageState extends State<EmergencyCarePage> {
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    final pos = await MapService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    }
  }

  Future<void> _dial(String tel) async {
    final uri = Uri(scheme: 'tel', path: tel);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _toast('当前设备无法直接拨号，号码：$tel');
      }
    } catch (_) {
      _toast('无法打开拨号，号码是：$tel');
    }
  }

  /// 紧急联系人存储格式为「称呼 号码」，拨号前提取号码部分
  String? _phoneFromContact(String contact) {
    final m = RegExp(r'(1[3-9]\d{9}|0\d{2,3}-?\d{7,8})').firstMatch(contact);
    if (m != null) return m.group(0);
    final digits = contact.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length >= 7 ? digits : null;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final contact = pet?.emergencyContact;

    return Scaffold(
      appBar: AppBar(title: Text('紧急就医${pet == null ? '' : ' · ${pet.name}'}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 紧急联系人卡
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.coral, AppColors.coralDeep]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('先别慌，我陪你一起处理💗',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    pet == null
                        ? '保持冷静，尽快联系就近宠物医院'
                        : '保持冷静，别让${pet.name}剧烈移动，注意保暖',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  if (contact != null && _phoneFromContact(contact) != null)
                    ElevatedButton.icon(
                      onPressed: () => _dial(_phoneFromContact(contact)!),
                      icon: const Icon(Icons.phone, size: 16),
                      label: Text('拨打紧急联系人（$contact）',
                          style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.coral,
                      ),
                    )
                  else
                    const Text(
                      '还没有为宝贝设置紧急联系人，建议在宠物档案里补一个哦；下方可查找附近医院',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('等待就医时可以这样做',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _tipItem(Icons.bed_rounded, '让宝贝安静平躺，避免剧烈移动和按压'),
            _tipItem(Icons.thermostat_rounded, '注意保暖，但也别捂得太严实'),
            _tipItem(Icons.block_rounded, '不要自行喂药喂食（可能加重病情）'),
            _tipItem(Icons.call_rounded, '提前打电话给医院确认急诊与位置，减少等待'),
            const SizedBox(height: 16),
            if (_lat != null && _lng != null)
              NearbyHospitalsSection(wgsLat: _lat!, wgsLng: _lng!)
            else
              const Text('正在获取当前位置以查找附近医院…',
                  style: TextStyle(fontSize: 12, color: AppColors.textSoft)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mintLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.mintLine),
              ),
              child: const Text(
                '本页提供的信息仅供参考，不能替代兽医诊断。紧急情况请以就近实体医院为准。',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textSoft, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.coral),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}

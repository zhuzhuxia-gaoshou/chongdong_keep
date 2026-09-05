import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/map_service.dart';
import '../theme/app_colors.dart';

/// 附近宠物医院列表（真实腾讯 POI 搜索，PRD 4.5.2）。
///
/// [wgsLat]/[wgsLng] 为 WGS-84 坐标；内部自动转 GCJ-02 查询。
/// 无地图 Key / 请求失败时显示友好降级文案，不阻塞页面其余部分。
class NearbyHospitalsSection extends StatefulWidget {
  final double wgsLat;
  final double wgsLng;

  const NearbyHospitalsSection({
    super.key,
    required this.wgsLat,
    required this.wgsLng,
  });

  @override
  State<NearbyHospitalsSection> createState() => _NearbyHospitalsSectionState();
}

class _NearbyHospitalsSectionState extends State<NearbyHospitalsSection> {
  late Future<List<PetHospital>?> _future;

  @override
  void initState() {
    super.initState();
    _future = MapService.searchNearbyPetHospitals(widget.wgsLat, widget.wgsLng);
  }

  Future<void> _call(String tel) async {
    final uri = Uri(scheme: 'tel', path: tel);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showUnreachable('当前设备无法直接拨号，号码已为你展示：$tel');
      }
    } catch (_) {
      _showUnreachable('无法打开拨号，号码是：$tel');
    }
  }

  void _showUnreachable(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('附近宠物医院',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _future = MapService.searchNearbyPetHospitals(
                      widget.wgsLat, widget.wgsLng);
                });
              },
              child: const Text('重新定位搜索',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mint)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<PetHospital>?>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _statusCard('正在查找附近的宠物医院…');
            }
            final list = snap.data;
            if (list == null) {
              return _statusCard(
                  '暂时查不到附近的医院（未配置地图Key或网络不佳）。\n紧急情况请直接拨打当地宠物医院电话或前往就近门店哦🥺');
            }
            if (list.isEmpty) {
              return _statusCard('附近 5 公里内没搜到宠物医院，可以扩大范围或咨询线上兽医哦');
            }
            return Column(
              children: [
                for (final h in list) ...[
                  _hospitalItem(h),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _statusCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 12, color: AppColors.textSoft, height: 1.5)),
    );
  }

  Widget _hospitalItem(PetHospital h) {
    final dist = h.distanceMeters == null
        ? ''
        : h.distanceMeters! >= 1000
            ? '${(h.distanceMeters! / 1000).toStringAsFixed(1)}km'
            : '${h.distanceMeters!.round()}m';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.mintLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.local_hospital_rounded, size: 20, color: AppColors.mint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                if (h.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(h.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSoft)),
                ],
                if (dist.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('距离约 $dist',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mint,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          if (h.tel != null)
            IconButton(
              tooltip: '拨打 ${h.tel}',
              icon: const Icon(Icons.phone, color: AppColors.mint),
              onPressed: () => _call(h.tel!),
            ),
        ],
      ),
    );
  }
}

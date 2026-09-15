import 'dart:io';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 移动端实现：本地文件路径 → Image.file
Widget localImageWidget(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  return Image.file(
    File(path),
    fit: fit,
    width: width,
    height: height,
    errorBuilder: errorBuilder ??
        (_, __, ___) => Container(
              width: width,
              height: height,
              // 图片加载失败占位底：品牌次级中性底（冷灰私造色已收编，D2-1）
              color: AppColors.sand,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_rounded,
                  size: 28, color: Colors.grey),
            ),
  );
}

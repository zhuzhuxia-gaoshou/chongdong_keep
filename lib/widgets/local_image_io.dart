import 'dart:io';
import 'package:flutter/material.dart';

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
              color: const Color(0xFFEFEFEF),
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined,
                  size: 28, color: Colors.grey),
            ),
  );
}

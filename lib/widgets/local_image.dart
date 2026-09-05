import 'package:flutter/material.dart';

import 'local_image_io.dart' if (dart.library.html) 'local_image_web.dart'
    as impl;

/// 本地/临时图片展示的跨平台统一入口：
/// - 移动端 → Image.file（dart:io）
/// - Web 端 → Image.network（blob: 临时地址与 http URL 都能加载）
/// 两端都用 errorBuilder 优雅兜底，杜绝 FileImage 在 web 上崩溃。
Widget buildLocalImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  return impl.localImageWidget(path,
      fit: fit, width: width, height: height, errorBuilder: errorBuilder);
}

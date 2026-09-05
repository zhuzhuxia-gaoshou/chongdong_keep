import 'package:flutter/material.dart';

/// Web 端实现：blob: 临时地址或 http URL → Image.network
Widget localImageWidget(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  return Image.network(
    path,
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

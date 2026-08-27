import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 统一用户头像：兼容三种取值来源——
/// 空 → emoji 兜底；http(s) URL → CachedNetworkImage；否则视为本地路径 Image.file。
/// 任一加载失败都优雅回落到 emoji 圆形底，杜绝 FileImage(httpUrl) 崩溃。
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.url,
    required this.radius,
    this.fallbackEmoji = '👩',
  });

  final String? url;
  final double radius;
  final String fallbackEmoji;

  @override
  Widget build(BuildContext context) {
    final u = url?.trim();
    Widget? inner;
    if (u != null && u.isNotEmpty) {
      inner = u.startsWith('http')
          ? CachedNetworkImage(
              imageUrl: u,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              placeholder: (_, __) => ColoredBox(color: AppColors.mintLight),
              errorWidget: (_, __, ___) => Center(
                child: Text(fallbackEmoji),
              ),
            )
          : Image.file(
              File(u),
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(fallbackEmoji),
              ),
            );
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.mintLight,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: inner ??
          Text(fallbackEmoji, style: TextStyle(fontSize: radius * 1.05)),
    );
  }
}

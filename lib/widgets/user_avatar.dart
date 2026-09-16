import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'local_image.dart';

/// 统一用户头像：兼容三种取值来源——
/// 空 → emoji 兜底；http(s) URL → CachedNetworkImage；否则视为本地路径
/// （移动端 Image.file / Web 端 blob 地址）。任一加载失败都优雅回落到 emoji 圆形底。
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.url,
    required this.radius,
    this.fallbackEmoji = '👩',
    this.semanticLabel,
  });

  final String? url;
  final double radius;
  final String fallbackEmoji;

  /// 读屏标签（E5-1）：传入即以「图片」角色整体朗读，内部 emoji/图片
  /// 子节点不再单独出声；不传则语义行为与既往完全一致。
  final String? semanticLabel;

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
          : buildLocalImage(
              u,
              width: radius * 2,
              height: radius * 2,
              errorBuilder: (_, __, ___) => Center(
                child: Text(fallbackEmoji),
              ),
            );
    }

    final Widget avatar = Container(
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
    if (semanticLabel == null) return avatar;
    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: avatar,
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// 应用统一底部弹窗骨架：透明底 + 白面板(rXl 圆角) + 抓手条 + 可选标题。
/// 自动处理键盘避让与 SafeArea；调用方只提供 [builder] 的内容部分，
/// 内部仍可用自己的 StatefulBuilder/滚动逻辑。
class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    bool isScrollControlled = false,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimens.rXl)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.sp20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 抓手条
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius:
                            BorderRadius.circular(2), // 元素内在"全圆端"
                      ),
                    ),
                  ),
                  if (title != null) ...[
                    const SizedBox(height: AppDimens.sp16),
                    Text(title, textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: AppDimens.fsSub,
                            fontWeight: FontWeight.w800)),
                  ],
                  const SizedBox(height: AppDimens.sp16),
                  builder(ctx),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

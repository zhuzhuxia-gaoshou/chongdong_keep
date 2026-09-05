import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 移动端实现：把临时图片复制到应用文档目录持久化，返回新路径
Future<String> persistPickedImage(String sourcePath) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/images');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
  final dest = File('${dir.path}/img_${DateTime.now().millisecondsSinceEpoch}.$ext');
  await File(sourcePath).copy(dest.path);
  return dest.path;
}

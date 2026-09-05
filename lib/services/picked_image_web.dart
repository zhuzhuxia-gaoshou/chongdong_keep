/// Web 端实现：浏览器没有文件系统，image_picker 给的是 blob: 临时地址，
/// 直接原样返回供本会话展示（刷新/重启后失效，历史记录走 errorBuilder 兜底）。
Future<String> persistPickedImage(String sourcePath) async {
  return sourcePath;
}

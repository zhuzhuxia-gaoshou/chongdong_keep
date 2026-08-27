import 'package:image_picker/image_picker.dart';

import '../models/dto/user_dto.dart';
import '../models/user.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

/// 上传成功结果
class UploadedImage {
  const UploadedImage({required this.url, required this.fileSize});

  final String url;
  final int fileSize;
}

/// 用户域门面：资料读取与更新、头像上传。
class UserRepository {
  UserRepository(this._client);

  static const int _avatarMaxBytes = 2 * 1024 * 1024; // 契约 4.8

  final ApiClient _client;

  Future<AppUser> fetchMe() async =>
      UserDto.fromWire(unwrapEnvelope(await _client.get('/api/v1/users/me')));

  /// 只提交出现的字段；以服务端回包为准。
  Future<AppUser> patchMe({String? nickname, String? avatarUrl}) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname.trim();
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    if (body.isEmpty) throw ApiException(kCodeParamInvalid, '没有可更新的字段');
    return UserDto.fromWire(
        unwrapEnvelope(await _client.patch('/api/v1/users/me', body: body)));
  }

  /// 头像上传：客户端先做与服务端一致的预校验（类型/大小），再走 multipart。
  Future<UploadedImage> uploadAvatar(XFile picked) async {
    final name = _resolveFileName(picked);
    final ext =
        name.contains('.') ? name.split('.').last.toLowerCase() : '';
    const allowed = {'jpg', 'jpeg', 'png', 'webp'};
    if (!allowed.contains(ext)) {
      throw ApiException(kCodeUploadType, '仅支持 JPG/PNG/WebP 图片');
    }
    final bytes = await picked.readAsBytes();
    if (bytes.length > _avatarMaxBytes) {
      throw ApiException(kCodeUploadSize, '图片大小超出限制');
    }
    final data = unwrapEnvelope(await _client.upload('/api/v1/upload',
        bytes: bytes, filename: name, fields: {'businessType': 'avatar'}));
    return UploadedImage(
        url: data['url'] as String,
        fileSize: (data['fileSize'] as num?)?.toInt() ?? bytes.length);
  }

  /// 解析可靠文件名：XFile 的 name/path 在部分平台或内存构造时可能为空，
  /// 此时按 mimeType 兜底推断，最后默认 jpg。
  static String _resolveFileName(XFile f) {
    bool hasExt(String s) =>
        s.contains('.') && s.split('.').last.trim().isNotEmpty;
    if (hasExt(f.name)) return f.name;
    if (f.path.isNotEmpty && hasExt(f.path.split('\\').last)) {
      return f.path.split('\\').last;
    }
    if (f.path.isNotEmpty && hasExt(f.path.split('/').last)) {
      return f.path.split('/').last;
    }
    switch (f.mimeType) {
      case 'image/jpeg':
      case 'image/jpg':
        return 'photo.jpg';
      case 'image/webp':
        return 'photo.webp';
      case 'image/gif': // 仅用于让校验给出准确的类型错误
        return 'photo.gif';
      default:
        return 'photo.jpg';
    }
  }
}

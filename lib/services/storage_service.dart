import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';
import '../models/exercise_record.dart';
import '../models/user.dart';
import '../models/walk_session.dart';
import 'picked_image_io.dart'
    if (dart.library.html) 'picked_image_web.dart' as picked_image;

class StorageService {
  StorageService._();

  /// 把临时图片持久化：移动端复制到应用文档目录；Web 端返回 blob 地址（本会话有效）
  static Future<String> savePickedImage(String sourcePath) =>
      picked_image.persistPickedImage(sourcePath);

  /// 保存手动选择的天气位置（name/lat/lng）
  static Future<void> saveWeatherLocation(String name, double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weather_location', json.encode({
      'name': name,
      'lat': lat,
      'lng': lng,
    }));
  }

  /// 读取手动选择的天气位置，未设置过返回 null
  static Future<Map<String, dynamic>?> loadWeatherLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('weather_location');
    if (data == null) return null;
    try {
      return json.decode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(user.toJson()));
  }

  static Future<AppUser?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user');
    if (data == null) return null;
    return AppUser.fromJson(json.decode(data));
  }

  static Future<void> savePets(List<Pet> pets) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> data = pets.map((p) => json.encode(p.toJson())).toList();
    await prefs.setStringList('pets', data);
  }

  static Future<List<Pet>> loadPets() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? data = prefs.getStringList('pets');
    if (data == null) return [];
    return data.map((e) => Pet.fromJson(json.decode(e))).toList();
  }

  static Future<void> saveRecords(List<ExerciseRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> data = records.map((r) => json.encode(r.toJson())).toList();
    await prefs.setStringList('records', data);
  }

  static Future<List<ExerciseRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? data = prefs.getStringList('records');
    if (data == null) return [];
    return data.map((e) => ExerciseRecord.fromJson(json.decode(e))).toList();
  }

  /// 清除手动选择的天气位置（恢复跟随定位）
  static Future<void> clearWeatherLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('weather_location');
  }

  /// 遛狗进行中的可恢复会话（进程被杀后用于恢复弹窗，PRD 4.2.3）
  static Future<void> saveWalkSession(WalkSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('walk_session', json.encode(session.toJson()));
  }

  static Future<WalkSession?> loadWalkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('walk_session');
    if (data == null) return null;
    try {
      return WalkSession.fromJson(json.decode(data));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearWalkSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('walk_session');
  }

  static Future<void> saveCheckinDays(Set<String> days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('checkin_days', days.toList());
  }

  static Future<Set<String>> loadCheckinDays() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? data = prefs.getStringList('checkin_days');
    if (data == null) return {};
    return data.toSet();
  }

  static Future<void> saveCurrentStreak(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_streak', days);
  }

  static Future<int> loadCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('current_streak') ?? 0;
  }

  static Future<void> saveTotalStreak(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_streak', days);
  }

  static Future<int> loadTotalStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('total_streak') ?? 0;
  }

  static Future<void> saveInvites(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('invites', count);
  }

  static Future<int> loadInvites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('invites') ?? 3;
  }

  static Future<void> saveBadges(List<String> badges) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('badges', badges);
  }

  static Future<List<String>> loadBadges() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('badges') ?? [];
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

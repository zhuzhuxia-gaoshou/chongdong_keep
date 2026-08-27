import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../models/user.dart';
import '../models/exercise_record.dart';
import '../network/api_exception.dart';
import 'api_config.dart';
import 'app_services.dart';
import 'storage_service.dart';

class AppState extends ChangeNotifier {
  bool _isLoggedIn = false;
  AppUser? _user;
  List<Pet> _pets = [];
  List<ExerciseRecord> _records = [];
  int _currentIndex = 0;

  bool get isLoggedIn => _isLoggedIn;
  AppUser? get user => _user;
  List<Pet> get pets => _pets;
  List<ExerciseRecord> get records => _records;
  int get currentIndex => _currentIndex;

  Pet? get currentPet => _pets.isNotEmpty ? _pets.first : null;

  Future<void> init() async {
    final user = await StorageService.loadUser();
    if (user != null) {
      _isLoggedIn = true;
      _user = user;
      _pets = await StorageService.loadPets();
      _records = await StorageService.loadRecords();
    }
    // 服务端判定 refreshToken 失效时强制回登录页
    AppServices.instance.api.onSessionExpired = _applySignedOut;
    // Live 模式下静默复同步个人资料（Mock/测试环境不触发）
    if (_isLoggedIn && ApiConfig.isLive) {
      _syncMeSilently();
    }
    notifyListeners();
  }

  /// 用服务端最新资料刷新本地（失败静默，沿用本地缓存）。
  Future<void> _syncMeSilently() async {
    try {
      final fresh = await AppServices.instance.users.fetchMe();
      if (!_isLoggedIn) return;
      _user = fresh;
      await StorageService.saveUser(fresh);
      notifyListeners();
    } on ApiException {
      // 网络/会话异常均不阻塞启动流程
    }
  }

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  /// 登录成功后由登录页调用：以服务端返回的权威用户落地本地态。
  Future<void> applyLogin(AppUser user) async {
    _isLoggedIn = true;
    _user = user;
    _pets = await StorageService.loadPets();
    _records = await StorageService.loadRecords();
    await StorageService.saveUser(user);
    notifyListeners();
  }

  /// 更新用户资料（昵称/头像等）并持久化
  Future<void> updateUser(AppUser user) async {
    _user = user;
    await StorageService.saveUser(_user!);
    notifyListeners();
  }

  /// 用户主动登出：清本地态 + 通知服务端作废凭据（尽力而为）。
  Future<void> logout() async {
    _applySignedOut();
    try {
      await AppServices.instance.auth.logout();
    } catch (_) {
      // 服务端失败不影响本地已登出
    }
  }

  /// 会话被服务端判定失效（40104）时的强制登出回调入口。
  void _applySignedOut() {
    _isLoggedIn = false;
    _user = null;
    _pets = [];
    _records = [];
    notifyListeners();
    // 尽力清理：token 与持久化数据，天气定位一并清除（可接受，见开发计划 §八）
    StorageService.clearAll();
    AppServices.instance.tokens.clear();
  }

  /// 个人资料编辑（M1）：以服务端回包为准写入本地。
  Future<void> patchProfile(AppUser serverEcho) async {
    if (!_isLoggedIn) return;
    _user = serverEcho;
    await StorageService.saveUser(serverEcho);
    notifyListeners();
  }

  Future<void> addPet(Pet pet) async {
    _pets.add(pet);
    await StorageService.savePets(_pets);
    notifyListeners();
  }

  Future<void> updatePet(Pet pet) async {
    final index = _pets.indexWhere((p) => p.id == pet.id);
    if (index != -1) {
      _pets[index] = pet;
      await StorageService.savePets(_pets);
      notifyListeners();
    }
  }

  Future<void> removePet(String petId) async {
    _pets.removeWhere((p) => p.id == petId);
    await StorageService.savePets(_pets);
    notifyListeners();
  }

  Future<void> addRecord(ExerciseRecord record) async {
    _records.add(record);
    await StorageService.saveRecords(_records);
    notifyListeners();
  }

  int getTodayExerciseMinutes(String petId) {
    final today = DateTime.now();
    int total = 0;
    for (final r in _records) {
      if (r.petId == petId &&
          r.startTime.year == today.year &&
          r.startTime.month == today.month &&
          r.startTime.day == today.day) {
        total += r.durationMinutes;
      }
    }
    return total;
  }

  List<CheckInRecord> getMonthlyCheckIns(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return List.generate(daysInMonth, (index) {
      final date = DateTime(year, month, index + 1);
      final isChecked = _records.any((r) =>
        r.startTime.year == date.year &&
        r.startTime.month == date.month &&
        r.startTime.day == date.day &&
        r.canCheckIn
      );
      return CheckInRecord(date: date, isChecked: isChecked);
    });
  }
}

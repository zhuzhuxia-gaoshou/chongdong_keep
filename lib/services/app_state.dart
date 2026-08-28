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
    // Live 模式下静默复同步个人资料与宠物列表（Mock/测试环境不触发：
    // 冷启动后 Mock 内存态已丢凭据，误触发会连锁刷新→强制登出）
    if (_isLoggedIn && ApiConfig.isLive) {
      _syncMeSilently();
      _syncPetsSilently();
    }
    notifyListeners();
  }

  /// 云端拉宠物列表，本地缓存兜底（失败静默，不阻塞启动/登录）。
  Future<void> _syncPetsSilently() async {
    try {
      final server = await AppServices.instance.pets.fetchPets();
      if (!_isLoggedIn) return;
      _pets = server;
      await StorageService.savePets(_pets);
      notifyListeners();
    } on ApiException {
      // 网络/会话异常沿用本地缓存（同 _syncMeSilently 语义）
    }
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
    // 登录链路刚建好凭据，Mock/Live 均可安全拉取云端宠物列表
    _syncPetsSilently();
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

  /// 新增宠物（M2）：服务端权威——id/派生字段以回包为准；
  /// 业务/网络异常原样上抛，由页面提示 friendlyMessage。
  Future<Pet> addPet(Pet pet) async {
    final created = await AppServices.instance.pets.createPet(pet);
    _pets.add(created);
    await StorageService.savePets(_pets);
    notifyListeners();
    return created;
  }

  /// 编辑宠物（M2）：PATCH 回包替换本地条目。
  Future<Pet> updatePet(Pet pet) async {
    final echo = await AppServices.instance.pets.patchPet(pet);
    final index = _pets.indexWhere((p) => p.id == echo.id);
    if (index != -1) {
      _pets[index] = echo;
    } else {
      _pets.add(echo);
    }
    await StorageService.savePets(_pets);
    notifyListeners();
    return echo;
  }

  /// 删除宠物（M2，服务端软删）：运动记录保留供历史周报。
  Future<void> removePet(String petId) async {
    await AppServices.instance.pets.deletePet(petId);
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
          r.canCheckIn);
      return CheckInRecord(date: date, isChecked: isChecked);
    });
  }
}

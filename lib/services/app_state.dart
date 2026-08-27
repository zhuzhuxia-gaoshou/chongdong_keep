import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../models/user.dart';
import '../models/exercise_record.dart';
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
    notifyListeners();
  }

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  Future<void> login(String phone) async {
    _isLoggedIn = true;
    _user = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      phone: phone,
      nickname: '铲屎官',
      createdAt: DateTime.now(),
    );
    await StorageService.saveUser(_user!);
    notifyListeners();
  }

  /// 更新用户资料（昵称/头像等）并持久化
  Future<void> updateUser(AppUser user) async {
    _user = user;
    await StorageService.saveUser(_user!);
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _user = null;
    _pets = [];
    _records = [];
    await StorageService.clearAll();
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

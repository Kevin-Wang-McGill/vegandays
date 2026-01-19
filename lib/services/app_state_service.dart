import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/app_state.dart';
import '../models/sanctuary_animal.dart';
import '../models/diet_type.dart';
import '../constants/prefs_keys.dart';

class AppStateService extends ChangeNotifier {
  static final AppStateService instance = AppStateService._internal();
  factory AppStateService() => instance;
  AppStateService._internal();

  static const String _stateKey = 'app_state';
  static const int BEANS_PER_DAY = 10; // Legacy fallback (older builds)
  static const int defaultMeatGramsPerDay = 282; // 227 lb/year → 282 g/day

  AppState _state = AppState();
  AppState get state => _state;

  // User prefs (kept in memory for instant UI refresh)
  String _nickname = '';
  DietType _dietType = DietType.vegan;
  int _dailyMeatSavedGrams = defaultMeatGramsPerDay; // always 1:1 with beans/day

  String get nickname => _nickname;
  DietType get dietType => _dietType;
  int get dailyMeatSavedGrams => _dailyMeatSavedGrams;
  int get dailyBeansPerDay => _dailyMeatSavedGrams + (_dietType == DietType.vegan ? 20 : 0); // Vegan bonus: +20 beans/day
  int get totalSavedGrams => state.impactedDays * _dailyMeatSavedGrams;
  int get totalSavedBeans => state.impactedDays * dailyBeansPerDay;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateAndNormalizePrefs(prefs);
    await _loadUserPrefs(prefs);
    await _loadState(prefs);
    await _ensureStartDateLoadedFromPrefsIfMissing(prefs);

    // Keep impact numbers consistent with "startDate → today" rule on app launch.
    if (_state.startDate != null) {
      await recomputeImpactAndBalances();
    } else {
      notifyListeners();
    }
  }

  Future<void> _loadState(SharedPreferences prefs) async {
    final stateJson = prefs.getString(_stateKey);
    if (stateJson != null) {
      try {
        _state = AppState.fromJson(jsonDecode(stateJson));
      } catch (e) {
        _state = AppState();
      }
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateKey, jsonEncode(_state.toJson()));
  }

  DateTime _getTodayMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  int _calculateImpactedDays(DateTime startMidnight, DateTime todayMidnight) {
    final diff = todayMidnight.difference(startMidnight);
    return (diff.inDays + 1).clamp(1, double.infinity).toInt();
  }

  Future<void> initializeOnboarding(DateTime startDate) async {
    final prefs = await SharedPreferences.getInstance();
    // Ensure grams/day prefs exist & are in sync before we compute state.
    await _migrateAndNormalizePrefs(prefs);
    await _loadUserPrefs(prefs);

    final startMidnight = DateTime(startDate.year, startDate.month, startDate.day);
    final todayMidnight = _getTodayMidnight();
    final impactedDays = _calculateImpactedDays(startMidnight, todayMidnight);

    _state = AppState(
      startDate: startMidnight,
      impactedDays: impactedDays,
      beans: 0, // Will be calculated by recomputeImpactAndBalances
      lastCheckInDate: null, // User must manually check in to get today's beans
      animalCounts: {
        AnimalType.cow: 0,
        AnimalType.sheep: 0,
        AnimalType.pig: 0,
        AnimalType.chicken: 0,
      },
      sanctuaryAnimals: [],
    );
    await _saveState();
    await recomputeImpactAndBalances(); // will notifyListeners()
  }

  String _getTodayString() {
    return DateFormat('yyyy-MM-dd').format(_getTodayMidnight());
  }

  bool canCheckIn() {
    final todayStr = _getTodayString();
    return _state.lastCheckInDate != todayStr;
  }

  Future<bool> checkIn() async {
    final todayStr = _getTodayString();
    if (_state.lastCheckInDate == todayStr) {
      return false;
    }
    _state.lastCheckInDate = todayStr;

    // Keep numbers consistent (earned-spent, local-midnight day count)
    await recomputeImpactAndBalances();
    return true;
  }

  bool canExchange(AnimalType type) {
    return _state.beans >= type.cost;
  }

  Future<bool> exchangeAnimal(AnimalType type) async {
    if (!canExchange(type)) {
      return false;
    }

    _state.beans -= type.cost;
    _state.animalCounts[type] = (_state.animalCounts[type] ?? 0) + 1;

    // 生成新动物位置（在草地上，避开池塘）
    // 坐标系统：x, y 都是 0-100 的百分比
    final random = Random();
    final minDistance = 12.0;
    double? newX, newY;
    int attempts = 0;
    const maxAttempts = 12;

    // 池塘位置（相对于屏幕的百分比，0-100）
    // pond left: 0.4 * w = 40%, width: 0.6 * w = 60%, 所以 right = 100%
    // pond bottom: 0.32 * grassH, grassH = 50% of h, 所以 bottom = 16% of h
    // 假设池塘高度约为宽度的 0.6 倍（根据图片比例），60% * 0.6 = 36%
    final pondLeft = 40.0;
    final pondRight = 100.0; // 延伸到屏幕右边缘
    final pondBottom = 16.0; // 距离屏幕底部 16%
    final pondTop = pondBottom + 36.0; // 池塘高度约为宽度的 0.6 倍
    final pondMargin = 3.0; // 安全边距 3%

    // 按钮区域（Check in 按钮 + 文字）
    // 按钮高度约 56px，间距 9px，文字高度约 20px，底部间距 10px
    // 总高度约 95px，在 844px 屏幕上约为 11.3%，加上安全边距设为 15%
    final buttonAreaTop = 15.0; // 距离底部 15% 以上才能生成动物
    final buttonAreaLeft = 0.0; // 按钮是全宽的
    final buttonAreaRight = 100.0;

    while (attempts < maxAttempts) {
      // 在草地区域生成位置：x 在 10-90% 之间，y 在草地区域（距离底部 15-40%）
      // y 坐标系统：0 = 底部，100 = 顶部
      // 注意：y 必须 > 15% 以避免遮挡按钮
      newX = 10 + random.nextDouble() * 80; // 10-90
      newY = buttonAreaTop + random.nextDouble() * (40.0 - buttonAreaTop); // 15-40（在草地区域内，距离底部，避开按钮）

      // 检查是否与按钮区域重叠
      final overlapsButton = newX! >= buttonAreaLeft && 
                            newX <= buttonAreaRight &&
                            newY! < buttonAreaTop;

      if (overlapsButton) {
        attempts++;
        continue;
      }

      // 检查是否与池塘重叠（考虑安全边距）
      // 池塘位置：bottom=16%, top=52%（从底部计算）
      final overlapsPond = newX >= (pondLeft - pondMargin) && 
                          newX <= (pondRight + pondMargin) &&
                          newY >= (pondBottom - pondMargin) && 
                          newY <= (pondTop + pondMargin);

      if (overlapsPond) {
        attempts++;
        continue;
      }

      // 检查是否与其他动物重叠
      bool overlap = false;
      for (final animal in _state.sanctuaryAnimals) {
        final distance = sqrt(
          pow(animal.x - newX, 2) + pow(animal.y - newY, 2),
        );
        if (distance < minDistance) {
          overlap = true;
          break;
        }
      }

      if (!overlap) {
        break;
      }
      attempts++;
    }

    if (newX == null || newY == null) {
      // 如果所有尝试都失败，强制放到池塘左侧安全区，避开按钮区域
      newX = 10 + random.nextDouble() * (pondLeft - pondMargin - 10);
      newY = buttonAreaTop + random.nextDouble() * (40.0 - buttonAreaTop); // 在草地区域，避开按钮
    }

    final newAnimal = SanctuaryAnimal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      x: newX,
      y: newY,
    );

    _state.sanctuaryAnimals.add(newAnimal);
    await _saveState();
    notifyListeners();
    return true;
  }

  Future<void> updateStartDate(DateTime newStartDate) async {
    final startMidnight = DateTime(newStartDate.year, newStartDate.month, newStartDate.day);
    _state = _state.copyWith(startDate: startMidnight);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.startDate, DateFormat('yyyy-MM-dd').format(startMidnight));

    await recomputeImpactAndBalances(); // will save + notify
  }

  Future<void> updateDailyMeatSavedGrams(int gramsPerDay) async {
    final newValue = gramsPerDay.clamp(1, 1000000);
    _dailyMeatSavedGrams = newValue;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefsKeys.dailyMeatSavedGrams, _dailyMeatSavedGrams);
    await prefs.setInt(PrefsKeys.dailyBeansPerDay, _dailyMeatSavedGrams); // keep legacy key in sync

    await recomputeImpactAndBalances(); // will save + notify
  }

  Future<void> resetDailyMeatSavedToDefault() async {
    await updateDailyMeatSavedGrams(defaultMeatGramsPerDay);
  }

  /// Reset all animals and refund the beans spent on them
  Future<void> resetAnimals() async {
    // Calculate total beans to refund
    final totalSpentBeans = _calculateTotalSpentBeans(_state.animalCounts);
    
    // Reset animal counts and sanctuary animals
    _state = _state.copyWith(
      animalCounts: {
        AnimalType.cow: 0,
        AnimalType.sheep: 0,
        AnimalType.pig: 0,
        AnimalType.chicken: 0,
      },
      sanctuaryAnimals: [],
      beans: _state.beans + totalSpentBeans, // Refund beans
    );
    
    await _saveState();
    notifyListeners();
  }

  Future<void> updateNickname(String nickname) async {
    final trimmed = nickname.trim();
    _nickname = trimmed;
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(PrefsKeys.nickname);
    } else {
      await prefs.setString(PrefsKeys.nickname, trimmed);
    }
    notifyListeners();
  }

  Future<void> updateDietType(DietType dietType) async {
    _dietType = dietType;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.dietType, dietType.storageKey);
    notifyListeners();
  }

  /// Unified recompute entry when startDate or grams/day changes.
  /// - impactedDays = dateDiffInDays(startDate, today) + 1 (local midnight, clamp >= 1)
  /// - earnedBeans = checkedInDays * dailyBeansPerDay
  ///   - checkedInDays = impactedDays - 1 if today not checked in, else impactedDays
  /// - spentBeans = Σ(count[type] * cost[type])
  /// - beansBalance = max(0, earnedBeans - spentBeans)
  Future<void> recomputeImpactAndBalances() async {
    if (_state.startDate == null) return;

    final startMidnight = DateTime(
      _state.startDate!.year,
      _state.startDate!.month,
      _state.startDate!.day,
    );
    final todayMidnight = _getTodayMidnight();
    final impactedDays = _calculateImpactedDays(startMidnight, todayMidnight);

    // Check if today is already checked in
    final todayStr = _getTodayString();
    final todayCheckedIn = _state.lastCheckInDate == todayStr;
    
    // Beans are only earned for days that have been checked in
    // If today not checked in yet, we don't count today's beans
    final checkedInDays = todayCheckedIn ? impactedDays : max(0, impactedDays - 1);

    final totalSpentBeans = _calculateTotalSpentBeans(_state.animalCounts);
    final totalEarnedBeans = checkedInDays * dailyBeansPerDay;
    final beansBalance = max(0, totalEarnedBeans - totalSpentBeans);

    _state = _state.copyWith(
      startDate: startMidnight,
      impactedDays: impactedDays,
      beans: beansBalance,
    );

    await _saveState();
    notifyListeners();
  }

  int _calculateTotalSpentBeans(Map<AnimalType, int> counts) {
    var total = 0;
    for (final entry in counts.entries) {
      total += entry.value * entry.key.cost;
    }
    return total;
  }

  Future<void> _loadUserPrefs(SharedPreferences prefs) async {
    _nickname = (prefs.getString(PrefsKeys.nickname) ?? '').trim();

    final dietKey = prefs.getString(PrefsKeys.dietType);
    _dietType = DietTypeExtension.fromStorageKey(dietKey) ?? DietType.vegan;

    // dailyMeatSavedGrams is already normalized in migration step, just read it.
    _dailyMeatSavedGrams =
        prefs.getInt(PrefsKeys.dailyMeatSavedGrams) ?? defaultMeatGramsPerDay;
  }

  Future<void> _ensureStartDateLoadedFromPrefsIfMissing(SharedPreferences prefs) async {
    if (_state.startDate != null) return;
    final startStr = prefs.getString(PrefsKeys.startDate);
    if (startStr == null) return;

    try {
      final parsed = DateTime.parse(startStr);
      _state = _state.copyWith(
        startDate: DateTime(parsed.year, parsed.month, parsed.day),
      );
      await _saveState();
    } catch (_) {
      // ignore
    }
  }

  Future<void> _migrateAndNormalizePrefs(SharedPreferences prefs) async {
    final int? meat = prefs.getInt(PrefsKeys.dailyMeatSavedGrams);
    final int? beans = prefs.getInt(PrefsKeys.dailyBeansPerDay);

    int normalized;
    if (meat == null && beans == null) {
      normalized = defaultMeatGramsPerDay;
    } else if (meat == null && beans != null) {
      normalized = beans;
    } else if (meat != null && beans == null) {
      normalized = meat;
    } else {
      // both present but might be out of sync; enforce 1:1 (prefer meat as source of truth)
      normalized = meat!;
    }

    normalized = normalized.clamp(1, 1000000);
    await prefs.setInt(PrefsKeys.dailyMeatSavedGrams, normalized);
    await prefs.setInt(PrefsKeys.dailyBeansPerDay, normalized);
    _dailyMeatSavedGrams = normalized;
  }

  Future<void> resetData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _state = AppState();
    _nickname = '';
    _dietType = DietType.vegan;
    _dailyMeatSavedGrams = defaultMeatGramsPerDay;
    notifyListeners();
  }
}



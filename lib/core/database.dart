import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDatabase {
  static const String keyMedicines = 'orma_dose_medicines';
  static const String keyLogs = 'orma_dose_logs';
  static const String keyFamily = 'orma_dose_family';
  static const String keyActiveProfileId = 'orma_dose_active_profile_id';
  static const String keyThemeMode = 'orma_dose_theme_mode';
  static const String keyPrescriptions = 'orma_dose_prescriptions';
  static const String keyStreak = 'orma_dose_streak';
  static const String keyLastStreakDate = 'orma_dose_last_streak_date';

  // Singleton Instance
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Generic JSON storage helpers
  Future<bool> _saveString(String key, String value) async {
    await init();
    return _prefs!.setString(key, value);
  }

  Future<String?> _getString(String key) async {
    await init();
    return _prefs!.getString(key);
  }

  // --- Theme ---
  Future<void> saveThemeMode(bool isDarkMode) async {
    await init();
    await _prefs!.setBool(keyThemeMode, isDarkMode);
  }

  Future<bool?> getThemeMode() async {
    await init();
    return _prefs!.getBool(keyThemeMode);
  }

  // --- Active Family Profile ID ---
  Future<void> saveActiveProfileId(String profileId) async {
    await _saveString(keyActiveProfileId, profileId);
  }

  Future<String?> getActiveProfileId() async {
    return await _getString(keyActiveProfileId);
  }

  // --- Medicines list serialization ---
  Future<void> saveMedicines(List<Map<String, dynamic>> medicinesJson) async {
    final raw = jsonEncode(medicinesJson);
    await _saveString(keyMedicines, raw);
  }

  Future<List<Map<String, dynamic>>> getMedicines() async {
    final raw = await _getString(keyMedicines);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Logs list serialization ---
  Future<void> saveLogs(List<Map<String, dynamic>> logsJson) async {
    final raw = jsonEncode(logsJson);
    await _saveString(keyLogs, raw);
  }

  Future<List<Map<String, dynamic>>> getLogs() async {
    final raw = await _getString(keyLogs);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Family list serialization ---
  Future<void> saveFamily(List<Map<String, dynamic>> familyJson) async {
    final raw = jsonEncode(familyJson);
    await _saveString(keyFamily, raw);
  }

  Future<List<Map<String, dynamic>>> getFamily() async {
    final raw = await _getString(keyFamily);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Prescriptions list serialization ---
  Future<void> savePrescriptions(List<Map<String, dynamic>> prescriptionsJson) async {
    final raw = jsonEncode(prescriptionsJson);
    await _saveString(keyPrescriptions, raw);
  }

  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    final raw = await _getString(keyPrescriptions);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Streak ---
  Future<void> saveStreak(int streak) async {
    await init();
    await _prefs!.setInt(keyStreak, streak);
  }

  Future<int> getStreak() async {
    await init();
    return _prefs!.getInt(keyStreak) ?? 0;
  }

  Future<void> saveLastStreakDate(String dateStr) async {
    await _saveString(keyLastStreakDate, dateStr);
  }

  Future<String?> getLastStreakDate() async {
    return await _getString(keyLastStreakDate);
  }

  // Reset database (for testing / fresh starts)
  Future<void> clearAll() async {
    await init();
    await _prefs!.clear();
  }
}

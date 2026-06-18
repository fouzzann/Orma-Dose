import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orma_dose/core/database.dart';
import 'package:orma_dose/models/medicine.dart';
import 'package:orma_dose/models/family_member.dart';
import 'package:orma_dose/models/history_log.dart';
import 'package:orma_dose/models/prescription.dart';

class ReminderData {
  final Medicine medicine;
  final String time;
  final DateTime date;
  ReminderData({required this.medicine, required this.time, required this.date});
}

class AppStateProvider extends ChangeNotifier {
  final LocalDatabase _db = LocalDatabase();

  // Settings & Theme
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // Active user profile
  String _activeProfileId = '';
  String get activeProfileId => _activeProfileId;

  // Streak tracking
  int _streak = 0;
  int get streak => _streak;

  // Lists
  List<FamilyMember> _familyMembers = [];
  List<Medicine> _medicines = [];
  List<HistoryLog> _historyLogs = [];
  List<Prescription> _prescriptions = [];

  List<FamilyMember> get familyMembers => _familyMembers;
  List<Medicine> get medicines => _medicines;
  List<HistoryLog> get historyLogs => _historyLogs;
  List<Prescription> get prescriptions => _prescriptions;

  // Filters profiles
  List<Medicine> get activeMedicines =>
      _medicines.where((m) => m.familyMemberId == _activeProfileId && !m.isArchived).toList();

  List<HistoryLog> get activeHistoryLogs =>
      _historyLogs.where((l) => l.familyMemberId == _activeProfileId).toList();

  List<Prescription> get activePrescriptions =>
      _prescriptions.where((p) => p.familyMemberId == _activeProfileId).toList();

  FamilyMember? get activeProfile {
    if (_familyMembers.isEmpty) return null;
    return _familyMembers.firstWhere(
      (m) => m.id == _activeProfileId,
      orElse: () => _familyMembers.first,
    );
  }

  // Active Reminder Overlay State
  ReminderData? _activeReminder;
  ReminderData? get activeReminder => _activeReminder;

  // Loading indicator
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AppStateProvider() {
    _initData();
  }

  Future<void> _initData() async {
    _isLoading = true;
    notifyListeners();

    await _db.init();

    // Check Theme
    final savedTheme = await _db.getThemeMode();
    if (savedTheme != null) {
      _isDarkMode = savedTheme;
    }

    // Load Family Members
    final rawFamily = await _db.getFamily();
    if (rawFamily.isEmpty) {
      // Build first-time pre-populated demo data
      await _buildDemoData();
    } else {
      _familyMembers = rawFamily.map((e) => FamilyMember.fromJson(e)).toList();
      
      // Load Active Profile ID
      final savedProfileId = await _db.getActiveProfileId();
      if (savedProfileId != null && _familyMembers.any((m) => m.id == savedProfileId)) {
        _activeProfileId = savedProfileId;
      } else {
        _activeProfileId = _familyMembers.first.id;
      }

      // Load medicines
      final rawMeds = await _db.getMedicines();
      _medicines = rawMeds.map((e) => Medicine.fromJson(e)).toList();

      // Load history logs
      final rawLogs = await _db.getLogs();
      _historyLogs = rawLogs.map((e) => HistoryLog.fromJson(e)).toList();

      // Load prescriptions
      final rawPrescr = await _db.getPrescriptions();
      _prescriptions = rawPrescr.map((e) => Prescription.fromJson(e)).toList();

      // Load Streak
      _streak = await _db.getStreak();
    }

    _isLoading = false;
    _checkAndFlagMissedDoses();
    _recalculateStreaks();
    notifyListeners();
  }

  // Generate complete, beautiful medical scenario logs for testing and demo
  Future<void> _buildDemoData() async {
    final self = FamilyMember(id: 'self', name: 'Fouzan', relation: 'Self', avatarIndex: 0);
    final mom = FamilyMember(id: 'mom', name: 'Sarah (Mom)', relation: 'Parent', avatarIndex: 1);
    final dad = FamilyMember(id: 'dad', name: 'Imran (Dad)', relation: 'Parent', avatarIndex: 2);

    _familyMembers = [self, mom, dad];
    _activeProfileId = self.id;
    await _db.saveFamily(_familyMembers.map((e) => e.toJson()).toList());
    await _db.saveActiveProfileId(_activeProfileId);

    // Medicines for Fouzan
    final m1 = Medicine(
      id: 'med_self_1',
      name: 'Paracetamol',
      dosage: '500mg (1 Tablet)',
      type: 'tablet',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 30)),
      frequencyType: 'daily',
      selectedDays: [],
      reminderTimes: ['08:00', '20:00'],
      initialStock: 60,
      remainingStock: 24,
      refillThreshold: 10,
      familyMemberId: self.id,
    );

    final m2 = Medicine(
      id: 'med_self_2',
      name: 'Omega 3 Fish Oil',
      dosage: '1000mg (1 Capsule)',
      type: 'capsule',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 90)),
      frequencyType: 'daily',
      selectedDays: [],
      reminderTimes: ['09:00'],
      initialStock: 90,
      remainingStock: 62,
      refillThreshold: 15,
      familyMemberId: self.id,
    );

    final m3 = Medicine(
      id: 'med_self_3',
      name: 'Cough Syrup',
      dosage: '10ml (2 Spoonfuls)',
      type: 'syrup',
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 5)),
      frequencyType: 'daily',
      selectedDays: [],
      reminderTimes: ['14:00'],
      initialStock: 200,
      remainingStock: 160,
      refillThreshold: 50,
      familyMemberId: self.id,
    );

    // Medicines for Mom (Sarah)
    final m4 = Medicine(
      id: 'med_mom_1',
      name: 'Atorvastatin (Cholesterol)',
      dosage: '20mg (1 Tablet)',
      type: 'tablet',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 180)),
      frequencyType: 'daily',
      selectedDays: [],
      reminderTimes: ['21:00'],
      initialStock: 30,
      remainingStock: 3, // Trigger stock warning!
      refillThreshold: 5,
      familyMemberId: mom.id,
    );

    final m5 = Medicine(
      id: 'med_mom_2',
      name: 'Metformin (Diabetes)',
      dosage: '500mg (1 Tablet)',
      type: 'tablet',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 180)),
      frequencyType: 'daily',
      selectedDays: [],
      reminderTimes: ['08:30', '20:30'],
      initialStock: 100,
      remainingStock: 48,
      refillThreshold: 14,
      familyMemberId: mom.id,
    );

    // Medicines for Dad (Imran)
    final m6 = Medicine(
      id: 'med_dad_1',
      name: 'Amlodipine (Blood Pressure)',
      dosage: '5mg (1 Tablet)',
      type: 'tablet',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 360)),
      frequencyType: 'daily',
      selectedDays: [],
      reminderTimes: ['08:00'],
      initialStock: 30,
      remainingStock: 15,
      refillThreshold: 5,
      familyMemberId: dad.id,
    );

    _medicines = [m1, m2, m3, m4, m5, m6];
    await _db.saveMedicines(_medicines.map((e) => e.toJson()).toList());

    // Generate historical history logs for last 14 days (Adherence charts)
    _historyLogs = [];
    final rand = Random();
    final today = DateTime.now();

    for (int dayOffset = 14; dayOffset >= 0; dayOffset--) {
      final logDate = today.subtract(Duration(days: dayOffset));
      final logDateStr = DateFormat('yyyy-MM-dd').format(logDate);

      for (var med in _medicines) {
        // Skip medicines if they weren't active yet
        if (logDate.isBefore(med.startDate) || logDate.isAfter(med.endDate)) continue;

        for (var timeStr in med.reminderTimes) {
          final parts = timeStr.split(':');
          final schedHour = int.parse(parts[0]);
          final schedMin = int.parse(parts[1]);
          final scheduledTime = DateTime(
            logDate.year,
            logDate.month,
            logDate.day,
            schedHour,
            schedMin,
          );

          // If it is today and the time hasn't passed, do not generate a log
          if (scheduledTime.isAfter(today)) continue;

          // Compliance generation: 85% compliance rate
          String status = 'taken';
          final roll = rand.nextDouble();
          if (roll > 0.93) {
            status = 'skipped';
          } else if (roll > 0.86) {
            status = 'missed';
          }

          _historyLogs.add(HistoryLog(
            id: 'log_${med.id}_${logDateStr}_${timeStr.replaceAll(':', '')}',
            medicineId: med.id,
            medicineName: med.name,
            dosage: med.dosage,
            type: med.type,
            scheduledTime: scheduledTime,
            actionTime: status == 'taken' 
                ? scheduledTime.add(Duration(minutes: rand.nextInt(30))) 
                : null,
            status: status,
            familyMemberId: med.familyMemberId,
          ));
        }
      }
    }
    await _db.saveLogs(_historyLogs.map((e) => e.toJson()).toList());

    // Prescriptions Demo
    final presc1 = Prescription(
      id: 'presc_1',
      title: 'Monthly BP & Diabetes Checkup',
      doctorName: 'Dr. Robert Chen, Cardiologist',
      uploadDate: DateTime.now().subtract(const Duration(days: 12)),
      extractedMedicines: ['Metformin 500mg', 'Amlodipine 5mg'],
      imageAsset: 'prescription_stub.png',
      familyMemberId: mom.id,
    );

    final presc2 = Prescription(
      id: 'presc_2',
      title: 'General Wellness Vitamin Plan',
      doctorName: 'Dr. Sarah Smith, MD',
      uploadDate: DateTime.now().subtract(const Duration(days: 25)),
      extractedMedicines: ['Omega 3 Fish Oil 1000mg', 'Multi-vitamin Capsule'],
      imageAsset: 'prescription_stub.png',
      familyMemberId: self.id,
    );

    _prescriptions = [presc1, presc2];
    await _db.savePrescriptions(_prescriptions.map((e) => e.toJson()).toList());

    _streak = 5; // Start with a 5 day streak
    await _db.saveStreak(_streak);
    await _db.saveLastStreakDate(DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 1))));
  }

  // Checks and tags doses in the past today that are not taken/skipped as missed
  void _checkAndFlagMissedDoses() {
    final now = DateTime.now();
    bool hasChanges = false;

    for (var med in _medicines) {
      if (now.isBefore(med.startDate) || now.isAfter(med.endDate)) continue;

      for (var timeStr in med.reminderTimes) {
        final parts = timeStr.split(':');
        final schedHour = int.parse(parts[0]);
        final schedMin = int.parse(parts[1]);
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          schedHour,
          schedMin,
        );

        // If the dose was scheduled in the past (more than 1 hour ago) and we don't have a log for it yet
        if (scheduledTime.isBefore(now.subtract(const Duration(hours: 1)))) {
          final logId = 'log_${med.id}_${DateFormat('yyyy-MM-dd').format(now)}_${timeStr.replaceAll(':', '')}';
          
          final exists = _historyLogs.any((l) => l.id == logId);
          if (!exists) {
            _historyLogs.add(HistoryLog(
              id: logId,
              medicineId: med.id,
              medicineName: med.name,
              dosage: med.dosage,
              type: med.type,
              scheduledTime: scheduledTime,
              status: 'missed',
              familyMemberId: med.familyMemberId,
            ));
            hasChanges = true;
          }
        }
      }
    }

    if (hasChanges) {
      _db.saveLogs(_historyLogs.map((e) => e.toJson()).toList());
    }
  }

  // Calculate streaks: consecutive days in the past where all scheduled doses were taken
  void _recalculateStreaks() {
    final now = DateTime.now();
    int currentStreak = 0;
    
    // Check backwards from yesterday
    for (int i = 1; i <= 30; i++) {
      final dateToCheck = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(dateToCheck);
      
      // Get all scheduled history logs for this active member on this day
      final dailyLogs = activeHistoryLogs.where((l) {
        final logDateStr = DateFormat('yyyy-MM-dd').format(l.scheduledTime);
        return logDateStr == dateStr;
      }).toList();

      if (dailyLogs.isEmpty) {
        // If no medicines were scheduled, count as a free pass (does not break streak)
        continue;
      }

      // If there are logs, did we take all of them? (i.e. zero missed)
      final hasMissed = dailyLogs.any((l) => l.status == 'missed');
      final takenCount = dailyLogs.where((l) => l.status == 'taken').length;
      
      if (!hasMissed && takenCount > 0) {
        currentStreak++;
      } else {
        break; // Streak broken
      }
    }

    _streak = currentStreak;
    _db.saveStreak(_streak);
  }

  // --- ACTIONS ---

  // Set active family profile
  Future<void> setActiveProfile(String profileId) async {
    _activeProfileId = profileId;
    await _db.saveActiveProfileId(profileId);
    _recalculateStreaks();
    notifyListeners();
  }

  // Toggle theme mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _db.saveThemeMode(_isDarkMode);
    notifyListeners();
  }

  // Add a family member profile
  Future<void> addFamilyMember(String name, String relation, int avatarIndex) async {
    final id = 'fam_${DateTime.now().millisecondsSinceEpoch}';
    final member = FamilyMember(id: id, name: name, relation: relation, avatarIndex: avatarIndex);
    _familyMembers.add(member);
    await _db.saveFamily(_familyMembers.map((e) => e.toJson()).toList());
    
    // Auto switch to new member
    await setActiveProfile(id);
  }

  // Delete family member profile and associated meds/logs
  Future<void> deleteFamilyMember(String id) async {
    if (id == 'self') return; // Cannot delete self
    _familyMembers.removeWhere((m) => m.id == id);
    _medicines.removeWhere((m) => m.familyMemberId == id);
    _historyLogs.removeWhere((l) => l.familyMemberId == id);
    _prescriptions.removeWhere((p) => p.familyMemberId == id);
    
    await _db.saveFamily(_familyMembers.map((e) => e.toJson()).toList());
    await _db.saveMedicines(_medicines.map((e) => e.toJson()).toList());
    await _db.saveLogs(_historyLogs.map((e) => e.toJson()).toList());
    await _db.savePrescriptions(_prescriptions.map((e) => e.toJson()).toList());

    if (_activeProfileId == id) {
      _activeProfileId = 'self';
      await _db.saveActiveProfileId('self');
    }
    _recalculateStreaks();
    notifyListeners();
  }

  // Add a new medication
  Future<void> addMedicine(Medicine med) async {
    _medicines.add(med);
    await _db.saveMedicines(_medicines.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  // Update an existing medication
  Future<void> updateMedicine(Medicine updated) async {
    final index = _medicines.indexWhere((m) => m.id == updated.id);
    if (index != -1) {
      _medicines[index] = updated;
      await _db.saveMedicines(_medicines.map((e) => e.toJson()).toList());
      notifyListeners();
    }
  }

  // Delete a medication
  Future<void> deleteMedicine(String id) async {
    _medicines.removeWhere((m) => m.id == id);
    _historyLogs.removeWhere((l) => l.medicineId == id); // Also clear logs for clean slate
    await _db.saveMedicines(_medicines.map((e) => e.toJson()).toList());
    await _db.saveLogs(_historyLogs.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  // Log medication as TAKEN
  Future<void> takeMedicine(Medicine med, String timeStr, DateTime scheduledDate) async {
    final logId = 'log_${med.id}_${DateFormat('yyyy-MM-dd').format(scheduledDate)}_${timeStr.replaceAll(':', '')}';
    
    // Remove existing log for this scheduled slot (e.g. if replacing a missed status)
    _historyLogs.removeWhere((l) => l.id == logId);

    _historyLogs.add(HistoryLog(
      id: logId,
      medicineId: med.id,
      medicineName: med.name,
      dosage: med.dosage,
      type: med.type,
      scheduledTime: scheduledDate,
      actionTime: DateTime.now(),
      status: 'taken',
      familyMemberId: med.familyMemberId,
    ));

    // Deduct stock
    final index = _medicines.indexWhere((m) => m.id == med.id);
    if (index != -1) {
      final currentStock = _medicines[index].remainingStock;
      final type = _medicines[index].type;
      
      // Syrup/Cream doesn't deduct 1 item, but we deduct 1 dose equivalent
      int deduct = 1;
      if (type == 'syrup') deduct = 10; // deduct 10ml
      
      final nextStock = max(0, currentStock - deduct);
      _medicines[index] = _medicines[index].copyWith(remainingStock: nextStock);
      await _db.saveMedicines(_medicines.map((e) => e.toJson()).toList());
    }

    await _db.saveLogs(_historyLogs.map((e) => e.toJson()).toList());
    _recalculateStreaks();
    
    // Dismiss overlay if active
    if (_activeReminder?.medicine.id == med.id && _activeReminder?.time == timeStr) {
      _activeReminder = null;
    }
    notifyListeners();
  }

  // Log medication as SKIPPED
  Future<void> skipMedicine(Medicine med, String timeStr, DateTime scheduledDate) async {
    final logId = 'log_${med.id}_${DateFormat('yyyy-MM-dd').format(scheduledDate)}_${timeStr.replaceAll(':', '')}';
    
    _historyLogs.removeWhere((l) => l.id == logId);
    _historyLogs.add(HistoryLog(
      id: logId,
      medicineId: med.id,
      medicineName: med.name,
      dosage: med.dosage,
      type: med.type,
      scheduledTime: scheduledDate,
      actionTime: DateTime.now(),
      status: 'skipped',
      familyMemberId: med.familyMemberId,
    ));

    await _db.saveLogs(_historyLogs.map((e) => e.toJson()).toList());
    _recalculateStreaks();

    if (_activeReminder?.medicine.id == med.id && _activeReminder?.time == timeStr) {
      _activeReminder = null;
    }
    notifyListeners();
  }

  // Refill medication tablets
  Future<void> refillMedicine(String id, int refillAmount) async {
    final index = _medicines.indexWhere((m) => m.id == id);
    if (index != -1) {
      final updatedStock = _medicines[index].remainingStock + refillAmount;
      _medicines[index] = _medicines[index].copyWith(remainingStock: updatedStock);
      await _db.saveMedicines(_medicines.map((e) => e.toJson()).toList());
      notifyListeners();
    }
  }

  // Upload digital prescription
  Future<void> uploadPrescription(String title, String doctorName, List<String> extractedMeds) async {
    final id = 'presc_${DateTime.now().millisecondsSinceEpoch}';
    final prescription = Prescription(
      id: id,
      title: title,
      doctorName: doctorName,
      uploadDate: DateTime.now(),
      extractedMedicines: extractedMeds,
      imageAsset: 'prescription_stub.png',
      familyMemberId: _activeProfileId,
    );
    _prescriptions.add(prescription);
    await _db.savePrescriptions(_prescriptions.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  // Alert simulation triggers
  void triggerReminderMock(Medicine med, String timeStr) {
    final parts = timeStr.split(':');
    final schedHour = int.parse(parts[0]);
    final schedMin = int.parse(parts[1]);
    final now = DateTime.now();
    final scheduledDate = DateTime(now.year, now.month, now.day, schedHour, schedMin);
    
    _activeReminder = ReminderData(
      medicine: med,
      time: timeStr,
      date: scheduledDate,
    );
    notifyListeners();
  }

  void dismissReminder() {
    _activeReminder = null;
    notifyListeners();
  }

  Future<void> resetDatabase() async {
    _isLoading = true;
    notifyListeners();
    await _db.clearAll();
    await _buildDemoData();
    _checkAndFlagMissedDoses();
    _recalculateStreaks();
    _isLoading = false;
    notifyListeners();
  }
}

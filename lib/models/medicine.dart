class Medicine {
  final String id;
  final String name;
  final String dosage; // e.g. "1 Tablet", "10ml", "2 puffs"
  final String type; // "tablet", "capsule", "syrup", "injection", "drops", "cream"
  final DateTime startDate;
  final DateTime endDate;
  final String frequencyType; // "daily", "weekly", "interval"
  final List<int> selectedDays; // 1 = Mon, 7 = Sun for weekly schedule
  final List<String> reminderTimes; // e.g. ["08:00", "20:00"]
  final int initialStock;
  final int remainingStock;
  final bool isRefillAlertEnabled;
  final int refillThreshold;
  final String familyMemberId;
  final bool isArchived;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.frequencyType,
    required this.selectedDays,
    required this.reminderTimes,
    required this.initialStock,
    required this.remainingStock,
    this.isRefillAlertEnabled = true,
    this.refillThreshold = 5,
    required this.familyMemberId,
    this.isArchived = false,
  });

  Medicine copyWith({
    String? id,
    String? name,
    String? dosage,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? frequencyType,
    List<int>? selectedDays,
    List<String>? reminderTimes,
    int? initialStock,
    int? remainingStock,
    bool? isRefillAlertEnabled,
    int? refillThreshold,
    String? familyMemberId,
    bool? isArchived,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      frequencyType: frequencyType ?? this.frequencyType,
      selectedDays: selectedDays ?? this.selectedDays,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      initialStock: initialStock ?? this.initialStock,
      remainingStock: remainingStock ?? this.remainingStock,
      isRefillAlertEnabled: isRefillAlertEnabled ?? this.isRefillAlertEnabled,
      refillThreshold: refillThreshold ?? this.refillThreshold,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'type': type,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'frequencyType': frequencyType,
      'selectedDays': selectedDays,
      'reminderTimes': reminderTimes,
      'initialStock': initialStock,
      'remainingStock': remainingStock,
      'isRefillAlertEnabled': isRefillAlertEnabled,
      'refillThreshold': refillThreshold,
      'familyMemberId': familyMemberId,
      'isArchived': isArchived,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      type: json['type'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      frequencyType: json['frequencyType'] as String,
      selectedDays: List<int>.from(json['selectedDays'] as List? ?? []),
      reminderTimes: List<String>.from(json['reminderTimes'] as List? ?? []),
      initialStock: json['initialStock'] as int? ?? 0,
      remainingStock: json['remainingStock'] as int? ?? 0,
      isRefillAlertEnabled: json['isRefillAlertEnabled'] as bool? ?? true,
      refillThreshold: json['refillThreshold'] as int? ?? 5,
      familyMemberId: json['familyMemberId'] as String,
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }
}

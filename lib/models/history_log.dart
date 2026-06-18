class HistoryLog {
  final String id;
  final String medicineId;
  final String medicineName;
  final String dosage;
  final String type;
  final DateTime scheduledTime;
  final DateTime? actionTime;
  final String status; // "taken", "skipped", "missed"
  final String familyMemberId;

  HistoryLog({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.dosage,
    required this.type,
    required this.scheduledTime,
    this.actionTime,
    required this.status,
    required this.familyMemberId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'dosage': dosage,
      'type': type,
      'scheduledTime': scheduledTime.toIso8601String(),
      'actionTime': actionTime?.toIso8601String(),
      'status': status,
      'familyMemberId': familyMemberId,
    };
  }

  factory HistoryLog.fromJson(Map<String, dynamic> json) {
    return HistoryLog(
      id: json['id'] as String,
      medicineId: json['medicineId'] as String,
      medicineName: json['medicineName'] as String,
      dosage: json['dosage'] as String,
      type: json['type'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      actionTime: json['actionTime'] != null
          ? DateTime.parse(json['actionTime'] as String)
          : null,
      status: json['status'] as String,
      familyMemberId: json['familyMemberId'] as String,
    );
  }
}

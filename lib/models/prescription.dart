class Prescription {
  final String id;
  final String title;
  final String doctorName;
  final DateTime uploadDate;
  final List<String> extractedMedicines;
  final String? imageAsset; // Mock file URI or asset name
  final String familyMemberId;

  Prescription({
    required this.id,
    required this.title,
    required this.doctorName,
    required this.uploadDate,
    required this.extractedMedicines,
    this.imageAsset,
    required this.familyMemberId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'doctorName': doctorName,
      'uploadDate': uploadDate.toIso8601String(),
      'extractedMedicines': extractedMedicines,
      'imageAsset': imageAsset,
      'familyMemberId': familyMemberId,
    };
  }

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] as String,
      title: json['title'] as String,
      doctorName: json['doctorName'] as String,
      uploadDate: DateTime.parse(json['uploadDate'] as String),
      extractedMedicines: List<String>.from(json['extractedMedicines'] as List? ?? []),
      imageAsset: json['imageAsset'] as String?,
      familyMemberId: json['familyMemberId'] as String,
    );
  }
}

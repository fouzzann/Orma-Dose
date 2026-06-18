class FamilyMember {
  final String id;
  final String name;
  final String relation; // "Self", "Parent", "Child", "Other"
  final int avatarIndex; // index of predefined avatar illustrations

  FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.avatarIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'avatarIndex': avatarIndex,
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      name: json['name'] as String,
      relation: json['relation'] as String,
      avatarIndex: json['avatarIndex'] as int? ?? 0,
    );
  }
}

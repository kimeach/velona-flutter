class MemberModel {
  final int memberId;
  final String email;
  final String? name;
  final String? profileImageUrl;
  final String role; // USER, ADMIN
  final DateTime createdAt;

  const MemberModel({
    required this.memberId,
    required this.email,
    this.name,
    this.profileImageUrl,
    required this.role,
    required this.createdAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
        memberId: json['memberId'] as int,
        email: json['email'] as String,
        name: json['name'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
        role: json['role'] as String? ?? 'USER',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  bool get isAdmin => role == 'ADMIN';
}

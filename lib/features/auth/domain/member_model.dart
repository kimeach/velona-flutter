class MemberModel {
  final int memberId;
  final String email;
  final String? nickname;
  final String? profileImg;
  final String plan;

  const MemberModel({
    required this.memberId,
    required this.email,
    this.nickname,
    this.profileImg,
    required this.plan,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
        memberId: (json['memberId'] as num).toInt(),
        email: json['email'] as String? ?? '',
        nickname: json['nickname'] as String?,
        profileImg: json['profileImg'] as String?,
        plan: json['plan'] as String? ?? 'free',
      );

  String get displayName => nickname ?? email;
}

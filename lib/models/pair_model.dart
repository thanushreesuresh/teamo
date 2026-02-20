class PairModel {
  final String id;
  final String user1Id;
  final String? user2Id;
  final String inviteCode;
  final String? mood1;
  final String? mood2;
  final int missYouCount;
  final String? lampColor1;
  final String? lampColor2;
  final DateTime createdAt;

  PairModel({
    required this.id,
    required this.user1Id,
    this.user2Id,
    required this.inviteCode,
    this.mood1,
    this.mood2,
    this.missYouCount = 0,
    this.lampColor1,
    this.lampColor2,
    required this.createdAt,
  });

  factory PairModel.fromMap(Map<String, dynamic> map) {
    return PairModel(
      id: map['id'] as String,
      user1Id: map['user1_id'] as String,
      user2Id: map['user2_id'] as String?,
      inviteCode: map['invite_code'] as String,
      mood1: map['mood1'] as String?,
      mood2: map['mood2'] as String?,
      missYouCount: (map['miss_you_count'] as int?) ?? 0,
      lampColor1: map['lamp_color1'] as String?,
      lampColor2: map['lamp_color2'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'invite_code': inviteCode,
      'mood1': mood1,
      'mood2': mood2,
      'miss_you_count': missYouCount,
      'lamp_color1': lampColor1,
      'lamp_color2': lampColor2,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isPaired => user2Id != null;
}

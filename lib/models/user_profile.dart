class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? pairId;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.pairId,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['display_name'] as String?,
      pairId: map['pair_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'pair_id': pairId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

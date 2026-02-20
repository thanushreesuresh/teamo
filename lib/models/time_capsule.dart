class TimeCapsule {
  final String id;
  final String pairId;
  final String authorId;
  final String message;
  final DateTime unlockAt;
  final DateTime createdAt;

  TimeCapsule({
    required this.id,
    required this.pairId,
    required this.authorId,
    required this.message,
    required this.unlockAt,
    required this.createdAt,
  });

  factory TimeCapsule.fromMap(Map<String, dynamic> map) {
    return TimeCapsule(
      id: map['id'] as String,
      pairId: map['pair_id'] as String,
      authorId: map['author_id'] as String,
      message: map['message'] as String,
      unlockAt: DateTime.parse(map['unlock_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pair_id': pairId,
      'author_id': authorId,
      'message': message,
      'unlock_at': unlockAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isUnlocked => DateTime.now().isAfter(unlockAt);
}

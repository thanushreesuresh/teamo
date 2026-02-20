class DiaryEntry {
  final String id;
  final String pairId;
  final String authorId;
  final String content;
  final DateTime createdAt;

  DiaryEntry({
    required this.id,
    required this.pairId,
    required this.authorId,
    required this.content,
    required this.createdAt,
  });

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as String,
      pairId: map['pair_id'] as String,
      authorId: map['author_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pair_id': pairId,
      'author_id': authorId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

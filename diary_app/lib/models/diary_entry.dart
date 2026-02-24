class DiaryEntry {
  final int? id;
  final DateTime date;
  final String content;
  final String? title;
  final DateTime? deletedAt;

  DiaryEntry({
    this.id,
    required this.date,
    required this.content,
    this.title,
    this.deletedAt,
  });

  DiaryEntry copyWith({
    int? id,
    DateTime? date,
    String? content,
    String? title,
    DateTime? deletedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      title: title ?? this.title,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, Object?> toJson() => {
        DiaryEntryFields.id: id,
        DiaryEntryFields.date: date.toIso8601String(),
        DiaryEntryFields.content: content,
        if (title != null) DiaryEntryFields.title: title,
        if (deletedAt != null) DiaryEntryFields.deletedAt: deletedAt!.toIso8601String(),
      };

  static DiaryEntry fromJson(Map<String, Object?> json) => DiaryEntry(
        id: json[DiaryEntryFields.id] as int?,
        date: DateTime.parse(json[DiaryEntryFields.date] as String),
        content: json[DiaryEntryFields.content] as String,
        title: json[DiaryEntryFields.title] as String?,
        deletedAt: json[DiaryEntryFields.deletedAt] == null
            ? null
            : DateTime.parse(json[DiaryEntryFields.deletedAt] as String),
      );
}

class DiaryEntryFields {
  static final List<String> values = [
    id, date, content, title, deletedAt
  ];

  static const String tableName = 'entries';
  static const String id = '_id';
  static const String date = 'date';
  static const String content = 'content';
  static const String title = 'title';
  static const String deletedAt = 'deletedAt';
}

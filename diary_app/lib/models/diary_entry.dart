class DiaryEntry {
  final int? id;
  final DateTime date;
  final String content;
  final String? title;

  DiaryEntry({
    this.id,
    required this.date,
    required this.content,
    this.title,
  });

  DiaryEntry copyWith({
    int? id,
    DateTime? date,
    String? content,
    String? title,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      title: title ?? this.title,
    );
  }

  Map<String, Object?> toJson() => {
        DiaryEntryFields.id: id,
        DiaryEntryFields.date: date.toIso8601String(),
        DiaryEntryFields.content: content,
        if (title != null) DiaryEntryFields.title: title,
      };

  static DiaryEntry fromJson(Map<String, Object?> json) => DiaryEntry(
        id: json[DiaryEntryFields.id] as int?,
        date: DateTime.parse(json[DiaryEntryFields.date] as String),
        content: json[DiaryEntryFields.content] as String,
        title: json[DiaryEntryFields.title] as String?,
      );
}

class DiaryEntryFields {
  static final List<String> values = [
    id, date, content, title
  ];

  static const String tableName = 'entries';
  static const String id = '_id';
  static const String date = 'date';
  static const String content = 'content';
  static const String title = 'title';
}

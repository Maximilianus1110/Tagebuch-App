import 'package:diary_app/models/diary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DiaryEntry toJson and fromJson', () {
    final date = DateTime.now();
    final entry = DiaryEntry(
      id: 1,
      date: date,
      content: 'Test content',
    );

    final json = entry.toJson();
    final newEntry = DiaryEntry.fromJson(json);

    expect(newEntry.id, entry.id);
    expect(newEntry.content, entry.content);
    expect(newEntry.date.toIso8601String(), date.toIso8601String());
  });
}

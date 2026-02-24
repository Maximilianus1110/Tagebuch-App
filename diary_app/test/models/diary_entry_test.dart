import 'package:diary_app/models/diary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DiaryEntry toJson and fromJson without title', () {
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
    expect(newEntry.title, null);
    expect(newEntry.deletedAt, null);
    expect(newEntry.date.toIso8601String(), date.toIso8601String());
  });

  test('DiaryEntry toJson and fromJson with title', () {
    final date = DateTime.now();
    final entry = DiaryEntry(
      id: 2,
      date: date,
      content: 'Test content',
      title: 'My Title',
    );

    final json = entry.toJson();
    final newEntry = DiaryEntry.fromJson(json);

    expect(newEntry.id, entry.id);
    expect(newEntry.content, entry.content);
    expect(newEntry.title, 'My Title');
    expect(newEntry.deletedAt, null);
    expect(newEntry.date.toIso8601String(), date.toIso8601String());
  });

  test('DiaryEntry toJson and fromJson with deletedAt', () {
    final date = DateTime.now();
    final deletedAt = DateTime.now().add(const Duration(hours: 1));
    final entry = DiaryEntry(
      id: 3,
      date: date,
      content: 'Deleted content',
      title: 'Deleted Title',
      deletedAt: deletedAt,
    );

    final json = entry.toJson();
    final newEntry = DiaryEntry.fromJson(json);

    expect(newEntry.id, entry.id);
    expect(newEntry.content, entry.content);
    expect(newEntry.title, 'Deleted Title');
    expect(newEntry.date.toIso8601String(), date.toIso8601String());
    expect(newEntry.deletedAt!.toIso8601String(), deletedAt.toIso8601String());
  });
}

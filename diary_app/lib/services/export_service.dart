import 'dart:io';
import 'package:diary_app/db/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static Future<void> exportEntries() async {
    final entries = await DatabaseHelper.instance.readAllEntries();

    if (entries.isEmpty) {
      return;
    }

    final buffer = StringBuffer();
    for (final entry in entries) {
      final dateStr = DateFormat('yyyy-MM-dd').format(entry.date);
      buffer.writeln('Datum: $dateStr');
      buffer.writeln(entry.content);
      buffer.writeln(); // Empty line between entries
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/tagebuch_export.txt');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles([XFile(file.path)], text: 'Mein Tagebuch Export');
  }
}

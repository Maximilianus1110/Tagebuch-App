import 'dart:io';
import 'package:archive/archive_io.dart';

void main() async {
  final bytes = await File('../docs/backup_example.zip').readAsBytes();
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    print('Decode success, files: ${archive.length}');
  } catch (e) {
    print('Decode failed: $e');
  }
}

import 'dart:io';
import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/services/gym_service.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';

class ExportService {
  static Future<void> exportEntries() async {
    final entries = await DatabaseHelper.instance.readAllEntries();

    if (entries.isEmpty) {
      return;
    }

    final buffer = StringBuffer();
    for (final entry in entries) {
      final dateStr = DateFormat('dd.MM.yyyy').format(entry.date);
      buffer.writeln('Datum: $dateStr');
      if (entry.title != null && entry.title!.isNotEmpty) {
        buffer.writeln('Titel: ${entry.title}');
      }
      buffer.writeln(entry.content);
      buffer.writeln('----------------------------------------');
      buffer.writeln();
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/tagebuch_export.txt');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles([XFile(file.path)], text: 'Mein Tagebuch Export');
  }

  static Future<void> exportGymData() async {
    final gymService = GymService();
    final history = await gymService.getHistory();

    // We could export plans and exercises too, but history is most important.
    // Let's create a CSV-like or readable text format.

    final buffer = StringBuffer();
    buffer.writeln('Gym Trainingsverlauf Export');
    buffer.writeln('Generiert am: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}');
    buffer.writeln('----------------------------------------');
    buffer.writeln();

    for (var item in history) {
        final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(item.training.date);
        buffer.writeln('Training: ${item.planName} am $dateStr');
        buffer.writeln('Gesamtvolumen: ${item.totalVolume.toStringAsFixed(1)} kg');

        // Fetch details for this training
        final sets = await gymService.getSetsForTraining(item.training.id!);
        // Sort/Group sets?
        sets.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

        final exercises = await gymService.getAllExercises();
        final exerciseMap = {for (var e in exercises) e.id: e.name};

        if (sets.isNotEmpty) {
            buffer.writeln('Übungen:');
            int? currentExId;
            for (var s in sets) {
                if (s.exerciseId != currentExId) {
                    currentExId = s.exerciseId;
                    buffer.writeln('  - ${exerciseMap[s.exerciseId] ?? "Unbekannt"}:');
                }
                buffer.write('    Set ${s.setNumber}: ${s.weight ?? 0}kg x ${s.reps ?? 0}');
                if (s.isWarmup) buffer.write(' (Aufwärmen)');
                if (s.durationSeconds != null && s.durationSeconds! > 0) buffer.write(' (${s.durationSeconds}s)');
                buffer.writeln();
            }
        }
        buffer.writeln();
        buffer.writeln('----------------------------------------');
        buffer.writeln();
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/gym_export.txt');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles([XFile(file.path)], text: 'Mein Gym Export');
  }

  static Future<void> exportAllData(BuildContext context) async {
    // Export both Diary and Gym data into separate files and share them together
    try {
        final directory = await getTemporaryDirectory();
        final files = <XFile>[];

        // 1. Diary
        final entries = await DatabaseHelper.instance.readAllEntries();
        if (entries.isNotEmpty) {
            final buffer = StringBuffer();
            for (final entry in entries) {
                final dateStr = DateFormat('dd.MM.yyyy').format(entry.date);
                buffer.writeln('Datum: $dateStr');
                if (entry.title != null && entry.title!.isNotEmpty) {
                    buffer.writeln('Titel: ${entry.title}');
                }
                buffer.writeln(entry.content);
                buffer.writeln('----------------------------------------');
                buffer.writeln();
            }
            final diaryFile = File('${directory.path}/tagebuch_komplett_export.txt');
            await diaryFile.writeAsString(buffer.toString());
            files.add(XFile(diaryFile.path));
        }

        // 2. Gym
        final gymService = GymService();
        final history = await gymService.getHistory();
        if (history.isNotEmpty) {
            final buffer = StringBuffer();
            buffer.writeln('Gym Trainingsverlauf Export');
            buffer.writeln('Generiert am: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}');
            buffer.writeln('----------------------------------------');
            buffer.writeln();

            for (var item in history) {
                final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(item.training.date);
                buffer.writeln('Training: ${item.planName} am $dateStr');
                buffer.writeln('Gesamtvolumen: ${item.totalVolume.toStringAsFixed(1)} kg');

                final sets = await gymService.getSetsForTraining(item.training.id!);
                sets.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

                final exercises = await gymService.getAllExercises();
                final exerciseMap = {for (var e in exercises) e.id: e.name};

                if (sets.isNotEmpty) {
                    buffer.writeln('Übungen:');
                    int? currentExId;
                    for (var s in sets) {
                        if (s.exerciseId != currentExId) {
                            currentExId = s.exerciseId;
                            buffer.writeln('  - ${exerciseMap[s.exerciseId] ?? "Unbekannt"}:');
                        }
                        buffer.write('    Set ${s.setNumber}: ${s.weight ?? 0}kg x ${s.reps ?? 0}');
                        if (s.isWarmup) buffer.write(' (Aufwärmen)');
                        if (s.durationSeconds != null && s.durationSeconds! > 0) buffer.write(' (${s.durationSeconds}s)');
                        buffer.writeln();
                    }
                }
                buffer.writeln();
                buffer.writeln('----------------------------------------');
                buffer.writeln();
            }
             final gymFile = File('${directory.path}/gym_komplett_export.txt');
            await gymFile.writeAsString(buffer.toString());
            files.add(XFile(gymFile.path));
        }

        if (files.isNotEmpty) {
            await Share.shareXFiles(files, text: 'Mein Kompletter Daten Export');
        } else {
             if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keine Daten zum Exportieren gefunden.')));
             }
        }

    } catch (e) {
        debugPrint('Export failed: $e');
        if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export fehlgeschlagen: $e')));
        }
    }
  }
}

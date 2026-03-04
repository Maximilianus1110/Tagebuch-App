import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:diary_app/services/kitchen_service.dart';

class KitchenImportScreen extends StatefulWidget {
  const KitchenImportScreen({super.key});

  @override
  State<KitchenImportScreen> createState() => _KitchenImportScreenState();
}

class _KitchenImportScreenState extends State<KitchenImportScreen> {
  final TextEditingController _jsonController = TextEditingController();
  final KitchenService _kitchenService = KitchenService();
  bool _isImporting = false;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        _jsonController.text = contents;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Dateiauswahl: $e')),
        );
      }
    }
  }

  Future<void> _processImport() async {
    final text = _jsonController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte JSON eingeben oder Datei laden.')),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final count = await _kitchenService.importFromJson(text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count Produkte erfolgreich importiert.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Import: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON Import'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Füge das JSON Array hier ein oder lade eine Datei hoch.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _importFromFile,
              icon: const Icon(Icons.file_upload),
              label: const Text('Aus Datei laden (.json)'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _jsonController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: '[\n  {\n    "name": "...",\n    "basis_produkt": "...",\n    "menge": 500,\n    "einheit": "g",\n    "haltbar_tage": 30\n  }\n]',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            if (_isImporting)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _processImport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Import ausführen'),
              ),
          ],
        ),
      ),
    );
  }
}

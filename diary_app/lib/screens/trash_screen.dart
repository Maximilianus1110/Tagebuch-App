import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/diary_entry.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<DiaryEntry> _trashEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshTrash();
  }

  Future<void> _refreshTrash() async {
    setState(() => _isLoading = true);
    try {
      final entries = await DatabaseHelper.instance.readTrashEntries();
      if (mounted) {
        setState(() {
          _trashEntries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading trash: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreEntry(DiaryEntry entry) async {
    if (entry.id != null) {
      await DatabaseHelper.instance.restore(entry.id!);
      await _refreshTrash();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eintrag wiederhergestellt')),
        );
      }
    }
  }

  Future<void> _deletePermanently(DiaryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Endgültig löschen?'),
        content: const Text('Möchtest du diesen Eintrag unwiderruflich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && entry.id != null) {
      await DatabaseHelper.instance.hardDelete(entry.id!);
      await _refreshTrash();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eintrag endgültig gelöscht')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Papierkorb'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trashEntries.isEmpty
              ? const Center(child: Text('Papierkorb ist leer.'))
              : ListView.builder(
                  itemCount: _trashEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _trashEntries[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(
                                DateFormat('dd.MM.yyyy').format(entry.date),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (entry.title != null && entry.title!.isNotEmpty)
                                    Text(entry.title!,
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(
                                    entry.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Gelöscht am: ${entry.deletedAt != null ? DateFormat('dd.MM.yyyy HH:mm').format(entry.deletedAt!) : '-'}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.restore),
                                    tooltip: 'Wiederherstellen',
                                    onPressed: () => _restoreEntry(entry),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                                    tooltip: 'Endgültig löschen',
                                    onPressed: () => _deletePermanently(entry),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

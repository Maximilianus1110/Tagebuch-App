import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/screens/add_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  final Future<void> Function(BuildContext context)? onExport;

  const HomeScreen({super.key, this.onExport});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<DiaryEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _refreshEntries();
  }

  void _refreshEntries() {
    setState(() {
      _entriesFuture = DatabaseHelper.instance.readAllEntries();
    });
  }

  Future<void> _navigateToAddEntry() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddEntryScreen()),
    );

    if (result == true) {
      _refreshEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mein Tagebuch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Exportieren',
            onPressed: widget.onExport != null
                ? () => widget.onExport!(context)
                : null,
          ),
        ],
      ),
      body: FutureBuilder<List<DiaryEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Fehler: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Keine Einträge vorhanden.'));
          } else {
            final entries = snapshot.data!;
            return ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('yyyy-MM-dd').format(entry.date),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.content,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddEntry,
        child: const Icon(Icons.add),
      ),
    );
  }
}

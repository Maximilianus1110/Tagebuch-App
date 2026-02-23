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
  List<DiaryEntry> _allEntries = [];
  List<DiaryEntry> _filteredEntries = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshEntries();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterEntries();
  }

  Future<void> _refreshEntries() async {
    setState(() => _isLoading = true);
    try {
      final entries = await DatabaseHelper.instance.readAllEntries();
      if (mounted) {
        setState(() {
          _allEntries = entries;
          _isLoading = false;
          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint('Error loading entries: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterEntries() {
    setState(() {
      _applyFilter();
    });
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredEntries = List.from(_allEntries);
    } else {
      _filteredEntries = _allEntries.where((entry) {
        final title = entry.title?.toLowerCase() ?? '';
        final content = entry.content.toLowerCase();
        return title.contains(query) || content.contains(query);
      }).toList();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _navigateToAddEntry() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddEntryScreen()),
    );

    if (result == true) {
      await _refreshEntries();
      _scrollToTop();
    }
  }

  Future<void> _navigateToEditEntry(DiaryEntry entry) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddEntryScreen(entry: entry)),
    );

    if (result == true) {
      await _refreshEntries();
      _scrollToTop();
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
      body: Column(
        children: [
          // Issue #4: Search Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Suchen...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEntries.isEmpty
                    ? const Center(child: Text('Keine Einträge vorhanden.'))
                    : ListView.builder(
                        controller: _scrollController, // Issue #6: Scroll Controller
                        itemCount: _filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _filteredEntries[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: InkWell(
                              onTap: () => _navigateToEditEntry(entry), // Issue #2: Edit
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Issue #3: Date format dd.MM.yyyy
                                    Text(
                                      DateFormat('dd.MM.yyyy')
                                          .format(entry.date),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Issue #1: Title
                                    if (entry.title != null &&
                                        entry.title!.isNotEmpty) ...[
                                      Text(
                                        entry.title!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    // Issue #5: Truncate text
                                    Text(
                                      entry.content,
                                      style:
                                          Theme.of(context).textTheme.bodyMedium,
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddEntry,
        child: const Icon(Icons.add),
      ),
    );
  }
}

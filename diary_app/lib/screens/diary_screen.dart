import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/screens/add_entry_screen.dart';
import 'package:diary_app/services/export_service.dart';
import 'package:diary_app/screens/trash_screen.dart';
import 'package:diary_app/screens/gym_screen.dart';
import 'package:diary_app/screens/settings/settings_screen.dart';
import 'package:diary_app/widgets/app_drawer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<DiaryEntry> _allEntries = [];
  List<DiaryEntry> _filteredEntries = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Calendar State
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // List Scroll Controller
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    _refreshEntries();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  List<DiaryEntry> _getEntriesForDay(DateTime day) {
    return _allEntries.where((entry) {
      return isSameDay(entry.date, day);
    }).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      // Clear search to show all entries
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
      }

      // We need to wait for the filter to apply and the list to rebuild
      // But since we are inside setState, and _searchController clear triggers listener synchronously,
      // _filteredEntries should be up to date (equal to _allEntries).

      final index = _allEntries.indexWhere((entry) => isSameDay(entry.date, selectedDay));

      if (index != -1) {
        // Use a small delay to ensure the list has been rebuilt with the full list
        // if search was cleared.
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_itemScrollController.isAttached) {
                _itemScrollController.scrollTo(
                    index: index,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                );
            }
        });
      }
    }
  }

  Future<void> _navigateToAddEntry() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddEntryScreen()),
    );

    if (result == true) {
      await _refreshEntries();
      if (_allEntries.isNotEmpty && _itemScrollController.isAttached) {
         _itemScrollController.jumpTo(index: 0);
      }
    }
  }

  Future<void> _navigateToEditEntry(DiaryEntry entry) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddEntryScreen(entry: entry)),
    );

    if (result == true) {
      await _refreshEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mein Tagebuch'),
      ),
      endDrawer: AppDrawer(
        title: 'Tagebuch Menü',
        children: [
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Tagebuch exportieren'),
            onTap: () {
              Navigator.pop(context);
              ExportService.exportEntries();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Papierkorb'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(builder: (context) => const TrashScreen()),
                  )
                  .then((_) => _refreshEntries());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Einstellungen'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('Modus wechseln'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const GymScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Stack(
            children: [
              TableCalendar<DiaryEntry>(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                eventLoader: _getEntriesForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false, // We use our own button
                  titleCentered: true,
                ),
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _calendarFormat = _calendarFormat == CalendarFormat.month
                            ? CalendarFormat.week
                            : CalendarFormat.month;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
                        boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                            )
                        ]
                      ),
                      child: Icon(
                        _calendarFormat == CalendarFormat.month
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Suchen...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEntries.isEmpty
                    ? const Center(child: Text('Keine Einträge vorhanden.'))
                    : ScrollablePositionedList.builder(
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        itemCount: _filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _filteredEntries[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _navigateToEditEntry(entry),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                    Text(
                                      DateFormat('dd.MM.yyyy')
                                          .format(entry.date),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).colorScheme.primary,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
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

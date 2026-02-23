import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/screens/add_entry_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class HomeScreen extends StatefulWidget {
  final Future<void> Function(BuildContext context)? onExport;

  const HomeScreen({super.key, this.onExport});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<DiaryEntry>> _entriesFuture;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

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

  void _scrollToFirstEntry(DateTime date, List<DiaryEntry> entries) {
    final index = entries.indexWhere((entry) => isSameDay(entry.date, date));
    if (index != -1) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
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
          }

          final entries = snapshot.data ?? [];

          // Optimization: Create a map for fast lookup
          final Map<DateTime, List<DiaryEntry>> events = {};
          for (var entry in entries) {
            final dateKey = DateUtils.dateOnly(entry.date);
            if (events.containsKey(dateKey)) {
              events[dateKey]!.add(entry);
            } else {
              events[dateKey] = [entry];
            }
          }

          return Column(
            children: [
              _buildCalendar(events, entries),
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('Keine Einträge vorhanden.'))
                    : _buildList(entries),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddEntry,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendar(Map<DateTime, List<DiaryEntry>> events, List<DiaryEntry> allEntries) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      child: Column(
        children: [
          TableCalendar<DiaryEntry>(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => events[DateUtils.dateOnly(day)] ?? [],
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              markerDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              if (events[DateUtils.dateOnly(selectedDay)]?.isNotEmpty == true) {
                _scrollToFirstEntry(selectedDay, allEntries);
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(
                _calendarFormat == CalendarFormat.month
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
              ),
              tooltip: _calendarFormat == CalendarFormat.month ? 'Wochenansicht' : 'Monatsansicht',
              onPressed: () {
                setState(() {
                  if (_calendarFormat == CalendarFormat.month) {
                    _calendarFormat = CalendarFormat.week;
                  } else {
                    _calendarFormat = CalendarFormat.month;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<DiaryEntry> entries) {
    return ScrollablePositionedList.builder(
      itemCount: entries.length,
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
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
}

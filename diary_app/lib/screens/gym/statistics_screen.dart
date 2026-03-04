import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:diary_app/services/gym_service.dart';
import 'package:diary_app/models/gym/gym_exercise.dart';
import 'package:diary_app/models/gym/gym_training.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GymService _gymService = GymService();

  bool _isLoading = true;
  List<GymTraining> _trainings = [];
  List<GymExercise> _exercises = [];

  // Exercise specific stats
  GymExercise? _selectedExercise;
  List<Map<String, dynamic>> _exerciseHistory = []; // {date, maxWeight, totalVolume}

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final history = await _gymService.getHistory();
    final items = history;
    final trainings = items.map((e) => e.training).toList();

    final exercises = await _gymService.getAllExercises();

    if (mounted) {
      setState(() {
        _trainings = trainings;
        _exercises = exercises;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExerciseStats(GymExercise exercise) async {
    setState(() => _isLoading = true);

    List<Map<String, dynamic>> history = [];

    for (var t in _trainings) {
        final sets = await _gymService.getSetsForTraining(t.id!);
        final exerciseSets = sets.where((s) => s.exerciseId == exercise.id).toList();

        if (exerciseSets.isNotEmpty) {
            double maxWeight = 0;
            double volume = 0;
            int totalReps = 0;
            int totalDuration = 0;

            for (var s in exerciseSets) {
                if (s.weight != null && s.weight! > maxWeight) maxWeight = s.weight!;
                if (s.weight != null && s.reps != null) volume += s.weight! * s.reps!;
                if (s.reps != null) totalReps += s.reps!;
                if (s.durationSeconds != null) totalDuration += s.durationSeconds!;
            }

            history.add({
                'date': t.date,
                'maxWeight': maxWeight,
                'volume': volume,
                'reps': totalReps,
                'duration': totalDuration,
            });
        }
    }

    history.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    if (mounted) {
        setState(() {
            _selectedExercise = exercise;
            _exerciseHistory = history;
            _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiken'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Allgemein'),
            Tab(text: 'Übung'),
            Tab(text: 'Nerdy'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralStats(),
                _buildExerciseStats(),
                _buildNerdyStats(),
              ],
            ),
    );
  }

  Widget _buildGeneralStats() {
    int totalWorkouts = _trainings.length;
    int totalDurationSeconds = 0;

    for(var t in _trainings) {
        if (t.durationSeconds != null) totalDurationSeconds += t.durationSeconds!;
    }

    final durationStr = _formatDuration(totalDurationSeconds);

    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Trainings Gesamt', '$totalWorkouts'),
                _buildStatCard('Gesamtzeit im Gym', durationStr),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Workouts pro Monat (Letzte 6 Monate)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              child: _buildWorkoutsBarChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutsBarChart() {
    Map<String, int> monthlyCounts = {};
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        final key = DateFormat('MMM').format(d);
        monthlyCounts[key] = 0;
    }

    for (var t in _trainings) {
        // Only count if within last 6 months window
        final diff = now.difference(t.date).inDays;
        if (diff <= 180) { // Approx
            final key = DateFormat('MMM').format(t.date);
            if (monthlyCounts.containsKey(key)) {
                monthlyCounts[key] = monthlyCounts[key]! + 1;
            }
        }
    }

    final spots = monthlyCounts.entries.map((e) => e).toList();
    double maxY = (spots.map((e) => e.value).fold(0, (p, c) => p > c ? p : c) + 2).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < spots.length) {
                    return Text(spots[value.toInt()].key, style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: spots.asMap().entries.map((e) {
            return BarChartGroupData(
                x: e.key,
                barRods: [
                    BarChartRodData(
                        toY: e.value.value.toDouble(),
                              color: Theme.of(context).colorScheme.primary,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                    ),
                ],
            );
        }).toList(),
      ),
    );
  }

  Widget _buildExerciseStats() {
      if (_selectedExercise == null) {
          return Column(
              children: [
                  Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                          decoration: const InputDecoration(
                              labelText: 'Übung suchen',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                              // Filter list locally?
                              // For simplicity, just show list.
                              // Implementing simple filter
                              final query = val.toLowerCase();
                              if (val.isEmpty) {
                                  _loadData(); // Reset
                              } else {
                                  setState(() {
                                      _exercises = _exercises.where((e) => e.name.toLowerCase().contains(query)).toList();
                                  });
                              }
                          },
                      ),
                  ),
                  Expanded(
                      child: ListView.builder(
                          itemCount: _exercises.length,
                          itemBuilder: (context, index) {
                              final ex = _exercises[index];
                              return ListTile(
                                  title: Text(ex.name),
                                  onTap: () => _loadExerciseStats(ex),
                                  trailing: const Icon(Icons.chevron_right),
                              );
                          },
                      ),
                  ),
              ],
          );
      }

      return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(
                      children: [
                          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedExercise = null)),
                          Expanded(child: Text(_selectedExercise!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                      ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Maximales Gewicht (kg)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: _buildLineChart('maxWeight', Colors.redAccent)),
                  const SizedBox(height: 32),
                  const Text('Volumen (kg)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: _buildLineChart('volume', Colors.green)),
              ],
          ),
      );
  }

  Widget _buildLineChart(String key, Color color) {
      if (_exerciseHistory.isEmpty) return const Center(child: Text('Keine Daten vorhanden'));

      final points = _exerciseHistory.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), (e.value[key] as num).toDouble());
      }).toList();

      return LineChart(
          LineChartData(
              lineBarsData: [
                  LineChartBarData(
                      spots: points,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
                  ),
              ],
              titlesData: const FlTitlesData(show: false),
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1)),
              borderData: FlBorderData(show: false),
          ),
      );
  }

  Widget _buildNerdyStats() {
      if (_selectedExercise == null) {
          return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                    Text('Wähle zuerst eine Übung im "Übung" Tab aus.', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 16),
                    Icon(Icons.query_stats, size: 64, color: Colors.grey),
                ],
            )
          );
      }

      if (_exerciseHistory.isEmpty) return const Center(child: Text('Keine Daten vorhanden'));

      // Calculate averages
      double totalVol = 0;
      double count = 0;
      int totalTime = 0;

      for(var h in _exerciseHistory) {
          totalVol += h['volume'];
          totalTime += (h['duration'] as int);
          count++;
      }

      final avgVol = count > 0 ? totalVol / count : 0;
      final avgTime = count > 0 ? totalTime / count : 0;

      return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
              children: [
                  Text('Nerdy Details für ${_selectedExercise!.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                        _buildStatCard('Ø Volumen', '${avgVol.toStringAsFixed(1)} kg'),
                        _buildStatCard('Ø Zeit/Session', '${avgTime.toStringAsFixed(0)} s'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Dauer pro Trainingseinheit (s)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: _buildLineChart('duration', Colors.purpleAccent)),
              ],
          ),
      );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
      final hours = seconds ~/ 3600;
      final mins = (seconds % 3600) ~/ 60;
      return '${hours}h ${mins}m';
  }
}

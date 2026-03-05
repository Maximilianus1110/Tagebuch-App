import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:diary_app/services/kitchen_service.dart';
import 'package:diary_app/models/kitchen/kitchen_history.dart';

class KitchenStatisticsScreen extends StatefulWidget {
  const KitchenStatisticsScreen({super.key});

  @override
  State<KitchenStatisticsScreen> createState() => _KitchenStatisticsScreenState();
}

class _KitchenStatisticsScreenState extends State<KitchenStatisticsScreen> {
  final KitchenService _kitchenService = KitchenService();
  bool _isLoading = true;
  List<KitchenHistory> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final history = await _kitchenService.getHistoryEvents();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Küchen-Statistiken'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('Noch keine Daten vorhanden. Verbrauche oder entsorge zuerst etwas.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewCards(),
                      const SizedBox(height: 32),
                      const Text(
                        'Verbraucht vs. Weggeschmissen (Anzahl Events)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 250,
                        child: _buildRatioPieChart(),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Top 5 Kategorien (Basis-Produkte)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 250,
                        child: _buildTopCategoriesChart(),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Top 5 Marken',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildTopBrandsList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverviewCards() {
    int consumedCount = _history.where((e) => e.eventType == 'consumed').length;
    int trashedCount = _history.where((e) => e.eventType == 'trashed').length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _StatCard(
            title: 'Verbraucht',
            value: '$consumedCount x',
            color: Colors.green,
            icon: Icons.restaurant,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Weggeschmissen',
            value: '$trashedCount x',
            color: Colors.red,
            icon: Icons.delete_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildRatioPieChart() {
    int consumedCount = _history.where((e) => e.eventType == 'consumed').length;
    int trashedCount = _history.where((e) => e.eventType == 'trashed').length;

    if (consumedCount == 0 && trashedCount == 0) return const SizedBox.shrink();

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          if (consumedCount > 0)
            PieChartSectionData(
              color: Colors.green,
              value: consumedCount.toDouble(),
              title: 'Verbraucht\n$consumedCount',
              radius: 60,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          if (trashedCount > 0)
            PieChartSectionData(
              color: Colors.red,
              value: trashedCount.toDouble(),
              title: 'Müll\n$trashedCount',
              radius: 60,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildTopCategoriesChart() {
    Map<String, int> categoryCounts = {};
    for (var h in _history) {
      categoryCounts[h.basisProdukt] = (categoryCounts[h.basisProdukt] ?? 0) + 1;
    }

    var sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = sortedCategories.take(5).toList();

    if (top5.isEmpty) return const SizedBox.shrink();

    double maxY = (top5.first.value + 2).toDouble();

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
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < top5.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        top5[value.toInt()].key,
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  );
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
        barGroups: top5.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value.toDouble(),
                color: Theme.of(context).colorScheme.primary,
                width: 20,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopBrandsList() {
    Map<String, int> brandCounts = {};
    for (var h in _history) {
      if (h.marke != null && h.marke!.isNotEmpty) {
        brandCounts[h.marke!] = (brandCounts[h.marke!] ?? 0) + 1;
      }
    }

    var sortedBrands = brandCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = sortedBrands.take(5).toList();

    if (top5.isEmpty) return const Text('Keine Markendaten vorhanden.', style: TextStyle(color: Colors.grey));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: top5.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text('${index + 1}'),
            ),
            title: Text(top5[index].key, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text('${top5[index].value} x'),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

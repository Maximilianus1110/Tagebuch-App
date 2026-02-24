import 'package:diary_app/models/gym/gym_plan.dart';
import 'package:diary_app/screens/diary_screen.dart';
import 'package:diary_app/screens/gym/create_plan_screen.dart';
import 'package:diary_app/screens/gym/manage_equipment_screen.dart';
import 'package:diary_app/screens/gym/training_session_screen.dart';
import 'package:diary_app/services/gym_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GymScreen extends StatefulWidget {
  const GymScreen({super.key});

  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen> {
  final GymService _gymService = GymService();
  List<GymPlanViewModel> _plans = [];
  List<TrainingHistoryItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final plans = await _gymService.getAllPlans();
      final history = await _gymService.getHistory();
      final allEquipment = await _gymService.getAllEquipment();
      final equipmentMap = {for (var e in allEquipment) e.id: e.name};

      List<GymPlanViewModel> planViewModels = [];
      for (var plan in plans) {
        final exercises = await _gymService.getExercisesForPlan(plan.id!);
        // Map equipment names
        final equipmentNames = exercises
            .map((e) => equipmentMap[e.equipmentId] ?? 'Unknown')
            .toList();
        planViewModels.add(GymPlanViewModel(plan: plan, equipmentNames: equipmentNames));
      }

      if (mounted) {
        setState(() {
          _plans = planViewModels;
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _refresh() {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Gym Menü',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Geräte verwalten'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ManageEquipmentScreen()),
                ).then((_) => _refresh());
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Neuer Trainingsplan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CreatePlanScreen()),
                ).then((_) => _refresh());
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Zum Tagebuch'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const DiaryScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trainingspläne',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200, // Fixed height for horizontal list
                        child: _plans.isEmpty
                            ? Center(
                                child: Text(
                                  'Keine Pläne vorhanden.\nErstelle einen im Menü.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Theme.of(context).disabledColor),
                                ),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _plans.length,
                                itemBuilder: (context, index) {
                                  return _buildPlanCard(_plans[index]);
                                },
                              ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Trainingsverlauf',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _history.isEmpty
                          ? Center(
                              child: Text(
                                'Noch keine Trainings absolviert.',
                                style: TextStyle(color: Theme.of(context).disabledColor),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _history.length,
                              itemBuilder: (context, index) {
                                return _buildHistoryItem(_history[index]);
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPlanCard(GymPlanViewModel viewModel) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewModel.plan.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  viewModel.equipmentNames.join(', '),
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal, // Greenish like sketch
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TrainingSessionScreen(plan: viewModel.plan),
                      ),
                    ).then((_) => _refresh());
                  },
                  child: const Text('Starten'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(TrainingHistoryItem item) {
    final dateFormat = DateFormat('dd.MM.yyyy'); // Or 'dd MMM, yyyy'
    final dateStr = dateFormat.format(item.training.date);

    // Day number big
    final dayNumber = DateFormat('dd').format(item.training.date);
    final monthYear = DateFormat('MMM, yyyy').format(item.training.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Date Section
            Container(
              padding: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Text(
                    dayNumber,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    monthYear,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Plan Name Section
            Expanded(
              child: Text(
                item.planName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            // Volume Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.totalVolume.toStringAsFixed(0)} Kg',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (item.volumeDelta != null)
                  Text(
                    '${item.volumeDelta! >= 0 ? '+' : ''}${item.volumeDelta!.toStringAsFixed(0)}kg',
                    style: TextStyle(
                      fontSize: 14,
                      color: item.volumeDelta! >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GymPlanViewModel {
  final GymPlan plan;
  final List<String> equipmentNames;

  GymPlanViewModel({required this.plan, required this.equipmentNames});
}

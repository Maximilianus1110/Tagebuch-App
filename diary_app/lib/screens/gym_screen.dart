import 'package:diary_app/models/gym/gym_plan.dart';
import 'package:diary_app/screens/diary_screen.dart';
import 'package:diary_app/screens/gym/create_plan_screen.dart';
import 'package:diary_app/screens/gym/manage_exercises_screen.dart';
import 'package:diary_app/screens/gym/training_session_screen.dart';
import 'package:diary_app/screens/gym/training_detail_screen.dart';
import 'package:diary_app/services/gym_service.dart';
import 'package:diary_app/widgets/app_drawer.dart';
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
      final allEquipment = await _gymService.getAllExercises();
      final equipmentMap = {for (var e in allEquipment) e.id: e.name};

      List<GymPlanViewModel> planViewModels = [];
      for (var plan in plans) {
        final exercises = await _gymService.getExercisesForPlan(plan.id!);
        // Map equipment names
        final equipmentNames = exercises
            .map((e) => equipmentMap[e.exerciseId] ?? 'Unknown')
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

  Future<void> _showAddPastTrainingDialog() async {
    Navigator.pop(context); // Close drawer

    if (_plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erstelle zuerst einen Trainingsplan.')),
      );
      return;
    }

    // 1. Pick Date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Datum des Trainings wählen',
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    // 2. Pick Plan
    GymPlan? selectedPlan;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plan wählen'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _plans.length,
            itemBuilder: (context, index) {
              final p = _plans[index].plan;
              return ListTile(
                title: Text(p.name),
                onTap: () {
                  selectedPlan = p;
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );

    if (selectedPlan != null && mounted) {
      // Set time to noon to avoid timezone issues or just keep date part?
      // TrainingSessionScreen uses date as start time.
      // Usually users care about date.
      final dateWithTime = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day, 12, 0); // Noon

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              TrainingSessionScreen(plan: selectedPlan!, date: dateWithTime),
        ),
      ).then((_) => _refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym'),
      ),
      endDrawer: AppDrawer(
        title: 'Gym Menü',
        children: [
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('Übungen verwalten'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ManageExercisesScreen()),
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
          ListTile(
            leading: const Icon(Icons.history_edu),
            title: const Text('Training nachtragen'),
            onTap: _showAddPastTrainingDialog,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      viewModel.plan.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CreatePlanScreen(plan: viewModel.plan),
                          ),
                        ).then((_) => _refresh());
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Plan löschen?'),
                            content: const Text('Möchtest du diesen Trainingsplan wirklich löschen?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Abbrechen'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Löschen', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _gymService.deletePlan(viewModel.plan.id!);
                          _refresh();
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                      const PopupMenuItem(value: 'delete', child: Text('Löschen')),
                    ],
                    icon: const Icon(Icons.more_vert, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
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
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TrainingDetailScreen(
                training: item.training,
                planName: item.planName,
              ),
            ),
          );
        },
        onLongPress: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Training löschen?'),
              content: const Text('Möchtest du dieses Training wirklich löschen?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Löschen', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await _gymService.deleteTraining(item.training.id!);
            _refresh();
          }
        },
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
      ),
    );
  }
}

class GymPlanViewModel {
  final GymPlan plan;
  final List<String> equipmentNames;

  GymPlanViewModel({required this.plan, required this.equipmentNames});
}

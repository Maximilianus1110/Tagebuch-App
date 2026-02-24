import 'package:flutter/material.dart';
import 'package:diary_app/models/gym/gym_training.dart';
import 'package:diary_app/models/gym/gym_exercise.dart';
import 'package:diary_app/services/gym_service.dart';
import 'package:intl/intl.dart';

class TrainingDetailScreen extends StatefulWidget {
  final GymTraining training;
  final String planName;

  const TrainingDetailScreen({
    super.key,
    required this.training,
    required this.planName,
  });

  @override
  State<TrainingDetailScreen> createState() => _TrainingDetailScreenState();
}

class _TrainingDetailScreenState extends State<TrainingDetailScreen> {
  final GymService _gymService = GymService();
  bool _isLoading = true;
  List<ExerciseSets> _exerciseSets = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final sets = await _gymService.getSetsForTraining(widget.training.id!);
      final allExercises = await _gymService.getAllExercises();
      final exerciseMap = {for (var e in allExercises) e.id: e};

      // Group by exercise
      final Map<int, List<GymSet>> grouped = {};
      // Preserve order? The query orders by setNumber, but sets come mixed?
      // Actually `getSetsForTraining` orders by `exerciseId`, `setNumber`.
      // This loses the order of exercises performed if they were interleaved or reordered.
      // But `GymSet` doesn't store "exercise order".
      // `GymPlanExercise` stores order, but `GymSet` just links to training.
      // If `GymTraining` doesn't store exercise order, we can only group by ID.
      // Unless we infer from `id` (autoincrement)?
      // If we save sets sequentially, `id` reflects order.
      // Let's sort by `id` if available, or just group.

      // Sorting sets by ID to attempt to reconstruct order
      sets.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

      final List<ExerciseSets> result = [];

      // Simple grouping: Iterating through sorted sets, if exercise changes, new group.
      // This handles interleaved sets too (superset), though UI might be tricky.
      // Let's assume sequential for now.

      int? currentExerciseId;
      ExerciseSets? currentGroup;

      for (var s in sets) {
        if (s.exerciseId != currentExerciseId) {
          currentExerciseId = s.exerciseId;
          final exercise = exerciseMap[s.exerciseId];
          if (exercise != null) {
            // Check if we already have this exercise in the list?
            // If user did Ex A, then Ex B, then Ex A again, we should probably have two entries.
            // But usually we group all sets of Ex A together if not interleaved.
            // Let's check if the *last* group was this exercise.
            if (currentGroup != null && currentGroup.exercise.id == exercise.id) {
               // Same exercise, continue adding
            } else {
               currentGroup = ExerciseSets(exercise: exercise, sets: []);
               result.add(currentGroup);
            }
          }
        }
        currentGroup?.sets.add(s);
      }

      if (mounted) {
        setState(() {
          _exerciseSets = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.planName),
            Text(
              DateFormat('dd.MM.yyyy HH:mm').format(widget.training.date),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _exerciseSets.length,
              itemBuilder: (context, index) {
                final group = _exerciseSets[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.exercise.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Table(
                          columnWidths: const {
                            0: FixedColumnWidth(40),
                            1: FlexColumnWidth(),
                            2: FlexColumnWidth(),
                          },
                          children: [
                            const TableRow(
                              children: [
                                Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Kg', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Wdh.', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const TableRow(children: [SizedBox(height: 8), SizedBox(height: 8), SizedBox(height: 8)]), // Spacer
                            ...group.sets.map((s) => TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Text('${s.setNumber}'),
                                      if (s.isWarmup) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.hot_tub, size: 12, color: Colors.orange)),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text('${s.weight ?? '-'}'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text('${s.reps ?? '-'}'),
                                ),
                              ],
                            )),
                          ],
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

class ExerciseSets {
  final GymExercise exercise;
  final List<GymSet> sets;
  ExerciseSets({required this.exercise, required this.sets});
}

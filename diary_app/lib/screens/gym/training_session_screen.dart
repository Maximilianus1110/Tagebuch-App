import 'package:diary_app/models/gym/gym_plan.dart';
import 'package:diary_app/models/gym/gym_equipment.dart';
import 'package:diary_app/models/gym/gym_training.dart';
import 'package:diary_app/services/gym_service.dart';
import 'package:flutter/material.dart';

class TrainingSessionScreen extends StatefulWidget {
  final GymPlan plan;

  const TrainingSessionScreen({super.key, required this.plan});

  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen> {
  final GymService _gymService = GymService();
  bool _isLoading = true;

  // Data
  List<GymPlanExercise> _exercises = [];
  Map<int, GymEquipment> _equipmentMap = {};

  // State for inputs: keys are "${equipmentId}_${setNumber}"
  final Map<String, TextEditingController> _repsControllers = {};
  final Map<String, TextEditingController> _weightControllers = {};
  final Map<String, bool> _doneStates = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var c in _repsControllers.values) c.dispose();
    for (var c in _weightControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // 1. Fetch exercises for this plan
      final exercises = await _gymService.getExercisesForPlan(widget.plan.id!);

      // 2. Fetch all equipment to show names
      final allEquipment = await _gymService.getAllEquipment();
      final eqMap = {for (var e in allEquipment) e.id!: e};

      // 3. Fetch last training values to pre-fill
      final lastValues = await _gymService.getLastTrainingSets(widget.plan.id!);

      if (!mounted) return;

      // 4. Initialize controllers
      for (var ex in exercises) {
        for (int i = 1; i <= ex.setCount; i++) {
          final key = '${ex.equipmentId}_$i';

          String initialReps = '';
          String initialWeight = '';

          if (lastValues.containsKey(key)) {
            final lastSet = lastValues[key]!;
            if (lastSet.reps != null) initialReps = lastSet.reps.toString();
            if (lastSet.weight != null) initialWeight = lastSet.weight.toString();
          }

          _repsControllers[key] = TextEditingController(text: initialReps);
          _weightControllers[key] = TextEditingController(text: initialWeight);
          _doneStates[key] = false;
        }
      }

      if (mounted) {
        setState(() {
          _exercises = exercises;
          _equipmentMap = eqMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }

  Future<void> _finishTraining() async {
    setState(() => _isLoading = true);

    try {
      final training = GymTraining(
        planId: widget.plan.id!,
        date: DateTime.now(),
      );

      final List<GymSet> sets = [];

      for (var ex in _exercises) {
        for (int i = 1; i <= ex.setCount; i++) {
          final key = '${ex.equipmentId}_$i';
          final repsText = _repsControllers[key]?.text.trim() ?? '';
          final weightText = _weightControllers[key]?.text.trim() ?? '';
          final isDone = _doneStates[key] ?? false;

          // Only save if at least reps or weight is entered, or if marked done?
          // Requirement: "am ende eines Trainings kann man dieses speichern".
          // Better save everything the user entered.

          if (repsText.isNotEmpty || weightText.isNotEmpty || isDone) {
            sets.add(GymSet(
              trainingId: 0, // Temp
              equipmentId: ex.equipmentId,
              setNumber: i,
              reps: int.tryParse(repsText),
              weight: double.tryParse(weightText.replaceAll(',', '.')),
              isDone: isDone,
            ));
          }
        }
      }

      await _gymService.saveTraining(training, sets);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                    itemCount: _exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _exercises[index];
                      final equipmentName = _equipmentMap[exercise.equipmentId]?.name ?? 'Unbekannt';

                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                equipmentName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              _buildSetRows(exercise),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finishTraining,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Training beenden & speichern', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSetRows(GymPlanExercise exercise) {
    List<Widget> rows = [];
    // Header
    rows.add(
      const Padding(
        padding: EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            SizedBox(width: 30, child: Text('Satz', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: 16),
            Expanded(child: Text('Wdh.', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: 16),
            Expanded(child: Text('Gewicht (kg)', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: 40), // Checkbox space
          ],
        ),
      ),
    );

    for (int i = 1; i <= exercise.setCount; i++) {
      final key = '${exercise.equipmentId}_$i';

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey.shade200,
                  child: Text('$i', style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _repsControllers[key],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _weightControllers[key],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              Checkbox(
                value: _doneStates[key],
                onChanged: (val) {
                  setState(() {
                    _doneStates[key] = val ?? false;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

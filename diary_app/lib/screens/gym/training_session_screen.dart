import 'dart:async';
import 'package:flutter/material.dart';
import 'package:diary_app/models/gym/gym_plan.dart';
import 'package:diary_app/models/gym/gym_exercise.dart';
import 'package:diary_app/models/gym/gym_training.dart';
import 'package:diary_app/services/gym_service.dart';
import 'package:diary_app/services/settings_service.dart';
import 'package:vibration/vibration.dart';

class TrainingSessionScreen extends StatefulWidget {
  final GymPlan plan;
  final DateTime? date;

  const TrainingSessionScreen({super.key, required this.plan, this.date});

  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class SessionSet {
  int setNumber;
  double? weight;
  int? reps;
  bool isDone;
  int durationSeconds;
  bool isWarmup;

  // UI State
  bool isActive; // Timer running
  DateTime? startTime;

  final TextEditingController weightController;
  final TextEditingController repsController;

  SessionSet({
    required this.setNumber,
    this.weight,
    this.reps,
    this.isDone = false,
    this.durationSeconds = 0,
    this.isWarmup = false,
    this.isActive = false,
  }) :
    weightController = TextEditingController(text: weight?.toString() ?? ''),
    repsController = TextEditingController(text: reps?.toString() ?? '');
}

class SessionExercise {
  GymExercise exercise;
  List<SessionSet> sets;
  String targetReps;

  SessionExercise({
    required this.exercise,
    required this.sets,
    this.targetReps = '',
  });
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen> {
  final GymService _gymService = GymService();
  final SettingsService _settingsService = SettingsService();

  List<SessionExercise> _exercises = [];
  bool _isLoading = true;
  DateTime _sessionStartTime = DateTime.now();

  // Rest Timer State
  Timer? _restTimer;
  int _restSeconds = 0;
  bool _isResting = false;
  int _targetRestDuration = 150; // Default 2:30, will be updated from settings

  // Active Set Timer (to update UI if needed, though main logic uses timestamps)
  Timer? _activeSetTicker;

  @override
  void initState() {
    super.initState();
    if (widget.date != null) {
      _sessionStartTime = widget.date!;
    }
    _loadSession();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final duration = await _settingsService.getRestTimerDuration();
    if (mounted) {
      setState(() {
        _targetRestDuration = duration;
      });
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _activeSetTicker?.cancel();
    for (var ex in _exercises) {
      for (var s in ex.sets) {
        s.weightController.dispose();
        s.repsController.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadSession() async {
    try {
      final planExercises = await _gymService.getExercisesForPlan(widget.plan.id!);
      // Fetch last training values for this plan (before this date if set)
      final lastSetsMap = await _gymService.getLastTrainingSets(widget.plan.id!, beforeDate: widget.date);

      final exercises = <SessionExercise>[];

      // Fetch exercise details for each plan item
      final allExercises = await _gymService.getAllExercises();
      final exerciseMap = {for (var e in allExercises) e.id: e};

      for (var pe in planExercises) {
        final exerciseDef = exerciseMap[pe.exerciseId];
        if (exerciseDef == null) continue;

        final sets = <SessionSet>[];
        for (var i = 1; i <= pe.setCount; i++) {
          // Try to find last values
          final lastKey = '${pe.exerciseId}_$i';
          final lastSet = lastSetsMap[lastKey];

          sets.add(SessionSet(
            setNumber: i,
            weight: lastSet?.weight,
            reps: lastSet?.reps, // Or maybe null reps? Usually you want target or last reps.
            isWarmup: pe.isWarmup,
          ));
        }

        exercises.add(SessionExercise(
          exercise: exerciseDef,
          sets: sets,
          targetReps: pe.targetReps ?? '',
        ));
      }

      if (mounted) {
        setState(() {
          _exercises = exercises;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  // --- Logic for Adding/Removing Exercises Mid-Session ---

  Future<void> _addExercise() async {
    // Reuse the dialog logic? Or simple selection.
    // I'll implement a simple selection dialog here.
    final allExercises = await _gymService.getAllExercises();

    // Show dialog
    final GymExercise? selected = await showDialog<GymExercise>(
      context: context,
      builder: (context) => _SimpleExerciseSelector(exercises: allExercises),
    );

    if (selected != null) {
      // Pre-fill logic
      final lastSet = await _gymService.getLatestSetForExercise(selected.id!);

      final sets = <SessionSet>[];
      // Default 3 sets
      for (var i = 1; i <= 3; i++) {
        sets.add(SessionSet(
          setNumber: i,
          weight: lastSet?.weight, // Use last weight if available
          reps: lastSet?.reps,
          isWarmup: false,
        ));
      }

      setState(() {
        _exercises.add(SessionExercise(
          exercise: selected,
          sets: sets,
          targetReps: '', // No target reps for ad-hoc? Or allow edit.
        ));
      });
    }
  }

  // --- Timer Logic ---

  void _toggleSetTimer(SessionSet set) {
    setState(() {
      if (set.isActive) {
        // STOP Timer
        set.isActive = false;
        final duration = DateTime.now().difference(set.startTime!).inSeconds;
        set.durationSeconds = duration;
        set.startTime = null; // Clear start time
        set.isDone = true; // Mark as done

        // Start Rest Timer
        _startRestTimer();
      } else {
        // START Timer
        // Stop any other active timers?
        // Stop Rest Timer
        _stopRestTimer();

        // Stop other active sets (if any) - enforcing one active set
        for (var ex in _exercises) {
          for (var s in ex.sets) {
            if (s.isActive) {
               s.isActive = false;
               // Don't mark as done/save duration if force-switched? Or maybe just pause?
               // Let's assume user knows what they are doing. Just stop tracking.
            }
          }
        }

        set.isActive = true;
        set.startTime = DateTime.now();
        set.isDone = false; // Reset done status if re-doing?
      }
    });
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    _restSeconds = 0;
    _isResting = true;
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mounted) {
        setState(() {
          _restSeconds++;
        });

        // Trigger vibration if target reached
        if (_restSeconds == _targetRestDuration) {
           if (await Vibration.hasVibrator() ?? false) {
             Vibration.vibrate();
           }
        }
      }
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSeconds = 0;
    });
  }

  Future<void> _confirmFinishSession() async {
    int rating = 0;
    String note = '';
    final noteController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Training abschließen'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Wie war das Training?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Notiz',
                      border: OutlineInputBorder(),
                      hintText: 'Besonderheiten, Probleme...',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Cancel
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () {
                   note = noteController.text;
                   Navigator.pop(context, true); // Confirm
                },
                child: const Text('Fertigstellen'),
              ),
            ],
          );
        },
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _finishSession(rating, note);
      }
    });
  }

  Future<void> _finishSession(int rating, String note) async {
    // Save logic
    setState(() => _isLoading = true);

    try {
      final training = GymTraining(
        planId: widget.plan.id!,
        date: _sessionStartTime, // Or DateTime.now()? Usually start time or end time. Let's use start.
        rating: rating > 0 ? rating : null,
        note: note.isNotEmpty ? note : null,
      );

      final setsToSave = <GymSet>[];

      for (var ex in _exercises) {
        for (var s in ex.sets) {
          if (s.isDone) { // Only save done sets? Or all? Usually only done.
            final weight = double.tryParse(s.weightController.text.replaceAll(',', '.'));
            final reps = int.tryParse(s.repsController.text);

            setsToSave.add(GymSet(
              trainingId: 0, // Ignored
              exerciseId: ex.exercise.id!,
              setNumber: s.setNumber,
              weight: weight,
              reps: reps,
              isDone: true,
              durationSeconds: s.durationSeconds,
              isWarmup: s.isWarmup,
            ));
          }
        }
      }

      await _gymService.saveTraining(training, setsToSave);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Error
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmFinishSession,
          )
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), // Space for rest timer
                  itemCount: _exercises.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) newIndex -= 1;
                      final item = _exercises.removeAt(oldIndex);
                      _exercises.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    return Card(
                      key: ObjectKey(exercise),
                      margin: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(exercise.exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(exercise.targetReps.isNotEmpty ? 'Ziel: ${exercise.targetReps}' : ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      final nextSetNum = exercise.sets.length + 1;
                                      // Copy previous values
                                      final prevSet = exercise.sets.last;
                                      exercise.sets.add(SessionSet(
                                        setNumber: nextSetNum,
                                        weight: double.tryParse(prevSet.weightController.text),
                                        reps: int.tryParse(prevSet.repsController.text),
                                        isWarmup: prevSet.isWarmup,
                                      ));
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                     setState(() {
                                       _exercises.removeAt(index);
                                     });
                                  },
                                ),
                                const Icon(Icons.drag_handle),
                              ],
                            ),
                          ),
                          // Headers
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: const [
                                SizedBox(width: 30, child: Text('Satz', style: TextStyle(fontWeight: FontWeight.bold))),
                                SizedBox(width: 16),
                                Expanded(child: Text('kg', style: TextStyle(fontWeight: FontWeight.bold))),
                                SizedBox(width: 16),
                                Expanded(child: Text('Wdh.', style: TextStyle(fontWeight: FontWeight.bold))),
                                SizedBox(width: 16),
                                SizedBox(width: 60, child: Text('Action', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          const Divider(),
                          _buildSetsList(exercise.sets.where((s) => s.isWarmup).toList(), 'Aufwärmsätze', Colors.orange),
                          _buildSetsList(exercise.sets.where((s) => !s.isWarmup).toList(), 'Arbeitssätze', Theme.of(context).primaryColor),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),

          // Floating Action Button to Add Exercise
          Positioned(
            bottom: _isResting ? 80 : 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _addExercise,
              child: const Icon(Icons.add),
            ),
          ),

          // Rest Timer Overlay
          if (_isResting)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black87,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: Colors.white),
                    const SizedBox(width: 16),
                    Text(
                      _formatDuration(_restSeconds),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: _stopRestTimer,
                      child: const Text('Stop Rest', style: TextStyle(color: Colors.redAccent)),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSetsList(List<SessionSet> sets, String title, Color color) {
    if (sets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sets.length,
          itemBuilder: (context, setIndex) {
            final set = sets[setIndex];
            return Container(
              color: set.isWarmup
                  ? Colors.orange.withOpacity(0.05)
                  : (set.isDone ? Colors.green.withOpacity(0.05) : null),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          set.isWarmup = !set.isWarmup;
                        });
                      },
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: set.isWarmup
                            ? Colors.orange
                            : Theme.of(context).colorScheme.secondaryContainer,
                        child: Text('${set.setNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: set.isWarmup
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSecondaryContainer,
                            )),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: set.weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: set.repsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: set.isActive
                            ? Colors.red
                            : (set.isDone ? Colors.green : Theme.of(context).primaryColor),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(60, 36),
                      ),
                      onPressed: () => _toggleSetTimer(set),
                      child: set.isActive
                          ? const Icon(Icons.stop, size: 20)
                          : (set.isDone ? const Icon(Icons.check, size: 20) : const Text('GO')),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _SimpleExerciseSelector extends StatefulWidget {
  final List<GymExercise> exercises;
  const _SimpleExerciseSelector({required this.exercises});

  @override
  State<_SimpleExerciseSelector> createState() => _SimpleExerciseSelectorState();
}

class _SimpleExerciseSelectorState extends State<_SimpleExerciseSelector> {
  final TextEditingController _searchController = TextEditingController();
  late List<GymExercise> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.exercises;
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filtered = widget.exercises.where((e) => e.name.toLowerCase().contains(query)).toList();
      });
    });
  }

  Future<void> _createNewExercise() async {
    final name = _searchController.text.trim();
    if (name.isEmpty) return;

    final GymService service = GymService();
    final newEx = await service.addExercise(name);
    if (mounted) {
      Navigator.pop(context, newEx);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Übung hinzufügen'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Suchen...',
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtered.length +
                  (_searchController.text.isNotEmpty &&
                   !_filtered.any((e) => e.name.toLowerCase() == _searchController.text.toLowerCase())
                   ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _filtered.length) {
                    final ex = _filtered[index];
                    return ListTile(
                      title: Text(ex.name),
                      onTap: () => Navigator.pop(context, ex),
                    );
                  } else {
                    return ListTile(
                      leading: const Icon(Icons.add),
                      title: Text('Neu erstellen: "${_searchController.text}"'),
                      onTap: _createNewExercise,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
      ],
    );
  }
}

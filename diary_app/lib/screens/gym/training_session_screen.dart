import 'dart:async';
import 'package:flutter/material.dart';
import 'package:diary_app/models/gym/gym_plan.dart';
import 'package:diary_app/models/gym/gym_exercise.dart';
import 'package:diary_app/models/gym/gym_training.dart';
import 'package:diary_app/services/gym_service.dart';
import 'package:diary_app/services/settings_service.dart';
import 'package:intl/intl.dart';
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

  List<SessionExercise> _exercises = [];
  bool _isLoading = true;
  DateTime _sessionStartTime = DateTime.now();

  // Rest Timer State
  Timer? _restTimer;
  int _restSeconds = 0;
  bool _isResting = false;
  int _targetRestSeconds = 150;
  bool _hasVibrated = false;

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
    final settingsService = SettingsService();
    _targetRestSeconds = await settingsService.getRestTimerDuration();
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
    _hasVibrated = false;
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mounted) {
        setState(() {
          _restSeconds++;
        });

        if (_restSeconds >= _targetRestSeconds && !_hasVibrated) {
          _hasVibrated = true;
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

  Future<void> _finishSession() async {
    // Show rating/note dialog
    int? rating;
    String? note;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TrainingFinishDialog(
        onResult: (r, n) {
          rating = r;
          note = n;
        },
      ),
    );

    // Save regardless of cancel or save, using whatever values were provided
    setState(() => _isLoading = true);

    try {
      final endTime = DateTime.now();
      final durationSeconds = endTime.difference(_sessionStartTime).inSeconds;

      final training = GymTraining(
        planId: widget.plan.id!,
        date: _sessionStartTime,
        durationSeconds: durationSeconds,
        rating: rating,
        note: note,
      );

      final setsToSave = <GymSet>[];

      for (var ex in _exercises) {
        for (var s in ex.sets) {
          if (s.isDone) {
            final weight = double.tryParse(s.weightController.text.replaceAll(',', '.'));
            final reps = int.tryParse(s.repsController.text);

            setsToSave.add(GymSet(
              trainingId: 0,
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
            onPressed: _finishSession,
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            title: Text(exercise.exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(exercise.targetReps.isNotEmpty ? 'Ziel: ${exercise.targetReps}' : ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.grey),
                                  onPressed: () {
                                     setState(() {
                                       _exercises.removeAt(index);
                                     });
                                  },
                                ),
                                const Icon(Icons.drag_handle, color: Colors.grey),
                              ],
                            ),
                          ),
                          // Headers
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: const [
                                SizedBox(width: 30, child: Text('Satz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                SizedBox(width: 16),
                                Expanded(child: Text('kg', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                SizedBox(width: 16),
                                Expanded(child: Text('Wdh.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                SizedBox(width: 16),
                                SizedBox(width: 60, child: Text('Action', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              ],
                            ),
                          ),
                          const Divider(),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: exercise.sets.length,
                            itemBuilder: (context, setIndex) {
                              final set = exercise.sets[setIndex];
                              return Container(
                                color: set.isWarmup ? Colors.orange.withOpacity(0.1) : (set.isDone ? Colors.green.withOpacity(0.1) : null),
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                            backgroundColor: set.isWarmup ? Colors.orange : Colors.grey.shade300,
                                            child: Text('${set.setNumber}', style: const TextStyle(fontSize: 12, color: Colors.white)),
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
                                        backgroundColor: set.isActive ? Colors.red : (set.isDone ? Colors.green : Theme.of(context).colorScheme.primary),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text('Satz hinzufügen'),
                                    onPressed: () {
                                      setState(() {
                                        final nextSetNum = exercise.sets.length + 1;
                                        // Copy previous values
                                        final prevSet = exercise.sets.isNotEmpty ? exercise.sets.last : null;
                                        exercise.sets.add(SessionSet(
                                          setNumber: nextSetNum,
                                          weight: prevSet?.weightController.text.isNotEmpty == true ? double.tryParse(prevSet!.weightController.text) : null,
                                          reps: prevSet?.repsController.text.isNotEmpty == true ? int.tryParse(prevSet!.repsController.text) : null,
                                          isWarmup: prevSet?.isWarmup ?? false,
                                        ));
                                      });
                                    },
                                  ),
                                ),
                                if (exercise.sets.isNotEmpty)
                                  Expanded(
                                    child: TextButton.icon(
                                      icon: const Icon(Icons.remove, color: Colors.redAccent),
                                      label: const Text('Satz entfernen', style: TextStyle(color: Colors.redAccent)),
                                      onPressed: () {
                                        setState(() {
                                          exercise.sets.removeLast();
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

          // Button to finish training early (at the bottom)
          if (!_isLoading && _exercises.isNotEmpty)
            Positioned(
              bottom: _isResting ? 80 : 16,
              left: 16,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: _finishSession,
                icon: const Icon(Icons.check_circle),
                label: const Text('Training abschließen', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
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

class _TrainingFinishDialog extends StatefulWidget {
  final Function(int?, String?) onResult;

  const _TrainingFinishDialog({required this.onResult});

  @override
  State<_TrainingFinishDialog> createState() => _TrainingFinishDialogState();
}

class _TrainingFinishDialogState extends State<_TrainingFinishDialog> {
  int? _rating;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Training abschließen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Wie war das Training? (optional)'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < (_rating ?? 0) ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Anmerkungen (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Abbrechen (speichert ohne Bewertung)
          child: const Text('Überspringen'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onResult(_rating, _noteController.text.isEmpty ? null : _noteController.text);
            Navigator.pop(context); // Speichern
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
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

import 'package:flutter/material.dart';
import 'package:diary_app/models/gym/gym_plan.dart';
import 'package:diary_app/models/gym/gym_exercise.dart';
import 'package:diary_app/services/gym_service.dart';

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class PlanExerciseItem {
  GymExercise exercise;
  int sets;
  String targetReps;
  bool isWarmup;

  PlanExerciseItem({
    required this.exercise,
    this.sets = 3,
    this.targetReps = '',
    this.isWarmup = false,
  });
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final GymService _gymService = GymService();
  final _nameController = TextEditingController();

  final List<PlanExerciseItem> _addedExercises = [];
  bool _isLoading = false;

  Future<void> _addExercise() async {
    final result = await showDialog<PlanExerciseItem>(
      context: context,
      builder: (context) => const _ExerciseDialog(),
    );

    if (result != null) {
      setState(() {
        _addedExercises.add(result);
      });
    }
  }

  Future<void> _editExercise(int index) async {
    final item = _addedExercises[index];
    final result = await showDialog<PlanExerciseItem>(
      context: context,
      builder: (context) => _ExerciseDialog(initialItem: item),
    );

    if (result != null) {
      setState(() {
        _addedExercises[index] = result;
      });
    }
  }

  Future<void> _savePlan() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Namen für den Plan eingeben.')),
      );
      return;
    }
    if (_addedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte mindestens eine Übung hinzufügen.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final exercises = _addedExercises.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        return GymPlanExercise(
          planId: 0, // Ignored by createPlan
          exerciseId: item.exercise.id!,
          setCount: item.sets,
          sortOrder: index,
          targetReps: item.targetReps,
          isWarmup: item.isWarmup,
        );
      }).toList();

      await _gymService.createPlan(GymPlan(name: name), exercises);

      if (mounted) {
        Navigator.pop(context, true); // Return success
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
        title: const Text('Neuer Trainingsplan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name des Plans',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                Expanded(
                  child: _addedExercises.isEmpty
                      ? Center(
                          child: Text(
                            'Keine Übungen hinzugefügt.',
                            style: TextStyle(color: Theme.of(context).disabledColor),
                          ),
                        )
                      : ReorderableListView.builder(
                          itemCount: _addedExercises.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }
                              final item = _addedExercises.removeAt(oldIndex);
                              _addedExercises.insert(newIndex, item);
                            });
                          },
                          itemBuilder: (context, index) {
                            final item = _addedExercises[index];
                            return Card(
                              key: ObjectKey(item), // Unique key for reordering
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: item.isWarmup ? Colors.orangeAccent : Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  child: item.isWarmup ? const Icon(Icons.hot_tub, size: 20) : Text('${index + 1}'),
                                ),
                                title: Text(item.exercise.name),
                                subtitle: Text(
                                  '${item.sets} Sätze${item.targetReps.isNotEmpty ? ' • ${item.targetReps} Wdh.' : ''}${item.isWarmup ? ' • Aufwärmen' : ''}',
                                ),
                                onTap: () => _editExercise(index),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.grey),
                                      onPressed: () => _editExercise(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () {
                                        setState(() {
                                          _addedExercises.removeAt(index);
                                        });
                                      },
                                    ),
                                    const Icon(Icons.drag_handle, color: Colors.grey),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addExercise,
                          icon: const Icon(Icons.add),
                          label: const Text('Übung hinzufügen'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _savePlan,
                          child: const Text('Plan speichern'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ExerciseDialog extends StatefulWidget {
  final PlanExerciseItem? initialItem;

  const _ExerciseDialog({this.initialItem});

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  final GymService _gymService = GymService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _setsController = TextEditingController(text: '3');
  final TextEditingController _targetRepsController = TextEditingController();

  List<GymExercise> _allExercises = [];
  List<GymExercise> _filteredExercises = [];
  bool _isLoading = true;
  bool _isWarmup = false;

  // Step 1: Select Exercise. Step 2: Details.
  GymExercise? _selectedExercise;

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      _selectedExercise = widget.initialItem!.exercise;
      _setsController.text = widget.initialItem!.sets.toString();
      _targetRepsController.text = widget.initialItem!.targetReps;
      _isWarmup = widget.initialItem!.isWarmup;
      _isLoading = false; // Skip loading list if editing (unless we want to allow changing exercise?)
      // If editing, we stay on details view.
    } else {
      _loadExercises();
    }
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _setsController.dispose();
    _targetRepsController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final list = await _gymService.getAllExercises();
      if (mounted) {
        setState(() {
          _allExercises = list;
          _filteredExercises = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  void _filter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExercises = _allExercises
          .where((e) => e.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _createNewExercise() async {
    final name = _searchController.text.trim();
    if (name.isEmpty) return;

    final newEx = await _gymService.addExercise(name);
    // Reload and select
    final list = await _gymService.getAllExercises();
    if (mounted) {
      setState(() {
        _allExercises = list;
        _filteredExercises = list;
        _selectedExercise = newEx;
        _searchController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If exercise is selected, show Details input
    if (_selectedExercise != null) {
      return AlertDialog(
        title: Text(_selectedExercise!.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _setsController,
                decoration: const InputDecoration(labelText: 'Anzahl Sätze'),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _targetRepsController,
                decoration: const InputDecoration(
                  labelText: 'Ziel-Wiederholungen (z.B. 6-8)',
                  hintText: '6-8',
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Aufwärmsatz'),
                value: _isWarmup,
                onChanged: (val) {
                  setState(() {
                    _isWarmup = val ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
        actions: [
          if (widget.initialItem == null) // Only show back if we came from selection
            TextButton(
              onPressed: () => setState(() => _selectedExercise = null),
              child: const Text('Zurück'),
            ),
          ElevatedButton(
            onPressed: () {
              final sets = int.tryParse(_setsController.text) ?? 3;
              final targetReps = _targetRepsController.text.trim();
              Navigator.pop(
                context,
                PlanExerciseItem(
                  exercise: _selectedExercise!,
                  sets: sets,
                  targetReps: targetReps,
                  isWarmup: _isWarmup,
                ),
              );
            },
            child: Text(widget.initialItem != null ? 'Speichern' : 'Hinzufügen'),
          ),
        ],
      );
    }

    // Otherwise show search list
    return AlertDialog(
      title: const Text('Übung auswählen'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Suchen...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredExercises.length +
                        (_searchController.text.isNotEmpty &&
                         !_filteredExercises.any((e) => e.name.toLowerCase() == _searchController.text.toLowerCase())
                         ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _filteredExercises.length) {
                          final ex = _filteredExercises[index];
                          return ListTile(
                            title: Text(ex.name),
                            subtitle: ex.description != null ? Text(ex.description!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                            onTap: () {
                              setState(() {
                                _selectedExercise = ex;
                              });
                            },
                          );
                        } else {
                          // "Create new" option
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:diary_app/models/gym/gym_plan.dart';
import 'package:diary_app/models/gym/gym_equipment.dart';
import 'package:diary_app/services/gym_service.dart';

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final GymService _gymService = GymService();
  final _nameController = TextEditingController();

  // List of added exercises. Each item is a map with equipment and set count.
  final List<Map<String, dynamic>> _addedExercises = [];

  bool _isLoading = false;

  Future<void> _addExercise() async {
    // Open dialog to select equipment and sets
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _SelectEquipmentDialog(),
    );

    if (result != null) {
      final equipment = result['equipment'] as GymEquipment;
      final sets = result['sets'] as int;
      setState(() {
        _addedExercises.add({
          'equipment': equipment,
          'sets': sets,
        });
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
        final map = entry.value;
        final equipment = map['equipment'] as GymEquipment;
        final sets = map['sets'] as int;

        return GymPlanExercise(
          planId: 0, // Ignored by createPlan
          equipmentId: equipment.id!,
          setCount: sets,
          sortOrder: index,
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
                      : ListView.builder(
                          itemCount: _addedExercises.length,
                          itemBuilder: (context, index) {
                            final item = _addedExercises[index];
                            final equipment = item['equipment'] as GymEquipment;
                            final sets = item['sets'] as int;
                            return ListTile(
                              leading: CircleAvatar(child: Text('${index + 1}')),
                              title: Text(equipment.name),
                              subtitle: Text('$sets Sätze'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    _addedExercises.removeAt(index);
                                  });
                                },
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
                          label: const Text('Gerät hinzufügen'),
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

class _SelectEquipmentDialog extends StatefulWidget {
  const _SelectEquipmentDialog();

  @override
  State<_SelectEquipmentDialog> createState() => _SelectEquipmentDialogState();
}

class _SelectEquipmentDialogState extends State<_SelectEquipmentDialog> {
  final GymService _gymService = GymService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _setsController = TextEditingController(text: '3');

  List<GymEquipment> _allEquipment = [];
  List<GymEquipment> _filteredEquipment = [];
  bool _isLoading = true;

  // Step 1: Select Equipment. Step 2: Select Sets.
  GymEquipment? _selectedEquipment;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _setsController.dispose();
    super.dispose();
  }

  Future<void> _loadEquipment() async {
    final list = await _gymService.getAllEquipment();
    if (mounted) {
      setState(() {
        _allEquipment = list;
        _filteredEquipment = list;
        _isLoading = false;
      });
    }
  }

  void _filter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEquipment = _allEquipment
          .where((e) => e.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _createNewEquipment() async {
    final name = _searchController.text.trim();
    if (name.isEmpty) return;

    final newEq = await _gymService.addEquipment(name);
    // Reload and select
    final list = await _gymService.getAllEquipment();
    if (mounted) {
      setState(() {
        _allEquipment = list;
        _filteredEquipment = list;
        _selectedEquipment = newEq;
        _searchController.clear(); // Or keep it?
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If equipment is selected, show Sets input
    if (_selectedEquipment != null) {
      return AlertDialog(
        title: Text(_selectedEquipment!.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _setsController,
              decoration: const InputDecoration(labelText: 'Anzahl Sätze'),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _selectedEquipment = null),
            child: const Text('Zurück'),
          ),
          ElevatedButton(
            onPressed: () {
              final sets = int.tryParse(_setsController.text) ?? 3;
              Navigator.pop(context, {
                'equipment': _selectedEquipment,
                'sets': sets,
              });
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      );
    }

    // Otherwise show search list
    return AlertDialog(
      title: const Text('Gerät auswählen'),
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
                      itemCount: _filteredEquipment.length +
                        (_searchController.text.isNotEmpty &&
                         !_filteredEquipment.any((e) => e.name.toLowerCase() == _searchController.text.toLowerCase())
                         ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _filteredEquipment.length) {
                          final eq = _filteredEquipment[index];
                          return ListTile(
                            title: Text(eq.name),
                            onTap: () {
                              setState(() {
                                _selectedEquipment = eq;
                              });
                            },
                          );
                        } else {
                          // "Create new" option
                          return ListTile(
                            leading: const Icon(Icons.add),
                            title: Text('Neu erstellen: "${_searchController.text}"'),
                            onTap: _createNewEquipment,
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

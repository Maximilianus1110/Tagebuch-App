import 'package:flutter/material.dart';
import 'package:diary_app/models/gym/gym_exercise.dart';
import 'package:diary_app/services/gym_service.dart';

class ManageExercisesScreen extends StatefulWidget {
  const ManageExercisesScreen({super.key});

  @override
  State<ManageExercisesScreen> createState() => _ManageExercisesScreenState();
}

class _ManageExercisesScreenState extends State<ManageExercisesScreen> {
  final GymService _gymService = GymService();
  List<GymExercise> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final exercises = await _gymService.getAllExercises();
      if (mounted) {
        setState(() {
          _exercises = exercises;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }

  Future<void> _showExerciseDialog([GymExercise? exercise]) async {
    final nameController = TextEditingController(text: exercise?.name ?? '');
    final descController = TextEditingController(text: exercise?.description ?? '');
    final isEditing = exercise != null;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Übung bearbeiten' : 'Neue Übung'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name der Übung'),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung (optional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'description': descController.text.trim(),
                });
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (isEditing) {
        final updated = exercise!.copyWith(
          name: result['name'],
          description: result['description'],
        );
        await _gymService.updateExercise(updated);
      } else {
        await _gymService.addExercise(result['name']!, result['description']);
      }
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Übungen verwalten'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Keine Übungen vorhanden.\nFüge welche hinzu!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).disabledColor),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _exercises.length,
                  itemBuilder: (context, index) {
                    final item = _exercises[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.fitness_center),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: item.description != null && item.description!.isNotEmpty
                            ? Text(
                                item.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () => _showExerciseDialog(item),
                        trailing: const Icon(Icons.edit, color: Colors.grey),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExerciseDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

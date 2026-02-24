import 'package:flutter/material.dart';
import 'package:diary_app/models/gym/gym_equipment.dart';
import 'package:diary_app/services/gym_service.dart';

class ManageEquipmentScreen extends StatefulWidget {
  const ManageEquipmentScreen({super.key});

  @override
  State<ManageEquipmentScreen> createState() => _ManageEquipmentScreenState();
}

class _ManageEquipmentScreenState extends State<ManageEquipmentScreen> {
  final GymService _gymService = GymService();
  List<GymEquipment> _equipment = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final equipment = await _gymService.getAllEquipment();
    if (mounted) {
      setState(() {
        _equipment = equipment;
        _isLoading = false;
      });
    }
  }

  Future<void> _addEquipment() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neues Gerät hinzufügen'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name des Geräts'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, nameController.text.trim());
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _gymService.addEquipment(result);
      _loadData(); // Refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geräte verwalten'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _equipment.isEmpty
              ? const Center(child: Text('Keine Geräte vorhanden.'))
              : ListView.builder(
                  itemCount: _equipment.length,
                  itemBuilder: (context, index) {
                    final item = _equipment[index];
                    return ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text(item.name),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEquipment,
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diary_app/models/kitchen/kitchen_item.dart';
import 'package:diary_app/services/kitchen_service.dart';

class AddKitchenItemScreen extends StatefulWidget {
  const AddKitchenItemScreen({super.key});

  @override
  State<AddKitchenItemScreen> createState() => _AddKitchenItemScreenState();
}

class _AddKitchenItemScreenState extends State<AddKitchenItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final KitchenService _kitchenService = KitchenService();

  final _nameController = TextEditingController();
  final _basisProduktController = TextEditingController();
  final _markeController = TextEditingController();
  final _mengeController = TextEditingController();
  final _tagsController = TextEditingController();

  String _selectedEinheit = 'g';
  final List<String> _einheiten = ['g', 'kg', 'ml', 'l', 'Stück'];
  DateTime? _selectedDate;

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _basisProduktController.dispose();
    _markeController.dispose();
    _mengeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final inputMengeText = _mengeController.text.replaceAll(',', '.');
      double menge = double.parse(inputMengeText);
      String finalEinheit = _selectedEinheit;

      // Convert kg to g and l to ml
      if (_selectedEinheit == 'kg') {
        menge = menge * 1000;
        finalEinheit = 'g';
      } else if (_selectedEinheit == 'l') {
        menge = menge * 1000;
        finalEinheit = 'ml';
      }

      final newItem = KitchenItem(
        name: _nameController.text.trim(),
        basisProdukt: _basisProduktController.text.trim(),
        marke: _markeController.text.trim().isEmpty ? null : _markeController.text.trim(),
        menge: menge,
        einheit: finalEinheit,
        haltbarBis: _selectedDate,
        hinzugefuegt: DateTime.now(),
      );

      final tagsString = _tagsController.text;
      final tagsList = tagsString
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      await _kitchenService.createItem(newItem, tagsList);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern: \$e')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neuen Vorrat hinzufügen'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveItem,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Produktname (z.B. Barilla Spaghetti No. 5)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte einen Namen eingeben.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _basisProduktController,
                decoration: const InputDecoration(
                  labelText: 'Basis-Produkt (z.B. Spaghetti, Milch)',
                  border: OutlineInputBorder(),
                  helperText: 'Dient der Gruppierung in der Übersicht.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte ein Basis-Produkt eingeben.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _markeController,
                decoration: const InputDecoration(
                  labelText: 'Marke (optional, z.B. Barilla)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _mengeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Menge',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Bitte eine Menge eingeben.';
                        }
                        if (double.tryParse(value.replaceAll(',', '.')) == null) {
                          return 'Ungültige Zahl.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedEinheit,
                      decoration: const InputDecoration(
                        labelText: 'Einheit',
                        border: OutlineInputBorder(),
                      ),
                      items: _einheiten.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedEinheit = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'Kein Ablaufdatum ausgewählt!'
                          : 'Haltbar bis: \${DateFormat("dd.MM.yyyy").format(_selectedDate!)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: _presentDatePicker,
                    child: const Text('Datum wählen'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (kommagetrennt, z.B. Nudeln, Vorrat)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saveItem,
                icon: const Icon(Icons.save),
                label: const Text('Speichern'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

  final _basisProduktController = TextEditingController();
  final _markeController = TextEditingController();
  final _mengeController = TextEditingController();
  final _tagsController = TextEditingController();
  final _dateController = TextEditingController();

  String _name = '';

  String _selectedEinheit = 'g';
  final List<String> _einheiten = ['g', 'kg', 'ml', 'l', 'Stück'];
  DateTime? _selectedDate;

  bool _isSaving = false;
  List<Map<String, dynamic>> _autocompleteOptions = [];

  @override
  void initState() {
    super.initState();
    _loadAutocompleteOptions();
  }

  Future<void> _loadAutocompleteOptions() async {
    final options = await _kitchenService.getDistinctItemsForAutocomplete();
    if (mounted) {
      setState(() {
        _autocompleteOptions = options;
      });
    }
  }

  @override
  void dispose() {
    _basisProduktController.dispose();
    _markeController.dispose();
    _mengeController.dispose();
    _tagsController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('dd.MM.yyyy').format(pickedDate);
      });
    });
  }

  void _onDateTextChanged(String value) {
    if (value.length == 10) {
      try {
        final parsed = DateFormat('dd.MM.yyyy').parseStrict(value);
        setState(() {
          _selectedDate = parsed;
        });
      } catch (e) {
        // invalid date format
      }
    } else {
       setState(() {
        _selectedDate = null;
      });
    }
  }

  void _onAutocompleteSelected(Map<String, dynamic> selection) {
    setState(() {
      _name = selection['name'] as String;
      _basisProduktController.text = selection['basisProdukt'] as String;

      if (selection['marke'] != null) {
        _markeController.text = selection['marke'] as String;
      }

      final einheit = selection['einheit'] as String;
      if (_einheiten.contains(einheit)) {
        _selectedEinheit = einheit;
      }

      if (selection['tags'] != null && selection['tags'].toString().isNotEmpty) {
        _tagsController.text = selection['tags'] as String;
      }
    });
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation for autocomplete since it's not a normal controller
    if (_name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Produktnamen eingeben.')),
      );
      return;
    }

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
        name: _name.trim(),
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
        SnackBar(content: Text('Fehler beim Speichern: $e')),
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
              Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Map<String, dynamic>>.empty();
                  }
                  final query = textEditingValue.text.toLowerCase();
                  return _autocompleteOptions.where((option) {
                    final name = option['name']?.toString().toLowerCase() ?? '';
                    final basis = option['basisProdukt']?.toString().toLowerCase() ?? '';
                    final marke = option['marke']?.toString().toLowerCase() ?? '';
                    final tags = option['tags']?.toString().toLowerCase() ?? '';
                    return name.contains(query) || basis.contains(query) || marke.contains(query) || tags.contains(query);
                  });
                },
                displayStringForOption: (option) => option['name'] as String,
                onSelected: _onAutocompleteSelected,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  // Keep _name synced if user types freely without selecting
                  controller.addListener(() {
                    _name = controller.text;
                  });
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
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
                  );
                },
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  // Get distinct Basis-Produkte
                  final basisProdukts = _autocompleteOptions
                      .map((o) => o['basisProdukt']?.toString() ?? '')
                      .where((s) => s.isNotEmpty)
                      .toSet()
                      .toList();
                  return basisProdukts.where((s) => s.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  _basisProduktController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  // Bind the controller to our state controller or listen to it
                  // Actually, to make it work seamlessly and keep our validation:
                  controller.addListener(() {
                     // We just use our own controller if we sync, or we use their controller and validate it.
                     // The best way is to set _basisProduktController text when this changes
                     _basisProduktController.text = controller.text;
                  });
                  // If we already had text from autocomplete or edits:
                  if (_basisProduktController.text.isNotEmpty && controller.text.isEmpty) {
                      controller.text = _basisProduktController.text;
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
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
                  );
                },
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  // Get distinct marken
                  final marken = _autocompleteOptions
                      .map((o) => o['marke']?.toString() ?? '')
                      .where((s) => s.isNotEmpty)
                      .toSet()
                      .toList();
                  return marken.where((s) => s.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  _markeController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  controller.addListener(() {
                     _markeController.text = controller.text;
                  });
                  if (_markeController.text.isNotEmpty && controller.text.isEmpty) {
                      controller.text = _markeController.text;
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Marke (optional, z.B. Barilla)',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
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
                      value: _selectedEinheit,
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
              TextFormField(
                controller: _dateController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: 'Haltbar bis (TT.MM.JJJJ)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _presentDatePicker,
                  ),
                ),
                onChanged: _onDateTextChanged,
                validator: (value) {
                   if (value != null && value.isNotEmpty) {
                     try {
                        DateFormat('dd.MM.yyyy').parseStrict(value);
                     } catch(e) {
                        return 'Ungültiges Datum. Format: TT.MM.JJJJ';
                     }
                   }
                   return null;
                },
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

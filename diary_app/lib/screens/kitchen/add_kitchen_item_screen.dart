import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diary_app/models/kitchen/kitchen_item.dart';
import 'package:diary_app/models/kitchen/kitchen_tag.dart';
import 'package:diary_app/services/kitchen_service.dart';

class AddKitchenItemScreen extends StatefulWidget {
  final KitchenItem? existingItem;
  final List<KitchenTag>? existingTags;

  const AddKitchenItemScreen({
    super.key,
    this.existingItem,
    this.existingTags,
  });

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
  List<KitchenTag> _allExistingTags = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _name = item.name;
      _basisProduktController.text = item.basisProdukt;
      _markeController.text = item.marke ?? '';
      _selectedEinheit = item.einheit;

      // Need to convert stored g to kg, or ml to l, if we want to show it the same way?
      // It's safer to just show the stored unit and amount directly since we only store base units.
      _mengeController.text = item.menge == item.menge.toInt()
          ? item.menge.toInt().toString()
          : item.menge.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');

      if (item.haltbarBis != null) {
        _selectedDate = item.haltbarBis;
        _dateController.text = DateFormat('dd.MM.yyyy').format(item.haltbarBis!);
      }

      if (widget.existingTags != null) {
        _tagsController.text = widget.existingTags!.map((t) => t.name).join(', ');
      }
    }
    _loadAutocompleteOptions();
  }

  Future<void> _loadAutocompleteOptions() async {
    final options = await _kitchenService.getDistinctItemsForAutocomplete();
    final tags = await _kitchenService.getAllTags();
    if (mounted) {
      setState(() {
        _autocompleteOptions = options;
        _allExistingTags = tags;
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
    } else if (int.tryParse(value) != null) {
      // It's a number (days), handled by unfocus/editing complete
    } else {
       setState(() {
        _selectedDate = null;
      });
    }
  }

  void _onDateEditingComplete() {
    final text = _dateController.text;
    final days = int.tryParse(text);
    if (days != null) {
      setState(() {
        _selectedDate = DateTime.now().add(Duration(days: days));
        _dateController.text = DateFormat('dd.MM.yyyy').format(_selectedDate!);
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

      if (selection['defaultHaltbarkeitTage'] != null) {
        final days = selection['defaultHaltbarkeitTage'] as int;
        _selectedDate = DateTime.now().add(Duration(days: days));
        _dateController.text = DateFormat('dd.MM.yyyy').format(_selectedDate!);
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

      final isEditing = widget.existingItem != null;

      final newItem = KitchenItem(
        id: isEditing ? widget.existingItem!.id : null,
        name: _name.trim(),
        basisProdukt: _basisProduktController.text.trim(),
        marke: _markeController.text.trim().isEmpty ? null : _markeController.text.trim(),
        menge: menge,
        einheit: finalEinheit,
        haltbarBis: _selectedDate,
        hinzugefuegt: isEditing ? widget.existingItem!.hinzugefuegt : DateTime.now(),
      );

      final tagsString = _tagsController.text;
      final tagsList = tagsString
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (isEditing) {
        await _kitchenService.updateItem(newItem, tagsList);
      } else {
        await _kitchenService.createItem(newItem, tagsList);
      }

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
    final isEditing = widget.existingItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Vorrat bearbeiten' : 'Neuen Vorrat hinzufügen'),
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
                  if (_name.isNotEmpty && controller.text.isEmpty) {
                     controller.text = _name;
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Produktname (z.B. Barilla Spaghetti No. 5)',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () {
                       // Select all text when tapped, if desired
                    },
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
              Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus) {
                    _onDateEditingComplete();
                  }
                },
                child: TextFormField(
                  controller: _dateController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Haltbar bis (TT.MM.JJJJ oder Anzahl Tage)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _presentDatePicker,
                    ),
                  ),
                  onChanged: _onDateTextChanged,
                  onEditingComplete: () {
                    _onDateEditingComplete();
                    FocusScope.of(context).unfocus();
                  },
                  validator: (value) {
                     if (value != null && value.isNotEmpty) {
                       // Try parsing as number first
                       if (int.tryParse(value) != null) {
                         return null; // Valid number
                       }
                       try {
                          DateFormat('dd.MM.yyyy').parseStrict(value);
                       } catch(e) {
                          return 'Ungültiges Format. TT.MM.JJJJ oder Zahl (Tage)';
                       }
                     }
                     return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final text = textEditingValue.text;
                  if (text.isEmpty) {
                    return const Iterable<String>.empty();
                  }

                  // Find the current word being typed (after the last comma)
                  final parts = text.split(',');
                  final lastPart = parts.last.trimLeft();

                  if (lastPart.isEmpty) {
                     return const Iterable<String>.empty();
                  }

                  final query = lastPart.toLowerCase();
                  return _allExistingTags
                      .map((t) => t.name)
                      .where((tagName) => tagName.toLowerCase().contains(query));
                },
                onSelected: (String selection) {
                  final text = _tagsController.text;
                  final parts = text.split(',');

                  // Replace the last part with the selected tag
                  if (parts.isNotEmpty) {
                    parts.removeLast();
                  }

                  parts.add(selection);

                  // Join with commas and add a trailing comma+space for next tag
                  _tagsController.text = '${parts.map((p) => p.trim()).join(', ')}, ';
                  // Move cursor to end
                  _tagsController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _tagsController.text.length),
                  );
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  controller.addListener(() {
                     _tagsController.text = controller.text;
                  });
                  if (_tagsController.text.isNotEmpty && controller.text.isEmpty) {
                      controller.text = _tagsController.text;
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Tags (kommagetrennt, z.B. Nudeln, Vorrat)',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
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

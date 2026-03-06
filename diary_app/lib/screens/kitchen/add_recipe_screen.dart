import 'package:flutter/material.dart';
import 'package:diary_app/models/kitchen/recipe.dart';
import 'package:diary_app/models/kitchen/recipe_ingredient.dart';
import 'package:diary_app/services/recipe_service.dart';
import 'package:diary_app/services/kitchen_service.dart';

class AddRecipeScreen extends StatefulWidget {
  final Recipe? existingRecipe;
  final List<RecipeIngredient>? existingIngredients;

  const AddRecipeScreen({super.key, this.existingRecipe, this.existingIngredients});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final RecipeService _recipeService = RecipeService();
  final KitchenService _kitchenService = KitchenService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _prepTimeController;

  List<RecipeIngredientForm> _ingredients = [];
  List<String> _autocompleteOptions = [];

  final List<String> _allowedUnits = ['g', 'kg', 'ml', 'l', 'Stück'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingRecipe?.name ?? '');
    _descriptionController = TextEditingController(text: widget.existingRecipe?.description ?? '');
    _prepTimeController = TextEditingController(text: widget.existingRecipe?.prepTimeMinutes?.toString() ?? '');

    if (widget.existingIngredients != null && widget.existingIngredients!.isNotEmpty) {
      _ingredients = widget.existingIngredients!.map((ing) {
        return RecipeIngredientForm(
          basisProduktController: TextEditingController(text: ing.basisProdukt),
          mengeController: TextEditingController(text: _formatTotal(ing.menge)),
          einheit: ing.einheit,
          id: ing.id,
        );
      }).toList();
    } else {
      // Start with one empty ingredient
      _addIngredientField();
    }

    _loadAutocompleteOptions();
  }

  Future<void> _loadAutocompleteOptions() async {
    final products = await _kitchenService.getDistinctItemsForAutocomplete();
    final tags = await _kitchenService.getAllTags();

    final Set<String> optionsSet = {};
    for (var p in products) {
      if (p['basisProdukt'] != null && p['basisProdukt'].toString().isNotEmpty) {
        optionsSet.add(p['basisProdukt'].toString());
      }
    }
    for (var t in tags) {
      optionsSet.add(t.name);
    }

    if (mounted) {
      setState(() {
        _autocompleteOptions = optionsSet.toList()..sort();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    for (var ing in _ingredients) {
      ing.basisProduktController.dispose();
      ing.mengeController.dispose();
    }
    super.dispose();
  }

  void _addIngredientField() {
    setState(() {
      _ingredients.add(
        RecipeIngredientForm(
          basisProduktController: TextEditingController(),
          mengeController: TextEditingController(),
          einheit: 'g',
        )
      );
    });
  }

  void _removeIngredientField(int index) {
    setState(() {
      _ingredients[index].basisProduktController.dispose();
      _ingredients[index].mengeController.dispose();
      _ingredients.removeAt(index);
    });
  }

  String _formatTotal(double total) {
    if (total == total.toInt()) return total.toInt().toString();
    return total.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    // Filter out empty ingredients
    final validIngredientsForms = _ingredients.where((ing) =>
      ing.basisProduktController.text.trim().isNotEmpty &&
      ing.mengeController.text.trim().isNotEmpty
    ).toList();

    if (validIngredientsForms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte füge mindestens eine Zutat hinzu.')),
      );
      return;
    }

    final String name = _nameController.text.trim();
    final String description = _descriptionController.text.trim();
    final int? prepTime = int.tryParse(_prepTimeController.text.trim());

    final recipe = Recipe(
      id: widget.existingRecipe?.id,
      name: name,
      description: description.isEmpty ? null : description,
      prepTimeMinutes: prepTime,
      createdAt: widget.existingRecipe?.createdAt ?? DateTime.now(),
    );

    List<RecipeIngredient> ingredientsList = [];
    for (int i = 0; i < validIngredientsForms.length; i++) {
      final form = validIngredientsForms[i];
      final mengeText = form.mengeController.text.replaceAll(',', '.');
      final menge = double.tryParse(mengeText) ?? 0;

      ingredientsList.add(RecipeIngredient(
        id: form.id,
        recipeId: widget.existingRecipe?.id ?? 0, // 0 will be replaced in DB helper if new
        basisProdukt: form.basisProduktController.text.trim(),
        menge: menge,
        einheit: form.einheit,
        sortOrder: i,
      ));
    }

    if (widget.existingRecipe == null) {
      await _recipeService.createRecipe(recipe, ingredientsList);
    } else {
      await _recipeService.updateRecipe(recipe, ingredientsList);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRecipe == null ? 'Neues Rezept' : 'Rezept bearbeiten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveRecipe,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Rezeptname',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Bitte Namen eingeben' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Zubereitung / Beschreibung',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prepTimeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Zubereitungszeit (Minuten)',
                  border: OutlineInputBorder(),
                  suffixText: 'Min.',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Zutaten',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              const Divider(),
              ..._ingredients.asMap().entries.map((entry) {
                int idx = entry.key;
                RecipeIngredientForm ingForm = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return _autocompleteOptions.where((String option) {
                              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          onSelected: (String selection) {
                            ingForm.basisProduktController.text = selection;
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            controller.addListener(() {
                              ingForm.basisProduktController.text = controller.text;
                            });
                            if (ingForm.basisProduktController.text.isNotEmpty && controller.text.isEmpty) {
                              controller.text = ingForm.basisProduktController.text;
                            }
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Zutat (Produkt/Tag)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (ingForm.mengeController.text.isNotEmpty && (value == null || value.trim().isEmpty)) {
                                  return 'Erforderlich';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: ingForm.mengeController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Menge',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (ingForm.basisProduktController.text.isNotEmpty) {
                              if (value == null || value.trim().isEmpty) return 'Fehlt';
                              if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Zahl!';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: ingForm.einheit,
                          decoration: const InputDecoration(
                            labelText: 'Einheit',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                          ),
                          items: _allowedUnits.map((String unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                ingForm.einheit = newValue;
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => _removeIngredientField(idx),
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addIngredientField,
                icon: const Icon(Icons.add),
                label: const Text('Zutat hinzufügen'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class RecipeIngredientForm {
  int? id;
  TextEditingController basisProduktController;
  TextEditingController mengeController;
  String einheit;

  RecipeIngredientForm({
    this.id,
    required this.basisProduktController,
    required this.mengeController,
    required this.einheit,
  });
}

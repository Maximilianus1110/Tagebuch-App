import 'package:flutter/material.dart';
import 'package:diary_app/services/recipe_service.dart';
import 'package:diary_app/services/kitchen_service.dart';
import 'package:diary_app/screens/kitchen/add_recipe_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final RecipeCookability cookability;

  const RecipeDetailScreen({super.key, required this.cookability});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final RecipeService _recipeService = RecipeService();
  final KitchenService _kitchenService = KitchenService();

  late RecipeCookability _currentCookability;

  @override
  void initState() {
    super.initState();
    _currentCookability = widget.cookability;
  }

  String _formatTotal(double total) {
    if (total == total.toInt()) return total.toInt().toString();
    return total.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  Future<void> _refresh() async {
    final updatedList = await _recipeService.getRecipesSortedByCookability();
    final updatedCookability = updatedList.firstWhere(
      (c) => c.recipe.id == _currentCookability.recipe.id,
      orElse: () => _currentCookability,
    );
    if (mounted) {
      setState(() {
        _currentCookability = updatedCookability;
      });
    }
  }

  Future<void> _editRecipe() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecipeScreen(
          existingRecipe: _currentCookability.recipe,
          existingIngredients: _currentCookability.ingredients,
        ),
      ),
    );
    if (result == true) {
      _refresh();
    }
  }

  Future<void> _deleteRecipe() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rezept löschen'),
        content: const Text('Möchtest du dieses Rezept wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm == true && _currentCookability.recipe.id != null) {
      await _recipeService.deleteRecipe(_currentCookability.recipe.id!);
      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh list
      }
    }
  }

  void _showCookModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CookModal(
          cookability: _currentCookability,
          kitchenService: _kitchenService,
          onCooked: () {
            _refresh();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = _currentCookability.recipe;
    final ingredients = _currentCookability.ingredients;
    final missingCount = _currentCookability.missingIngredientsCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editRecipe),
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteRecipe),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.prepTimeMinutes != null) ...[
              Row(
                children: [
                  const Icon(Icons.timer, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${recipe.prepTimeMinutes} Min. Zubereitungszeit',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (recipe.description != null && recipe.description!.isNotEmpty) ...[
              const Text(
                'Zubereitung',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                recipe.description!,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              'Zutaten',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...ingredients.map((ing) {
              final isMissing = _currentCookability.availableItemsForIngredient[ing.id!]?.isEmpty ?? true;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isMissing ? Icons.cancel : Icons.check_circle,
                  color: isMissing ? Colors.red : Colors.green,
                ),
                title: Text(
                  ing.basisProdukt,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Text(
                  '${_formatTotal(ing.menge)} ${ing.einheit}',
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: missingCount == 0 ? Colors.green : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.restaurant_menu),
                label: Text(
                  missingCount == 0 ? 'Jetzt kochen (Alle Zutaten vorhanden)' : 'Jetzt kochen ($missingCount fehlend)',
                  style: const TextStyle(fontSize: 18),
                ),
                onPressed: _showCookModal,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class CookModal extends StatefulWidget {
  final RecipeCookability cookability;
  final KitchenService kitchenService;
  final VoidCallback onCooked;

  const CookModal({
    super.key,
    required this.cookability,
    required this.kitchenService,
    required this.onCooked,
  });

  @override
  State<CookModal> createState() => _CookModalState();
}

class _CookModalState extends State<CookModal> {
  // Map of Ingredient ID to the list of specific items to consume and their amounts
  final Map<int, Map<int, double>> _consumptionPlan = {};
  bool _isCooking = false;

  @override
  void initState() {
    super.initState();
    _autoFillPlan();
  }

  void _autoFillPlan() {
    for (var ing in widget.cookability.ingredients) {
      if (ing.id == null) continue;

      final availableItems = widget.cookability.availableItemsForIngredient[ing.id!] ?? [];
      if (availableItems.isEmpty) continue;

      // Sort items by expiration date (soonest first)
      availableItems.sort((a, b) {
        if (a.haltbarBis == null && b.haltbarBis == null) return 0;
        if (a.haltbarBis == null) return 1;
        if (b.haltbarBis == null) return -1;
        return a.haltbarBis!.compareTo(b.haltbarBis!);
      });

      double remainingAmountNeeded = ing.menge;
      final targetUnit = ing.einheit;
      Map<int, double> planForIng = {};

      for (var item in availableItems) {
        if (remainingAmountNeeded <= 0) break;
        if (item.id == null) continue;

        // Simplified unit matching for auto-fill
        double itemAmountInTargetUnit = item.menge;
        if (item.einheit == 'g' && targetUnit == 'kg') {
          itemAmountInTargetUnit /= 1000;
        } else if (item.einheit == 'kg' && targetUnit == 'g') {
          itemAmountInTargetUnit *= 1000;
        } else if (item.einheit == 'ml' && targetUnit == 'l') {
          itemAmountInTargetUnit /= 1000;
        } else if (item.einheit == 'l' && targetUnit == 'ml') {
          itemAmountInTargetUnit *= 1000;
        }
        // If units are completely different, fallback to 1:1

        if (itemAmountInTargetUnit > 0) {
          final toConsumeInTargetUnit = itemAmountInTargetUnit >= remainingAmountNeeded
              ? remainingAmountNeeded
              : itemAmountInTargetUnit;

          // Convert back to item's unit for consumption
          double toConsumeInItemUnit = toConsumeInTargetUnit;
          if (item.einheit == 'g' && targetUnit == 'kg') {
            toConsumeInItemUnit *= 1000;
          } else if (item.einheit == 'kg' && targetUnit == 'g') {
            toConsumeInItemUnit /= 1000;
          } else if (item.einheit == 'ml' && targetUnit == 'l') {
            toConsumeInItemUnit *= 1000;
          } else if (item.einheit == 'l' && targetUnit == 'ml') {
            toConsumeInItemUnit /= 1000;
          }

          planForIng[item.id!] = toConsumeInItemUnit;
          remainingAmountNeeded -= toConsumeInTargetUnit;
        }
      }

      _consumptionPlan[ing.id!] = planForIng;
    }
  }

  String _formatTotal(double total) {
    if (total == total.toInt()) return total.toInt().toString();
    return total.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  Future<void> _executeCooking() async {
    setState(() => _isCooking = true);

    try {
      for (var plan in _consumptionPlan.values) {
        for (var entry in plan.entries) {
          final itemId = entry.key;
          final amountToConsume = entry.value;
          if (amountToConsume > 0) {
            await widget.kitchenService.consumeItem(itemId, amountToConsume);
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zutaten wurden aus dem Vorrat verbraucht. Guten Appetit!')),
        );
        widget.onCooked();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Verbrauchen: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Zutaten verbrauchen',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const Text(
            'Die App hat automatisch die Zutaten mit dem kürzesten MHD ausgewählt. Du kannst die Mengen anpassen oder Zutaten abwählen.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: widget.cookability.ingredients.length,
              itemBuilder: (context, index) {
                final ing = widget.cookability.ingredients[index];
                if (ing.id == null) return const SizedBox();

                final availableItems = widget.cookability.availableItemsForIngredient[ing.id!] ?? [];
                final planForIng = _consumptionPlan[ing.id!] ?? {};

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${ing.basisProdukt} (${_formatTotal(ing.menge)} ${ing.einheit})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (availableItems.isEmpty)
                              const Text('Fehlt im Vorrat', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        if (availableItems.isNotEmpty) const SizedBox(height: 8),
                        ...availableItems.map((item) {
                          if (item.id == null) return const SizedBox();
                          final plannedAmount = planForIng[item.id!] ?? 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: plannedAmount > 0,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        // Simplified fallback to full amount of item if checked
                                        _consumptionPlan[ing.id!]![item.id!] = item.menge;
                                      } else {
                                        _consumptionPlan[ing.id!]![item.id!] = 0.0;
                                      }
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${item.name} (${_formatTotal(item.menge)} ${item.einheit})'),
                                      if (item.haltbarBis != null)
                                        Text('MHD: ${item.haltbarBis!.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    initialValue: _formatTotal(plannedAmount),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      suffixText: item.einheit,
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (val) {
                                      final newAmount = double.tryParse(val.replaceAll(',', '.')) ?? 0;
                                      setState(() {
                                        _consumptionPlan[ing.id!]![item.id!] = newAmount;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _isCooking ? null : _executeCooking,
              child: _isCooking
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Kochen & Zutaten abziehen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

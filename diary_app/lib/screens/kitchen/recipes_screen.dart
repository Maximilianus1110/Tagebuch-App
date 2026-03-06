import 'package:flutter/material.dart';
import 'package:diary_app/services/recipe_service.dart';
import 'package:diary_app/screens/kitchen/add_recipe_screen.dart';
import 'package:diary_app/screens/kitchen/recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final RecipeService _recipeService = RecipeService();
  bool _isLoading = true;
  List<RecipeCookability> _recipes = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    final recipes = await _recipeService.getRecipesSortedByCookability();
    if (mounted) {
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    }
  }

  List<RecipeCookability> get _filteredRecipes {
    if (_searchQuery.isEmpty) return _recipes;
    return _recipes.where((r) => r.recipe.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  String _getCookabilityText(int missingCount, int totalIngredients) {
    if (missingCount == 0) return '100% Kochbar';
    if (missingCount == totalIngredients) return 'Zutaten fehlen komplett';
    return 'Es fehlen $missingCount Zutat${missingCount == 1 ? '' : 'en'}';
  }

  Color _getCookabilityColor(int missingCount, int totalIngredients) {
    if (missingCount == 0) return Colors.green;
    if (missingCount <= totalIngredients / 2) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRecipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezepte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
              );
              if (result == true) {
                _loadRecipes();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rezept suchen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _recipes.isEmpty
                    ? const Center(child: Text('Keine Rezepte gefunden. Erstelle dein erstes Rezept!'))
                    : filtered.isEmpty
                        ? const Center(child: Text('Keine Ergebnisse für deine Suche.'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final cookability = filtered[index];
                              final recipe = cookability.recipe;
                              final missingCount = cookability.missingIngredientsCount;
                              final totalIngredients = cookability.ingredients.length;
                              final color = _getCookabilityColor(missingCount, totalIngredients);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12.0),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RecipeDetailScreen(cookability: cookability),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadRecipes();
                                    }
                                  },
                                  leading: CircleAvatar(
                                    backgroundColor: color.withValues(alpha: 0.2),
                                    child: Icon(
                                      missingCount == 0 ? Icons.check_circle : Icons.fastfood,
                                      color: color,
                                    ),
                                  ),
                                  title: Text(
                                    recipe.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (recipe.prepTimeMinutes != null)
                                        Text('${recipe.prepTimeMinutes} Min. Zubereitungszeit'),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getCookabilityText(missingCount, totalIngredients),
                                        style: TextStyle(color: color, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

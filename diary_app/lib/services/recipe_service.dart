import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/kitchen/kitchen_item.dart';
import 'package:diary_app/models/kitchen/recipe.dart';
import 'package:diary_app/models/kitchen/recipe_ingredient.dart';
import 'package:diary_app/services/kitchen_service.dart';

class RecipeCookability {
  final Recipe recipe;
  final List<RecipeIngredient> ingredients;
  final int missingIngredientsCount;
  final Map<int, List<KitchenItem>> availableItemsForIngredient;

  RecipeCookability({
    required this.recipe,
    required this.ingredients,
    required this.missingIngredientsCount,
    required this.availableItemsForIngredient,
  });
}

class RecipeService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final KitchenService _kitchenService = KitchenService();

  Future<Recipe> createRecipe(Recipe recipe, List<RecipeIngredient> ingredients) async {
    return await _dbHelper.createRecipe(recipe, ingredients);
  }

  Future<int> updateRecipe(Recipe recipe, List<RecipeIngredient> ingredients) async {
    return await _dbHelper.updateRecipe(recipe, ingredients);
  }

  Future<int> deleteRecipe(int id) async {
    return await _dbHelper.deleteRecipe(id);
  }

  Future<List<Recipe>> getAllRecipes() async {
    return await _dbHelper.getAllRecipes();
  }

  Future<List<RecipeIngredient>> getIngredientsForRecipe(int recipeId) async {
    return await _dbHelper.getIngredientsForRecipe(recipeId);
  }

  // Gets recipes and sorts them by cookability (least missing ingredients first)
  Future<List<RecipeCookability>> getRecipesSortedByCookability() async {
    final recipes = await getAllRecipes();
    final allKitchenItems = await _kitchenService.getAllItems();

    // Also need tags to match ingredients by tag
    // For performance, we pre-fetch tags for all items
    Map<int, List<String>> itemTagsMap = {};
    for (var item in allKitchenItems) {
      if (item.id != null) {
        final tags = await _kitchenService.getTagsForItem(item.id!);
        itemTagsMap[item.id!] = tags.map((t) => t.name.toLowerCase()).toList();
      }
    }

    List<RecipeCookability> cookabilityList = [];

    for (var recipe in recipes) {
      if (recipe.id == null) continue;

      final ingredients = await getIngredientsForRecipe(recipe.id!);
      int missingCount = 0;
      Map<int, List<KitchenItem>> availableItemsMap = {};

      for (var ingredient in ingredients) {
        if (ingredient.id == null) continue;

        final reqName = ingredient.basisProdukt.toLowerCase();
        final reqAmount = ingredient.menge;

        // Find matching kitchen items (by basisProdukt or tag)
        List<KitchenItem> matchingItems = allKitchenItems.where((item) {
          final isBasisMatch = item.basisProdukt.toLowerCase() == reqName;
          final isTagMatch = item.id != null && itemTagsMap[item.id!]!.contains(reqName);
          return isBasisMatch || isTagMatch;
        }).toList();

        // Calculate total available amount of matching items
        // Note: this assumes units match or can be easily converted.
        // For simplicity, we just sum up items that match the name.
        // In a more complex app, we'd convert units (e.g. kg to g)
        double totalAvailable = 0;
        for (var item in matchingItems) {
            // Very basic unit matching/conversion
            if (item.einheit == ingredient.einheit) {
                totalAvailable += item.menge;
            } else if ((item.einheit == 'g' && ingredient.einheit == 'kg') || (item.einheit == 'ml' && ingredient.einheit == 'l')) {
                totalAvailable += item.menge / 1000;
            } else if ((item.einheit == 'kg' && ingredient.einheit == 'g') || (item.einheit == 'l' && ingredient.einheit == 'ml')) {
                totalAvailable += item.menge * 1000;
            } else {
                // If units completely differ (e.g., 'Stück' vs 'g'), we still add it but it might be inaccurate
                totalAvailable += item.menge;
            }
        }

        if (totalAvailable < reqAmount) {
          missingCount++;
        }

        availableItemsMap[ingredient.id!] = matchingItems;
      }

      cookabilityList.add(RecipeCookability(
        recipe: recipe,
        ingredients: ingredients,
        missingIngredientsCount: missingCount,
        availableItemsForIngredient: availableItemsMap,
      ));
    }

    // Sort: 0 missing first, then 1 missing, etc. If tie, sort by name
    cookabilityList.sort((a, b) {
      int cmp = a.missingIngredientsCount.compareTo(b.missingIngredientsCount);
      if (cmp != 0) return cmp;
      return a.recipe.name.compareTo(b.recipe.name);
    });

    return cookabilityList;
  }
}

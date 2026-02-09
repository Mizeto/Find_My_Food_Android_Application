// Simple ingredient item for display in Recipe detail
class RecipeIngredientItem {
  final int ingredientId;
  final String ingredientName;
  final double quantity;
  final int unitId;
  final String unitName;

  RecipeIngredientItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    required this.unitId,
    required this.unitName,
  });
}

class Recipe {
  final int id;
  final String title;
  final String description;
  final String cookingMethod;
  final String imageUrl;
  final int prepTime;
  final List<RecipeIngredientItem>? ingredients; // เพิ่ม ingredients

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.cookingMethod,
    required this.imageUrl,
    required this.prepTime,
    this.ingredients, // optional
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['recipe_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      cookingMethod: json['cooking_method'] ?? 'ไม่มีข้อมูลวิธีทำ',
      imageUrl: _fixImageUrl(
        json['image_url'] ?? 'https://placehold.co/600x400.png',
      ),
      prepTime: json['prep_time'] ?? 0,
      ingredients: null, // fromJson is for simple cases, use repository for full detail
    );
  }

  static String _fixImageUrl(String url) {
    if (url.contains('placehold.co') && !url.contains('.png')) {
      return url.replaceFirst('?', '.png?');
    }
    return url;
  }
}


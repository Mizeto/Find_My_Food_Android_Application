// Simple ingredient item for display in Recipe detail
class RecipeIngredientItem {
  final int ingredientId;
  final String ingredientName;
  final double quantity;
  final int unitId;
  final String unitName;
  final bool isMainIngredient;

  RecipeIngredientItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    required this.unitId,
    required this.unitName,
    this.isMainIngredient = false,
  });
}

class Recipe {
  final int id;
  final String title;
  final String description;
  final String cookingMethod;
  final String imageUrl;
  final int prepTime;
  final int likeCount; // Add likeCount
  final bool isLiked; // Add this
  final List<String>? tags;
  final List<RecipeIngredientItem>? ingredients;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.cookingMethod,
    required this.imageUrl,
    required this.prepTime,
    this.likeCount = 0, // default 0
    this.isLiked = false,
    this.tags,
    this.ingredients, // optional
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // Safe tags parsing
    List<String> parsedTags = [];
    try {
      if (json['tags'] != null && json['tags'] is List) {
        parsedTags = (json['tags'] as List).map((t) => t.toString()).toList();
      }
    } catch (_) {}

    return Recipe(
      id: json['recipe_id'] ?? 0,
      title: json['title']?.toString() ?? json['recipe_name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      cookingMethod: json['cooking_method']?.toString() ?? 'ไม่มีข้อมูลวิธีทำ',
      imageUrl: _fixImageUrl(
        json['image_url']?.toString() ?? 'https://placehold.co/600x400.png',
      ),
      prepTime: (json['prep_time'] as num?)?.toInt() ?? (json['cooking_time_min'] as num?)?.toInt() ?? 0,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0, 
      isLiked: json['is_liked'] == true || json['is_liked'] == 1 || json['is_liked'] == "true",
      tags: parsedTags,
      ingredients: null,
    );
  }

  static String _fixImageUrl(String url) {
    if (url.contains('placehold.co') && !url.contains('.png')) {
      return url.replaceFirst('?', '.png?');
    }
    return url;
  }
}


class RecipeCategory {
  final int categoryId;
  final String categoryName;

  RecipeCategory({
    required this.categoryId,
    required this.categoryName,
  });

  factory RecipeCategory.fromJson(Map<String, dynamic> json) {
    return RecipeCategory(
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
    );
  }
}

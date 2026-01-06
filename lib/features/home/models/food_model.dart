class FoodModel {
  final int foodId;
  final String name;
  final String imageUrl;

  FoodModel({
    required this.foodId,
    required this.name,
    required this.imageUrl,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      foodId: json['food_id'] as int,
      name: json['food'] as String,
      imageUrl: json['image_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_id': foodId,
      'food': name,
      'image_url': imageUrl,
    };
  }
}

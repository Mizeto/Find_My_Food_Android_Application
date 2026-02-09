import 'food_model.dart';

class ShoppingListModel {
  final int shoppingListId;
  final String listName;
  final String shoppingType; // "recipe" or "market"
  final List<ShoppingItemModel> items;

  ShoppingListModel({
    required this.shoppingListId,
    required this.listName,
    required this.shoppingType,
    required this.items,
  });

  factory ShoppingListModel.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List?;
    return ShoppingListModel(
      shoppingListId: json['shopping_list_id'] as int? ?? 0,
      listName: json['list_name'] as String? ?? 'รายการซื้อของ',
      shoppingType: json['shopping_type'] as String? ?? 'market',
      items: itemsList?.map((i) => ShoppingItemModel.fromJson(i)).toList() ?? [],
    );
  }
}

class ShoppingItemModel {
  final int itemId;
  final String itemName;
  final double quantity;
  final int unitId;
  final String? unitName; // Optional, might come from API join
  final String? note;
  final bool isCheck;

  ShoppingItemModel({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitId,
    this.unitName,
    this.note,
    required this.isCheck,
  });

  factory ShoppingItemModel.fromJson(Map<String, dynamic> json) {
    return ShoppingItemModel(
      // Fix: Map 'shopping_item_id' from API/DB to itemId. 
      // Fallback to 'item_id' just in case, but DB shows 'shopping_item_id'.
      itemId: (json['shopping_item_id'] ?? json['item_id']) as int? ?? 0,
      itemName: json['item_name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitId: json['unit_id'] as int? ?? 0,
      unitName: json['unit_name'] as String?,
      note: json['note'] as String?,
      isCheck: json['is_check'] as bool? ?? false,
    );
  }
}


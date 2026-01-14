part of 'scan_food_cubit.dart';

abstract class ScanFoodState extends Equatable {
  const ScanFoodState();

  @override
  List<Object?> get props => [];
}

class ScanFoodInitial extends ScanFoodState {}

class ScanFoodLoading extends ScanFoodState {}

class ScanFoodSuccess extends ScanFoodState {
  final List<String> ingredients;
  final DishAIResponse? dishResponse;

  const ScanFoodSuccess({this.ingredients = const [], this.dishResponse});

  @override
  List<Object?> get props => [ingredients, dishResponse];
}

class ScanFoodError extends ScanFoodState {
  final String message;

  const ScanFoodError(this.message);

  @override
  List<Object?> get props => [message];
}

part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Recipe> recipes;
  final List<Recipe> recommendedForYou;
  final List<Recipe> recommendedFromStock;
  final List<Map<String, dynamic>> categories;
  final int? selectedCategoryId;
  final List<int> selectedFilterCategoryIds;
  final List<int> selectedFilterTagIds;
  final String searchQuery;

  HomeLoaded({
    required this.recipes,
    this.recommendedForYou = const [],
    this.recommendedFromStock = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.selectedFilterCategoryIds = const [],
    this.selectedFilterTagIds = const [],
    this.searchQuery = '',
  });

  @override
  List<Object> get props => [
    recipes, 
    recommendedForYou, 
    recommendedFromStock, 
    categories, 
    selectedCategoryId ?? -1,
    selectedFilterCategoryIds,
    selectedFilterTagIds,
    searchQuery,
  ];

  HomeLoaded copyWith({
    List<Recipe>? recipes,
    List<Recipe>? recommendedForYou,
    List<Recipe>? recommendedFromStock,
    List<Map<String, dynamic>>? categories,
    int? Function()? selectedCategoryId,
    List<int>? selectedFilterCategoryIds,
    List<int>? selectedFilterTagIds,
    String? searchQuery,
  }) {
    return HomeLoaded(
      recipes: recipes ?? this.recipes,
      recommendedForYou: recommendedForYou ?? this.recommendedForYou,
      recommendedFromStock: recommendedFromStock ?? this.recommendedFromStock,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId != null 
          ? selectedCategoryId() 
          : this.selectedCategoryId,
      selectedFilterCategoryIds: selectedFilterCategoryIds ?? this.selectedFilterCategoryIds,
      selectedFilterTagIds: selectedFilterTagIds ?? this.selectedFilterTagIds,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class HomeError extends HomeState {
  final String message;

  HomeError(this.message);

  @override
  List<Object> get props => [message];
}

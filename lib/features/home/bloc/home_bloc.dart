import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart'; // ✅ 1. ต้องเพิ่มอันนี้ (เพื่อให้ลูกใช้)
import '../../../data/models/recipe_model.dart'; // ✅ 2. ต้องเพิ่มอันนี้ (เพื่อให้ลูกรู้จัก Recipe)
import '../../../data/repositories/recipe_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final RecipeRepository repository;

  HomeBloc({required this.repository}) : super(HomeInitial()) {
    // Event เดิม: โหลดทั้งหมด
    on<LoadHomeRecipes>((event, emit) async {
      emit(HomeLoading());
      try {
        // Fetch categories separately to avoid type casting issues with Future.wait
        final categories = await repository.getCategories();
        
        if (event.isGuest) {
          final recipes = await repository.getRecipes();
          emit(HomeLoaded(
            recipes: recipes,
            categories: categories,
          ));
        } else {
          final results = await Future.wait([
            repository.getRecipes(),
            repository.getRecommendForYou(),
            repository.getRecommendFromStock(),
          ]);

          emit(HomeLoaded(
            recipes: results[0] as List<Recipe>,
            recommendedForYou: results[1] as List<Recipe>,
            recommendedFromStock: results[2] as List<Recipe>,
            categories: categories,
          ));
        }
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });

    // Event ใหม่: ค้นหาตามคำที่พิมพ์
    on<SearchRecipes>((event, emit) async {
      final currentState = state;
      final prevCategories = currentState is HomeLoaded ? currentState.categories : const <Map<String, dynamic>>[];
      final prevRecommendedForYou = currentState is HomeLoaded ? currentState.recommendedForYou : const <Recipe>[];
      final prevRecommendedFromStock = currentState is HomeLoaded ? currentState.recommendedFromStock : const <Recipe>[];
      final prevFilterCatIds = currentState is HomeLoaded ? currentState.selectedFilterCategoryIds : const <int>[];
      final prevFilterTagIds = currentState is HomeLoaded ? currentState.selectedFilterTagIds : const <int>[];

      emit(HomeLoading());
      try {
        List<Recipe> recipes = await repository.getRecipes(search: event.query);
        
        // Local filtering if filters are active
        if (prevFilterCatIds.isNotEmpty || prevFilterTagIds.isNotEmpty) {
          recipes = recipes.where((recipe) {
            // Check category match
            bool categoryMatch = prevFilterCatIds.isEmpty || 
                (recipe.tags != null && recipe.tags!.any((t) {
                  // Fallback string matching or rely on tags matching ids if id maps nicely.
                  // Since Recipe model only has List<String> for tags, local filtering is best-effort
                  // based on whether the string tag is in the selected categories.
                  // For robust filtering, we would need Category IDs on the Recipe model.
                  // But we will do a best effort: if we don't have enough data, we won't strictly filter category.
                  return true; 
                }));
            
            // Check tag match
            bool tagMatch = prevFilterTagIds.isEmpty || 
                (recipe.tags != null && recipe.tags!.isNotEmpty); // Best effort placeholder
            
            return categoryMatch && tagMatch;
          }).toList();
        }

        emit(HomeLoaded(
          recipes: recipes,
          categories: prevCategories,
          recommendedForYou: prevRecommendedForYou,
          recommendedFromStock: prevRecommendedFromStock,
          selectedFilterCategoryIds: prevFilterCatIds,
          selectedFilterTagIds: prevFilterTagIds,
        ));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });

    // Event: โหลดหมวดหมู่
    on<LoadCategories>((event, emit) async {
      try {
        final categories = await repository.getCategories();
        if (state is HomeLoaded) {
          emit((state as HomeLoaded).copyWith(categories: categories));
        }
      } catch (e) {
        // Silently fail - categories are not critical
      }
    });

    // Event: เลือกหมวดหมู่
    on<SelectCategory>((event, emit) async {
      final currentState = state;
      if (currentState is! HomeLoaded) return;

      // Preserve categories when switching
      final categories = currentState.categories;

      emit(HomeLoading());
      try {
        List<Recipe> recipes;
        if (event.categoryId == null) {
          // "ทั้งหมด" - load all recipes
          recipes = await repository.getRecipes();
        } else {
          recipes = await repository.getRecipesByCategory(event.categoryId!);
        }

        emit(HomeLoaded(
          recipes: recipes,
          recommendedForYou: currentState.recommendedForYou,
          recommendedFromStock: currentState.recommendedFromStock,
          categories: categories,
          selectedCategoryId: event.categoryId,
        ));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });

    // Event: ค้นหาตามฟิลเตอร์ (Categories + Tags)
    on<FilterSearchRecipes>((event, emit) async {
      final currentState = state;
      final prevCategories = currentState is HomeLoaded ? currentState.categories : const <Map<String, dynamic>>[];
      final prevRecommendedForYou = currentState is HomeLoaded ? currentState.recommendedForYou : const <Recipe>[];
      final prevRecommendedFromStock = currentState is HomeLoaded ? currentState.recommendedFromStock : const <Recipe>[];

      emit(HomeLoading());
      try {
        final recipes = await repository.searchWithFilter(
          categoryIds: event.categoryIds,
          tagIds: event.tagIds,
        );
        emit(HomeLoaded(
          recipes: recipes,
          categories: prevCategories,
          recommendedForYou: prevRecommendedForYou,
          recommendedFromStock: prevRecommendedFromStock,
          selectedFilterCategoryIds: event.categoryIds,
          selectedFilterTagIds: event.tagIds,
        ));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });
  }
}

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
      emit(HomeLoading()); // หมุนติ้วๆ
      try {
        final recipes = await repository.getRecipes(search: event.query);
        emit(HomeLoaded(recipes: recipes));
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
      emit(HomeLoading());
      try {
        final recipes = await repository.searchWithFilter(
          categoryIds: event.categoryIds,
          tagIds: event.tagIds,
        );
        emit(HomeLoaded(recipes: recipes));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });
  }
}

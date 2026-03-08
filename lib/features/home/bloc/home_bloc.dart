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
        if (event.isGuest) {
          // Guest: only load main recipes, skip recommendations
          final recipes = await repository.getRecipes();
          emit(HomeLoaded(recipes: recipes));
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
        // เมื่อค้นหา เราจะแสดงเฉพาะผลการค้นหา (หรืออาจจะเก็บ Recommend ไว้ก็ได้ แต่ในที่นี้ขอแสดงเฉพาะผลค้นหาเพื่อความเคลียร์)
        final recipes = await repository.getRecipes(search: event.query);
        emit(HomeLoaded(recipes: recipes));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });
  }
}

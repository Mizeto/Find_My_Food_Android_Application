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
        final recipes = await repository.getRecipes();
        emit(HomeLoaded(recipes));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });

    // Event ใหม่: ค้นหาตามคำที่พิมพ์
    on<SearchRecipes>((event, emit) async {
      emit(HomeLoading()); // หมุนติ้วๆ
      try {
        // ส่งคำค้นหา (event.query) ไปให้ Repository
        final recipes = await repository.getRecipes(search: event.query);
        emit(HomeLoaded(recipes));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });
  }
}

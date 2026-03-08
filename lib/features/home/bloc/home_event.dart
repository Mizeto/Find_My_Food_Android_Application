part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  @override
  List<Object> get props => [];
}

// คำสั่ง: "ช่วยไปโหลดเมนูอาหารมาให้หน่อย"
class LoadHomeRecipes extends HomeEvent {
  final bool isGuest;
  LoadHomeRecipes({this.isGuest = false});

  @override
  List<Object> get props => [isGuest];
}

// คำสั่ง: "ช่วยค้นหาตามคำนี้ให้หน่อย"
class SearchRecipes extends HomeEvent {
  final String query;
  SearchRecipes(this.query);

  // เพิ่ม props เพื่อให้ Equatable รู้ว่าถ้าค้นหาคำเดิม ไม่ต้องทำซ้ำ (Optional แต่นิยมทำ)
  @override
  List<Object> get props => [query];
}

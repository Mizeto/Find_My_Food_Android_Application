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

  HomeLoaded({
    required this.recipes,
    this.recommendedForYou = const [],
    this.recommendedFromStock = const [],
  });

  @override
  List<Object> get props => [recipes, recommendedForYou, recommendedFromStock];
}

class HomeError extends HomeState {
  final String message;

  HomeError(this.message);

  @override
  List<Object> get props => [message];
}

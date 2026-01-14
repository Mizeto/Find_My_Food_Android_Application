import 'package:equatable/equatable.dart';

enum LoginType { email, guest }

class UserModel extends Equatable {
  final int id; // Changed to int to match SERIAL in DB
  final String username;
  final String email;
  final String? profileImage;
  final LoginType loginType;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage,
    required this.loginType,
  });

  bool get isGuest => loginType == LoginType.guest;

  // From JSON (SharedPreferences / API)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      username: json['username'] ?? 'User',
      email: json['email'] ?? '',
      profileImage: json['profile_image'],
      loginType: json['loginType'] != null
          ? LoginType.values.firstWhere(
              (e) => e.name == json['loginType'],
              orElse: () => LoginType.email,
            )
          : LoginType.email,
    );
  }

  // To JSON (SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'username': username,
      'email': email,
      'profile_image': profileImage,
      'loginType': loginType.name,
    };
  }

  // Guest user factory
  factory UserModel.guest() {
    return UserModel(
      id: -1,
      username: 'ผู้เยี่ยมชม',
      email: '',
      loginType: LoginType.guest,
    );
  }

  // Copy with
  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? profileImage,
    LoginType? loginType,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      loginType: loginType ?? this.loginType,
    );
  }

  @override
  List<Object?> get props => [id, username, email, profileImage, loginType];
}

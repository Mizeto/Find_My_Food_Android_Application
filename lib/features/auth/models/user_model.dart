import 'package:equatable/equatable.dart';

enum LoginType { email, guest }

class UserModel extends Equatable {
  final int id; // Changed to int to match SERIAL in DB
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final DateTime? birthDate;
  final String? profileImage;
  final LoginType loginType;
  final String? guestUuid; // UUID4 for guest identification

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.gender,
    this.birthDate,
    this.profileImage,
    required this.loginType,
    this.guestUuid,
  });

  bool get isGuest => loginType == LoginType.guest;

  // From JSON (SharedPreferences / API)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? rawImage = json['profile_image'] ?? json['image_url'];
    
    // Normalize image URL
    String? normalizedImage;
    if (rawImage != null && rawImage.isNotEmpty) {
      if (rawImage.startsWith('http')) {
        normalizedImage = rawImage;
      } else {
        // Assume relative path from backend
        // Make sure it doesn't have double slashes
        String cleanPath = rawImage.startsWith('/') ? rawImage.substring(1) : rawImage;
        normalizedImage = 'http://43.229.132.119/$cleanPath';
      }
    }

    return UserModel(
      id: int.tryParse(json['user_id'].toString()) ?? 0,
      username: json['username'] ?? 'User',
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      gender: json['gender'],
      birthDate: json['birth_date'] != null ? DateTime.tryParse(json['birth_date']) : null,
      profileImage: normalizedImage,
      loginType: json['loginType'] != null
          ? LoginType.values.firstWhere(
              (e) => e.name == json['loginType'],
              orElse: () => LoginType.email,
            )
          : LoginType.email,
      guestUuid: json['guest_uuid'],
    );
  }

  // To JSON (SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'birth_date': birthDate?.toIso8601String().split('T')[0],
      'profile_image': profileImage,
      'loginType': loginType.name,
      'guest_uuid': guestUuid,
    };
  }

  // Guest user factory
  factory UserModel.guest({required String uuid}) {
    return UserModel(
      id: -1,
      username: 'ผู้เยี่ยมชม',
      email: '',
      loginType: LoginType.guest,
      guestUuid: uuid,
    );
  }

  // Copy with
  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? gender,
    DateTime? birthDate,
    String? profileImage,
    LoginType? loginType,
    String? guestUuid,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      profileImage: profileImage ?? this.profileImage,
      loginType: loginType ?? this.loginType,
      guestUuid: guestUuid ?? this.guestUuid,
    );
  }

  @override
  List<Object?> get props => [id, username, email, firstName, lastName, gender, birthDate, profileImage, loginType, guestUuid];
}

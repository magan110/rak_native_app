import '../../domain/entities/user.dart';

/// User model
/// Data layer - handles serialization/deserialization
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.profileImage,
  });
  
  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      profileImage: json['profile_image'] as String?,
    );
  }
  
  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profile_image': profileImage,
    };
  }
  
  /// Convert to entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      name: name,
      profileImage: profileImage,
    );
  }
}

import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// 用户模型
@JsonSerializable()
class UserModel {
  final String id;
  final String? phone;
  final String? name;
  final String? avatar;
  final String? gender;
  final int? age;

  UserModel({
    required this.id,
    this.phone,
    this.name,
    this.avatar,
    this.gender,
    this.age,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

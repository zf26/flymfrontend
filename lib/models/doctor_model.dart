import 'package:json_annotation/json_annotation.dart';

part 'doctor_model.g.dart';

/// 医生模型
@JsonSerializable()
class DoctorModel {
  final String id;
  final String name;
  final String? avatar;
  final String? title; // 职称
  final String? department; // 科室
  final String? hospital; // 医院
  final String? introduction; // 简介
  final double? rating; // 评分
  final int? consultationCount; // 问诊次数
  final List<String>? specialties; // 专长

  DoctorModel({
    required this.id,
    required this.name,
    this.avatar,
    this.title,
    this.department,
    this.hospital,
    this.introduction,
    this.rating,
    this.consultationCount,
    this.specialties,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) =>
      _$DoctorModelFromJson(json);

  Map<String, dynamic> toJson() => _$DoctorModelToJson(this);
}

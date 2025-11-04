import 'package:json_annotation/json_annotation.dart';

part 'consultation_model.g.dart';

/// 问诊模型
@JsonSerializable()
class ConsultationModel {
  final String id;
  final String doctorId;
  final String? doctorName;
  final String? doctorAvatar;
  final String? description;
  final String status;
  final DateTime createTime;
  final DateTime? updateTime;
  final List<String>? images;

  ConsultationModel({
    required this.id,
    required this.doctorId,
    this.doctorName,
    this.doctorAvatar,
    this.description,
    required this.status,
    required this.createTime,
    this.updateTime,
    this.images,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) =>
      _$ConsultationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConsultationModelToJson(this);
}

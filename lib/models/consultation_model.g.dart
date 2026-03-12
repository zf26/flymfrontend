// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consultation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConsultationModel _$ConsultationModelFromJson(
  Map<String, dynamic> json,
) => ConsultationModel(
  id: json['id'] as String,
  userId: json['userId'] as String,
  userName: json['userName'] as String?,
  doctorId: json['doctorId'] as String,
  doctorName: json['doctorName'] as String?,
  doctorAvatar: json['doctorAvatar'] as String?,
  description: json['description'] as String?,
  status: json['status'] as String,
  createTime: DateTime.parse(json['createTime'] as String),
  updateTime:
      json['updateTime'] == null
          ? null
          : DateTime.parse(json['updateTime'] as String),
  images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
  consultationType: json['consultationType'] as String? ?? '初诊',
  department: json['department'] as String?,
  consultationMethod: json['consultationMethod'] as String? ?? '文字',
  isAnonymous: json['isAnonymous'] as bool? ?? false,
  priceBudget: json['priceBudget'] as String?,
  urgencyLevel: json['urgencyLevel'] as String? ?? '普通',
  symptoms:
      (json['symptoms'] as List<dynamic>?)?.map((e) => e as String).toList(),
  agreeToTerms: json['agreeToTerms'] as bool? ?? false,
);

Map<String, dynamic> _$ConsultationModelToJson(ConsultationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'userName': instance.userName,
      'doctorId': instance.doctorId,
      'doctorName': instance.doctorName,
      'doctorAvatar': instance.doctorAvatar,
      'description': instance.description,
      'status': instance.status,
      'createTime': instance.createTime.toIso8601String(),
      'updateTime': instance.updateTime?.toIso8601String(),
      'images': instance.images,
      'consultationType': instance.consultationType,
      'department': instance.department,
      'consultationMethod': instance.consultationMethod,
      'isAnonymous': instance.isAnonymous,
      'priceBudget': instance.priceBudget,
      'urgencyLevel': instance.urgencyLevel,
      'symptoms': instance.symptoms,
      'agreeToTerms': instance.agreeToTerms,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consultation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConsultationModel _$ConsultationModelFromJson(Map<String, dynamic> json) =>
    ConsultationModel(
      id: json['id'] as String,
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
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ConsultationModelToJson(ConsultationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'doctorId': instance.doctorId,
      'doctorName': instance.doctorName,
      'doctorAvatar': instance.doctorAvatar,
      'description': instance.description,
      'status': instance.status,
      'createTime': instance.createTime.toIso8601String(),
      'updateTime': instance.updateTime?.toIso8601String(),
      'images': instance.images,
    };

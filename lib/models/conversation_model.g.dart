// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationModel _$ConversationModelFromJson(Map<String, dynamic> json) =>
    ConversationModel(
      id: (json['id'] as num?)?.toInt(),
      roomId: json['roomId'] as String?,
      conversationType: json['conversationType'] as String?,
      userIdA: (json['userIdA'] as num?)?.toInt(),
      userIdB: (json['userIdB'] as num?)?.toInt(),
      status: (json['status'] as num?)?.toInt(),
      remark: json['remark'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );

Map<String, dynamic> _$ConversationModelToJson(ConversationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'roomId': instance.roomId,
      'conversationType': instance.conversationType,
      'userIdA': instance.userIdA,
      'userIdB': instance.userIdB,
      'status': instance.status,
      'remark': instance.remark,
      'createTime': instance.createTime,
      'updateTime': instance.updateTime,
    };

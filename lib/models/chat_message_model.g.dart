// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessageModel _$ChatMessageModelFromJson(Map<String, dynamic> json) =>
    ChatMessageModel(
      id: json['id'] as String?,
      type: json['type'] as String? ?? 'CHAT',
      fromUserId: json['fromUserId']?.toString(),
      toUserId: json['toUserId']?.toString(),
      roomId: json['roomId'] as String?,
      content: json['content'] as String,
      timestamp: (json['timestamp'] as num?)?.toInt(),
      extra: ChatMessageModel._decodeExtra(json['extra']),
    );

Map<String, dynamic> _$ChatMessageModelToJson(ChatMessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'fromUserId': instance.fromUserId,
      'toUserId': instance.toUserId,
      'roomId': instance.roomId,
      'content': instance.content,
      'timestamp': instance.timestamp,
      'extra': ChatMessageModel._encodeExtra(instance.extra),
    };

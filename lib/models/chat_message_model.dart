import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'chat_message_model.g.dart';

/// 聊天消息模型（与后端 `ChatMessage` 对齐）
@JsonSerializable()
class ChatMessageModel {
  /// 消息ID（后端生成）
  final String? id;

  /// 消息类型，如：CHAT、NOTICE 等
  final String type;

  /// 发送者ID，由后端根据会话自动填充
  final String? fromUserId;

  /// 接收者ID，私聊必填
  final String? toUserId;

  /// 房间 / 会话ID，群聊或房间广播时必填
  final String? roomId;

  /// 消息内容，纯文本或 JSON 字符串
  final String content;

  /// 时间戳（毫秒）
  final int? timestamp;

  /// 扩展字段（JSON）会在序列化时转换成字符串
  @JsonKey(fromJson: _decodeExtra, toJson: _encodeExtra)
  final Map<String, dynamic>? extra;

  const ChatMessageModel({
    this.id,
    this.type = 'CHAT',
    this.fromUserId,
    this.toUserId,
    this.roomId,
    required this.content,
    this.timestamp,
    this.extra,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageModelToJson(this);

  /// 创建时间
  DateTime? get createdAt {
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp!);
  }

  /// 是否来自当前用户（与后端会话保持一致）
  bool isFromCurrentUser(String currentUserId) {
    return fromUserId == currentUserId;
  }

  static Map<String, dynamic>? _decodeExtra(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        return decoded is Map<String, dynamic> ? decoded : {'raw': decoded};
      } catch (_) {
        return {'raw': value};
      }
    }
    return null;
  }

  static String? _encodeExtra(Map<String, dynamic>? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }
}

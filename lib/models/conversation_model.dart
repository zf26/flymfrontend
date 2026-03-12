import 'package:json_annotation/json_annotation.dart';

part 'conversation_model.g.dart';

/// 会话模型（与后端 ImConversation 对齐）
@JsonSerializable()
class ConversationModel {
  /// 会话ID
  final int? id;

  /// 房间/会话ID
  final String? roomId;

  /// 会话类型（PRIVATE: 私聊, GROUP: 群聊）
  final String? conversationType;

  /// 用户A的ID
  final int? userIdA;

  /// 用户B的ID
  final int? userIdB;

  /// 会话状态（0: 正常, 1: 已关闭）
  final int? status;

  /// 备注信息
  final String? remark;

  /// 创建时间
  final String? createTime;

  /// 更新时间
  final String? updateTime;

  /// 对方用户信息（扩展字段，由前端或后端填充）
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? otherUserName;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? otherUserAvatar;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? otherUserRole;

  /// 最后一条消息（扩展字段）
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? lastMessage;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? lastMessageTime;

  @JsonKey(includeFromJson: false, includeToJson: false)
  int unreadCount = 0;

  ConversationModel({
    this.id,
    this.roomId,
    this.conversationType,
    this.userIdA,
    this.userIdB,
    this.status,
    this.remark,
    this.createTime,
    this.updateTime,
    this.otherUserName,
    this.otherUserAvatar,
    this.otherUserRole,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationModelToJson(this);

  /// 获取对方用户ID（相对于当前用户）
  int? getOtherUserId(int currentUserId) {
    if (userIdA == currentUserId) {
      return userIdB;
    } else if (userIdB == currentUserId) {
      return userIdA;
    }
    return null;
  }

  /// 是否为私聊
  bool get isPrivate => conversationType == 'PRIVATE';

  /// 是否为群聊
  bool get isGroup => conversationType == 'GROUP';

  /// 是否已关闭
  bool get isClosed => status == 1;
}


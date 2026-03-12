import 'package:flutter/foundation.dart';
import 'package:flymfrontend/models/conversation_model.dart';
import 'package:flymfrontend/services/api/im_service.dart';
import 'package:flymfrontend/core/exception/exception_handler.dart';
import 'package:flymfrontend/utils/logger_util.dart';

/// 聊天会话状态管理
class ChatProvider with ChangeNotifier {
  final ImService _imService;

  ChatProvider(this._imService);

  List<ConversationModel> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 加载会话列表
  Future<void> loadConversations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _imService.getMyConversations();
      if (result.success && result.data != null) {
        _conversations = result.data!;
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = result.message;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      LoggerUtil.e('加载会话列表失败', e);
      _errorMessage = ExceptionHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 刷新会话列表
  Future<void> refreshConversations() async {
    await loadConversations();
  }

  /// 更新会话的最后消息
  void updateLastMessage(String roomId, String message, String time) {
    final index = _conversations.indexWhere((c) => c.roomId == roomId);
    if (index != -1) {
      _conversations[index].lastMessage = message;
      _conversations[index].lastMessageTime = time;
      notifyListeners();
    }
  }

  /// 增加未读数
  void incrementUnreadCount(String roomId) {
    final index = _conversations.indexWhere((c) => c.roomId == roomId);
    if (index != -1) {
      _conversations[index].unreadCount++;
      notifyListeners();
    }
  }

  /// 清除未读数
  void clearUnreadCount(String roomId) {
    final index = _conversations.indexWhere((c) => c.roomId == roomId);
    if (index != -1) {
      _conversations[index].unreadCount = 0;
      notifyListeners();
    }
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}


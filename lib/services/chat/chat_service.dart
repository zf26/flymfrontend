import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flymfrontend/config/app_config.dart';
import 'package:flymfrontend/config/app_environment.dart';
import 'package:flymfrontend/models/chat_message_model.dart';
import 'package:flymfrontend/utils/logger_util.dart';
import 'package:flymfrontend/utils/storage_util.dart';

/// 连接状态枚举
enum ChatConnectionStatus {
  disconnected, // 未连接
  connecting, // 连接中
  connected, // 已连接
  reconnecting, // 重连中
  error, // 错误
}

/// 聊天服务类
/// 封装 STOMP + WebSocket 连接，提供消息收发功能
class ChatService {
  StompClient? _stompClient;
  ChatConnectionStatus _connectionStatus = ChatConnectionStatus.disconnected;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  final Map<String, StompUnsubscribe> _subscriptions = {};
  final Map<String, Function(ChatMessageModel)> _messageCallbacks = {};
  Function(ChatConnectionStatus)? _connectionStatusCallback;

  /// 默认订阅路径
  static const String personalChatQueue = '/user/queue/chat';
  static const String personalAckQueue = '/user/queue/ack';

  /// 群聊 Topic
  static String roomTopic(String roomId) => '/topic/room.$roomId';

  /// 当前连接状态
  ChatConnectionStatus get connectionStatus => _connectionStatus;

  /// 是否已连接
  bool get isConnected => _connectionStatus == ChatConnectionStatus.connected;

  /// WebSocket 基础URL
  String get _wsBaseUrl {
    final baseUrl =
        AppEnvironmentConfig.isDevelopment
            ? AppConfig.wsBaseUrlDev
            : AppConfig.wsBaseUrlProd;
    return '$baseUrl${AppConfig.wsStompEndpoint}';
  }

  /// 获取认证Token
  Future<String?> _getToken() async {
    return await StorageUtil.getString(AppConfig.keyToken);
  }

  /// 连接WebSocket服务器
  /// [onConnected] 连接成功回调
  /// [onError] 连接错误回调
  /// [onDisconnected] 断开连接回调
  Future<bool> connect({
    Function()? onConnected,
    Function(String error)? onError,
    Function()? onDisconnected,
  }) async {
    if (_connectionStatus == ChatConnectionStatus.connected ||
        _connectionStatus == ChatConnectionStatus.connecting) {
      LoggerUtil.w('ChatService: Already connected or connecting');
      return false;
    }

    try {
      _updateConnectionStatus(ChatConnectionStatus.connecting);

      final token = await _getToken();

      // 构建WebSocket URL（token放在请求头中，不放在URL中）
      final wsUrl = _wsBaseUrl;

      LoggerUtil.i('ChatService: Connecting to $wsUrl');

      // 注意：stomp_dart_client 会自己创建 WebSocket 连接
      // 这里不需要手动创建 channel

      // 仅在存在有效 token 时设置 Authorization 头，
      // 本地开发场景下即使未登录也允许建立连接。
      final connectHeaders = <String, String>{};
      if (token != null && token.isNotEmpty) {
        connectHeaders['Authorization'] = 'Bearer $token';
      }

      // 创建STOMP客户端配置
      final config = StompConfig(
        url: wsUrl,
        onConnect: (StompFrame frame) {
          LoggerUtil.i('ChatService: STOMP connected');
          _updateConnectionStatus(ChatConnectionStatus.connected);
          _startHeartbeat();
          _stopReconnectTimer();
          onConnected?.call();
        },
        onWebSocketError: (dynamic error) {
          LoggerUtil.e('ChatService: WebSocket error', error);
          _updateConnectionStatus(ChatConnectionStatus.error);
          _handleDisconnection();
          onError?.call(error.toString());
        },
        onStompError: (StompFrame frame) {
          LoggerUtil.e('ChatService: STOMP error: ${frame.body}');
          _updateConnectionStatus(ChatConnectionStatus.error);
          _handleDisconnection();
          onError?.call(frame.body ?? 'STOMP error');
        },
        onDisconnect: (StompFrame frame) {
          LoggerUtil.w('ChatService: STOMP disconnected');
          _updateConnectionStatus(ChatConnectionStatus.disconnected);
          _stopHeartbeat();
          _handleDisconnection();
          onDisconnected?.call();
        },
        beforeConnect: () async {
          // 连接前的准备工作
          LoggerUtil.d('ChatService: Before connect');
        },
        stompConnectHeaders: connectHeaders,
        webSocketConnectHeaders: connectHeaders,
        connectionTimeout: const Duration(seconds: 10),
        heartbeatIncoming: Duration(
          milliseconds: AppConfig.wsHeartbeatInterval,
        ),
        heartbeatOutgoing: Duration(
          milliseconds: AppConfig.wsHeartbeatInterval,
        ),
        reconnectDelay: const Duration(
          milliseconds: AppConfig.wsReconnectInterval,
        ),
      );

      // 创建并激活STOMP客户端
      _stompClient = StompClient(config: config);
      _stompClient!.activate();

      return true;
    } catch (e) {
      LoggerUtil.e('ChatService: Connection failed', e);
      _updateConnectionStatus(ChatConnectionStatus.error);
      _handleDisconnection();
      onError?.call(e.toString());
      return false;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    _stopReconnectTimer();
    _stopHeartbeat();
    _clearSubscriptions();

    if (_stompClient != null) {
      try {
        _stompClient!.deactivate();
        LoggerUtil.i('ChatService: Disconnected');
      } catch (e) {
        LoggerUtil.e('ChatService: Disconnect error', e);
      }
      _stompClient = null;
    }

    _updateConnectionStatus(ChatConnectionStatus.disconnected);
  }

  /// 订阅消息
  /// [destination] STOMP目标地址（如：/user/{userId}/queue/messages）
  /// [onMessage] 消息接收回调
  /// [subscriptionId] 订阅ID（用于取消订阅）
  void subscribe({
    required String destination,
    required Function(ChatMessageModel) onMessage,
    String? subscriptionId,
  }) {
    if (!isConnected) {
      LoggerUtil.w('ChatService: Cannot subscribe, not connected');
      return;
    }

    final subId = subscriptionId ?? destination;
    if (_subscriptions.containsKey(subId)) {
      LoggerUtil.w('ChatService: Already subscribed to $destination');
      return;
    }

    try {
      final subscription = _stompClient!.subscribe(
        destination: destination,
        callback: (StompFrame frame) {
          try {
            if (frame.body != null) {
              final jsonData = jsonDecode(frame.body!);
              final message = ChatMessageModel.fromJson(
                jsonData is Map<String, dynamic>
                    ? jsonData
                    : jsonDecode(jsonData.toString()),
              );
              LoggerUtil.d('ChatService: Message received: ${message.content}');
              onMessage(message);
            }
          } catch (e) {
            LoggerUtil.e('ChatService: Failed to parse message', e);
          }
        },
      );

      _subscriptions[subId] = subscription;
      _messageCallbacks[subId] = onMessage;
      LoggerUtil.i('ChatService: Subscribed to $destination');
    } catch (e) {
      LoggerUtil.e('ChatService: Subscribe failed', e);
    }
  }

  /// 取消订阅
  /// [subscriptionId] 订阅ID
  void unsubscribe(String subscriptionId) {
    final subscription = _subscriptions.remove(subscriptionId);
    if (subscription != null) {
      try {
        subscription();
        _messageCallbacks.remove(subscriptionId);
        LoggerUtil.i('ChatService: Unsubscribed from $subscriptionId');
      } catch (e) {
        LoggerUtil.e('ChatService: Unsubscribe error', e);
      }
    }
  }

  /// 发送消息
  /// [destination] STOMP目标地址（如：/app/chat.send）
  /// [message] 消息对象
  Future<bool> sendMessage({
    required String destination,
    required ChatMessageModel message,
  }) async {
    if (!isConnected) {
      LoggerUtil.w('ChatService: Cannot send message, not connected');
      return false;
    }

    try {
      final messageJson = jsonEncode(message.toJson());
      _stompClient!.send(
        destination: destination,
        body: messageJson,
        headers: {'content-type': 'application/json'},
      );
      LoggerUtil.d('ChatService: Message sent to $destination');
      return true;
    } catch (e) {
      LoggerUtil.e('ChatService: Send message failed', e);
      return false;
    }
  }

  /// 发送文本消息（便捷方法）
  Future<bool> sendTextMessage({
    required String destination,
    String type = 'CHAT',
    String? toUserId,
    String? roomId,
    required String content,
    Map<String, dynamic>? extra,
    int? timestamp,
  }) async {
    final message = ChatMessageModel(
      type: type,
      toUserId: toUserId,
      roomId: roomId,
      content: content,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      extra: extra,
    );

    return await sendMessage(destination: destination, message: message);
  }

  /// 设置连接状态变化回调
  void setConnectionStatusCallback(Function(ChatConnectionStatus) callback) {
    _connectionStatusCallback = callback;
  }

  /// 更新连接状态
  void _updateConnectionStatus(ChatConnectionStatus status) {
    if (_connectionStatus != status) {
      _connectionStatus = status;
      _connectionStatusCallback?.call(status);
    }
  }

  /// 处理断开连接
  void _handleDisconnection() {
    _clearSubscriptions();
    _stopHeartbeat();

    // 如果处于错误状态，尝试重连
    if (_connectionStatus == ChatConnectionStatus.error) {
      _startReconnectTimer();
    }
  }

  /// 启动重连定时器
  void _startReconnectTimer() {
    _stopReconnectTimer();
    _updateConnectionStatus(ChatConnectionStatus.reconnecting);

    _reconnectTimer = Timer.periodic(
      Duration(milliseconds: AppConfig.wsReconnectInterval),
      (timer) {
        if (_connectionStatus != ChatConnectionStatus.connected) {
          LoggerUtil.i('ChatService: Attempting to reconnect...');
          // 注意：这里需要重新调用 connect，但需要保存之前的参数
          // 实际使用时，建议在应用层处理重连逻辑
        } else {
          _stopReconnectTimer();
        }
      },
    );
  }

  /// 停止重连定时器
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// 启动心跳
  void _startHeartbeat() {
    _stopHeartbeat();
    // STOMP客户端会自动处理心跳，这里可以添加额外的逻辑
  }

  /// 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 清除所有订阅
  void _clearSubscriptions() {
    for (final subscription in _subscriptions.values) {
      try {
        subscription();
      } catch (e) {
        LoggerUtil.e('ChatService: Clear subscription error', e);
      }
    }
    _subscriptions.clear();
    _messageCallbacks.clear();
  }

  /// 获取所有活跃的订阅
  List<String> getActiveSubscriptions() {
    return _subscriptions.keys.toList();
  }
}

# 聊天服务模块使用说明

## 概述

本模块提供了基于 STOMP + WebSocket 的实时聊天功能，封装了连接管理、消息收发、订阅管理等核心功能。

## 功能特性

- ✅ WebSocket 连接管理（连接、断开、重连）
- ✅ STOMP 协议支持
- ✅ 消息订阅与取消订阅
- ✅ 消息发送（文本、图片、文件等）
- ✅ 连接状态监听
- ✅ 自动重连机制
- ✅ 心跳保活
- ✅ WebRTC 信令封装（音视频呼叫）

## 快速开始

### 1. 获取服务实例

```dart
import 'package:flymfrontend/core/di/service_locator.dart';
import 'package:flymfrontend/services/chat/chat_service.dart';

final chatService = ServiceLocator().getChatService();
```

### 2. 连接服务器

```dart
await chatService.connect(
  userId: 'user123',
  onConnected: () {
    print('连接成功');
  },
  onError: (error) {
    print('连接错误: $error');
  },
  onDisconnected: () {
    print('连接断开');
  },
);
```

### 3. 订阅消息

```dart
// 订阅个人消息队列
chatService.subscribe(
  destination: '/user/user123/queue/messages',
  subscriptionId: 'personal_messages',
  onMessage: (ChatMessageModel message) {
    print('收到消息: ${message.content}');
    // 处理消息，更新UI等
  },
);

// 订阅会话消息（群聊）
chatService.subscribe(
  destination: '/topic/conversation/conversation123',
  subscriptionId: 'conversation_messages',
  onMessage: (ChatMessageModel message) {
    print('收到会话消息: ${message.content}');
  },
);
```

### 4. 发送消息

```dart
// 发送文本消息
await chatService.sendTextMessage(
  destination: '/app/chat.send',
  conversationId: 'conversation123',
  senderId: 'user123',
  content: '你好，这是一条测试消息',
);

// 发送自定义消息
final message = ChatMessageModel(
  conversationId: 'conversation123',
  senderId: 'user123',
  content: '消息内容',
  type: ChatMessageType.text,
  timestamp: DateTime.now().millisecondsSinceEpoch,
);

await chatService.sendMessage(
  destination: '/app/chat.send',
  message: message,
);
```

### 5. 监听连接状态

```dart
chatService.setConnectionStatusCallback((status) {
  switch (status) {
    case ChatConnectionStatus.connected:
      // 连接成功
      break;
    case ChatConnectionStatus.disconnected:
      // 连接断开
      break;
    case ChatConnectionStatus.error:
      // 连接错误
      break;
    case ChatConnectionStatus.reconnecting:
      // 重连中
      break;
    default:
      break;
  }
});
```

### 6. 取消订阅

```dart
chatService.unsubscribe('personal_messages');
```

### 7. 断开连接

```dart
await chatService.disconnect();
```

## WebRTC 视频通话

`lib/services/chat/webrtc_signaling_service.dart` 集成了 `flutter_webrtc` 与 `stomp_dart_client`，可在不改动后端接口的前提下完成音/视频呼叫。

### 1. 创建实例并连接

```dart
final signaling = WebRtcSignalingService(
  remoteUserId: 2,
  roomId: 'room-1',
  enableVideo: true,
  onLocalStream: (stream) => localRenderer.srcObject = stream,
  onRemoteStream: (stream) => remoteRenderer.srcObject = stream,
  onCallStateChange: (state) => print('call state => $state'),
  onError: (msg) => debugPrint('call error: $msg'),
);

await signaling.connect(); // 建立 STOMP + PeerConnection
```

### 2. 主叫发起通话

```dart
await signaling.startCall();
```

### 3. 被叫侧

只要 `connect()` 成功并订阅到 `/user/queue/webrtc`，收到 `offer` 会自动生成 `answer` 并通过 `/app/webrtc.signal` 发回。收到 `candidate` 也会自动执行 `addCandidate`。

### 4. 挂断 & 清理

```dart
await signaling.hangUp();
await signaling.dispose(); // 释放 STOMP 和媒体资源
```

> 说明：服务内部会自动带上存储中的 Token 并使用 `AppConfig.wsBaseUrl*` 配置生成 WebSocket 地址，如需自定义可以传入 `customWsUrl`。

## 配置说明

在 `lib/config/app_config.dart` 中可以配置 WebSocket 相关参数：

```dart
// WebSocket配置
static const String wsBaseUrlDev = 'ws://192.168.127.1:10021';
static const String wsBaseUrlProd = 'ws://192.168.127.1:10021';
static const String wsStompEndpoint = '/ws'; // STOMP端点路径
static const int wsReconnectInterval = 5000; // 重连间隔(毫秒)
static const int wsHeartbeatInterval = 30000; // 心跳间隔(毫秒)
```

## 消息模型

`ChatMessageModel` 包含以下字段：

- `id`: 消息ID
- `conversationId`: 会话ID
- `senderId`: 发送者ID
- `senderName`: 发送者名称（可选）
- `senderAvatar`: 发送者头像（可选）
- `receiverId`: 接收者ID（可选）
- `content`: 消息内容
- `type`: 消息类型（text, image, file, system）
- `status`: 消息状态（sending, sent, delivered, read, failed）
- `timestamp`: 时间戳（毫秒）
- `extras`: 扩展字段（用于存储图片URL、文件信息等）

## 完整示例

参考 `lib/services/chat/chat_service_example.dart` 文件查看完整的使用示例。

## 注意事项

1. **连接前确保已登录**：连接 WebSocket 需要有效的认证 Token，确保用户已登录
2. **及时取消订阅**：在页面销毁或离开会话时，记得取消订阅以避免内存泄漏
3. **错误处理**：建议实现完善的错误处理逻辑，包括网络错误、连接超时等
4. **消息去重**：根据业务需求，可能需要实现消息去重机制
5. **后端配置**：确保后端服务器已正确配置 STOMP 端点，路径需要与配置一致

## 后端要求

后端需要支持 STOMP over WebSocket，常见的配置：

- STOMP 端点：`/ws`
- 应用前缀：`/app`（用于发送消息）
- 主题前缀：`/topic`（用于广播消息）
- 用户队列前缀：`/user`（用于点对点消息）

## 常见问题

### Q: 连接失败怎么办？
A: 检查以下几点：
- 网络连接是否正常
- WebSocket URL 是否正确
- Token 是否有效
- 后端服务是否正常运行

### Q: 消息发送失败？
A: 确保：
- WebSocket 已连接（`chatService.isConnected`）
- 目标地址（destination）正确
- 消息格式符合后端要求

### Q: 如何实现自动重连？
A: 服务已内置重连机制，当连接断开时会自动尝试重连。你也可以通过 `connectionStatusCallback` 监听状态变化，手动触发重连。

## 维护建议

1. **日志监控**：通过 `LoggerUtil` 查看连接和消息日志
2. **性能优化**：大量消息时考虑实现消息分页和本地缓存
3. **安全性**：确保 Token 传输安全，考虑使用 WSS（WebSocket Secure）
4. **测试**：编写单元测试和集成测试确保功能正常


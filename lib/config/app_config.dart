/// 应用配置
class AppConfig {
  // 应用信息
  static const String appName = '远程医疗问诊';
  static const String appVersion = '1.0.0';

  // API配置
  static const String baseUrlDev = 'http://192.168.127.1:10021';
  static const String baseUrlProd = 'http://192.168.127.1:10021';
  static const int connectTimeout = 30000; // 连接超时时间(毫秒)
  static const int receiveTimeout = 30000; // 接收超时时间(毫秒)

  // WebSocket配置
  static const String wsBaseUrlDev = 'ws://192.168.127.1:10021';
  static const String wsBaseUrlProd = 'ws://192.168.127.1:10021';
  static const String wsStompEndpoint = '/ws/websocket'; // STOMP端点路径（与后端 WebSocketConfig 中的 addEndpoint 一致）
  static const int wsReconnectInterval = 5000; // 重连间隔(毫秒)
  static const int wsHeartbeatInterval = 30000; // 心跳间隔(毫秒)

  // WebRTC配置
  static const Map<String, dynamic> webrtcPeerConnectionConfig = {
    'iceServers': [
      {'urls': 'stun:coturn.fly-fly.fun:3478'}, // 公共备用
      {
        'urls': [
          'turn:coturn.fly-fly.fun:3478?transport=udp',
          'turn:coturn.fly-fly.fun:3478?transport=tcp',
          'turns:coturn.fly-fly.fun:5349?transport=tcp', // 走 TLS
        ],
        'username': 'admin',
        'credential': 'iCnHUcKAVqSDDsdwew323',
      },
    ],
    'sdpSemantics': 'unified-plan',
  };
  // 本地存储Key
  static const String keyToken = 'token';
  static const String keyUserInfo = 'user_info';
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyCacheEnabled = 'cache_enabled';
  static const String keyAutoCleanCache = 'auto_clean_cache';

  // 分页配置
  static const int pageSize = 20;

  // 缓存配置
  static const String cacheKeyConsultations = 'consultations';
  static const String cacheKeyDoctors = 'doctors';
}

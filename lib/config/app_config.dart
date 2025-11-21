/// 应用配置
class AppConfig {
  // 应用信息
  static const String appName = '远程医疗问诊';
  static const String appVersion = '1.0.0';

  // API配置
  static const String baseUrlDev = 'http://localhost:10021';
  static const String baseUrlProd = 'http://localhost:10021';
  static const int connectTimeout = 30000; // 连接超时时间(毫秒)
  static const int receiveTimeout = 30000; // 接收超时时间(毫秒)

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

import 'package:flymfrontend/config/app_config.dart';

/// 应用环境枚举
enum AppEnvironment { development, production }

/// 环境配置管理
class AppEnvironmentConfig {
  static AppEnvironment _environment = AppEnvironment.development;

  /// 当前环境
  static AppEnvironment get environment => _environment;

  /// 是否为开发环境
  static bool get isDevelopment => _environment == AppEnvironment.development;

  /// 是否为生产环境
  static bool get isProduction => _environment == AppEnvironment.production;

  /// 设置环境
  static void setEnvironment(AppEnvironment env) {
    _environment = env;
  }

  /// 根据环境获取API地址
  static String getApiBaseUrl() {
    switch (_environment) {
      case AppEnvironment.development:
        return AppConfig.baseUrlDev;
      case AppEnvironment.production:
        return AppConfig.baseUrlProd;
    }
  }

  /// 是否启用日志
  static bool get enableLogging => isDevelopment;
}

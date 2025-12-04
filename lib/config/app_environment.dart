import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    String baseUrl;
    switch (_environment) {
      case AppEnvironment.development:
        baseUrl = AppConfig.baseUrlDev;
        break;
      case AppEnvironment.production:
        baseUrl = AppConfig.baseUrlProd;
        break;
    }

    // 在 Android 模拟器上，localhost 需要替换为 10.0.2.2
    // 10.0.2.2 是 Android 模拟器访问宿主机 localhost 的特殊 IP
    if (!kIsWeb && Platform.isAndroid && baseUrl.contains('192.168.127.1')) {
      baseUrl = baseUrl.replaceAll('192.168.127.1', '192.168.127.1');
    }

    return baseUrl;
  }

  /// 是否启用日志
  static bool get enableLogging => isDevelopment;
}

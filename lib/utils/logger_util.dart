import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flymfrontend/config/app_environment.dart';

/// 日志工具类
class LoggerUtil {
  static Logger? _logger;

  static Logger get logger {
    _logger ??= Logger(
      printer: PrettyPrinter(
        methodCount: kDebugMode ? 2 : 0,
        errorMethodCount: kDebugMode ? 8 : 0,
        lineLength: 120,
        colors: kDebugMode && AppEnvironmentConfig.enableLogging,
        printEmojis: kDebugMode && AppEnvironmentConfig.enableLogging,
      ),
      level: AppEnvironmentConfig.enableLogging ? Level.debug : Level.nothing,
    );
    return _logger!;
  }

  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    if (AppEnvironmentConfig.enableLogging) {
      final fullMessage =
          error != null
              ? '$message\n错误: $error${stackTrace != null ? '\n堆栈: $stackTrace' : ''}'
              : message;
      logger.d(fullMessage);
    }
  }

  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    if (AppEnvironmentConfig.enableLogging) {
      final fullMessage =
          error != null
              ? '$message\n错误: $error${stackTrace != null ? '\n堆栈: $stackTrace' : ''}'
              : message;
      logger.i(fullMessage);
    }
  }

  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    if (AppEnvironmentConfig.enableLogging) {
      final fullMessage =
          error != null
              ? '$message\n错误: $error${stackTrace != null ? '\n堆栈: $stackTrace' : ''}'
              : message;
      logger.w(fullMessage);
    }
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    // 错误日志始终记录
    final fullMessage =
        error != null
            ? '$message\n错误: $error${stackTrace != null ? '\n堆栈: $stackTrace' : ''}'
            : message;
    logger.e(fullMessage);
  }
}

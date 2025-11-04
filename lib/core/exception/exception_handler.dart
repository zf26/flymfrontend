import 'package:dio/dio.dart';
import 'package:flymfrontend/core/exception/app_exception.dart';
import 'package:flymfrontend/utils/logger_util.dart';

/// 异常处理器
class ExceptionHandler {
  /// 处理Dio异常
  static AppException handleDioException(DioException error) {
    LoggerUtil.e('Dio异常: ${error.type}', error.error, error.stackTrace);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('网络连接超时，请检查网络设置');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        String message;

        // 安全地获取错误消息
        try {
          final responseData = error.response?.data;
          if (responseData is Map) {
            message =
                responseData['message'] as String? ??
                responseData['msg'] as String? ??
                '服务器错误: $statusCode';
          } else if (responseData is String) {
            message = responseData;
          } else {
            message = '服务器错误: $statusCode';
          }
        } catch (e) {
          message = '服务器错误: $statusCode';
        }

        if (statusCode == 401) {
          return const AuthException('登录已过期，请重新登录', code: 401);
        } else if (statusCode == 403) {
          return const AuthException('无权限访问', code: 403);
        } else if (statusCode == 404) {
          return ApiException('请求的资源不存在', code: 404);
        } else if (statusCode == 405) {
          return ApiException('请求方法不允许，请检查API接口', code: 405);
        } else if (statusCode != null && statusCode >= 500) {
          return NetworkException('服务器错误，请稍后重试', code: statusCode);
        } else {
          return ApiException(message, code: statusCode);
        }

      case DioExceptionType.cancel:
        return const NetworkException('请求已取消');

      case DioExceptionType.connectionError:
        return const NetworkException('网络连接失败，请检查网络设置');

      default:
        return NetworkException(
          error.message ?? '网络请求失败',
          originalError: error.error,
        );
    }
  }

  /// 处理通用异常
  static AppException handleException(dynamic error) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      return handleDioException(error);
    }

    LoggerUtil.e('未知异常', error);

    return BusinessException(error.toString(), originalError: error);
  }

  /// 获取用户友好的错误消息
  static String getErrorMessage(dynamic error) {
    final exception = handleException(error);
    return exception.message;
  }
}

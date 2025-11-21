import 'package:dio/dio.dart';
import 'package:flymfrontend/services/api/api_service.dart';
import 'package:flymfrontend/core/result/api_result.dart';
import 'package:flymfrontend/core/exception/exception_handler.dart';
import 'package:flymfrontend/config/app_config.dart';
import 'package:flymfrontend/utils/storage_util.dart';

/// 认证服务
class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  /// 登录
  Future<ApiResult<Map<String, dynamic>>> login(
    String phone,
    String password,
  ) async {
    try {
      final response = await _apiService.post(
        '/auth/login',
        data: {'username': phone, 'password': password},
      );

      // 检查HTTP状态码，如果是403等错误状态码，需要特殊处理
      if (response.statusCode != null && response.statusCode! >= 400) {
        // 如果响应有数据，尝试解析
        if (response.data != null) {
          try {
            final result = ApiResult<Map<String, dynamic>>.fromJson(
              response.data as Map<String, dynamic>,
              (json) => json as Map<String, dynamic>,
            );
            return result;
          } catch (e) {
            // 如果解析失败，抛出异常
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              message: '服务器返回错误状态码: ${response.statusCode}',
            );
          }
        } else {
          // 如果没有响应数据，直接抛出异常
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: '服务器返回错误状态码: ${response.statusCode}',
          );
        }
      }

      final result = ApiResult<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );

      if (result.success && result.data != null) {
        final token = result.data!['access_token'] as String?;
        if (token != null) {
          await StorageUtil.setString(AppConfig.keyToken, token);
        }
      }

      return result;
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  /// 登出
  Future<void> logout() async {
    await StorageUtil.remove(AppConfig.keyToken);
    await StorageUtil.remove(AppConfig.keyUserInfo);
  }

  /// 获取当前token
  Future<String?> getToken() async {
    return StorageUtil.getString(AppConfig.keyToken);
  }

  /// 检查是否已登录（同步方法，用于路由守卫）
  bool isLoggedIn() {
    final token = StorageUtil.getString(AppConfig.keyToken);
    return token != null && token.isNotEmpty;
  }

  /// 检查是否已登录（异步方法）
  Future<bool> checkLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// 获取短信验证码
  Future<ApiResult<void>> sendSmsCode(String phone) async {
    try {
      final response = await _apiService.post(
        '/auth/sendSmsVerifyCode',
        data: {'phone': phone},
      );

      // 检查HTTP状态码
      if (response.statusCode != null && response.statusCode! >= 400) {
        if (response.data != null) {
          try {
            final result = ApiResult<void>.fromJson(
              response.data as Map<String, dynamic>,
              (_) {},
            );
            return result;
          } catch (e) {
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              message: '服务器返回错误状态码: ${response.statusCode}',
            );
          }
        } else {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: '服务器返回错误状态码: ${response.statusCode}',
          );
        }
      }

      return ApiResult<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) {},
      );
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  /// 注册
  Future<ApiResult<Map<String, dynamic>>> register(
    String phone,
    String password,
    String smsCode,
  ) async {
    try {
      final response = await _apiService.post(
        '/auth/register',
        data: {'username': phone, 'password': password, 'smsCode': smsCode},
      );

      // 检查HTTP状态码
      if (response.statusCode != null && response.statusCode! >= 400) {
        if (response.data != null) {
          try {
            final result = ApiResult<Map<String, dynamic>>.fromJson(
              response.data as Map<String, dynamic>,
              (json) => json as Map<String, dynamic>,
            );
            return result;
          } catch (e) {
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              message: '服务器返回错误状态码: ${response.statusCode}',
            );
          }
        } else {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: '服务器返回错误状态码: ${response.statusCode}',
          );
        }
      }

      final result = ApiResult<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );

      if (result.success && result.data != null) {
        final token = result.data!['access_token'] as String?;
        if (token != null) {
          await StorageUtil.setString(AppConfig.keyToken, token);
        }
      }

      return result;
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}

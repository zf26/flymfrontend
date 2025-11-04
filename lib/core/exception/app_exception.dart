/// 应用异常基类
abstract class AppException implements Exception {
  final String message;
  final int? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// 网络异常
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

/// API异常
class ApiException extends AppException {
  const ApiException(super.message, {super.code, super.originalError});
}

/// 认证异常
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

/// 业务异常
class BusinessException extends AppException {
  const BusinessException(super.message, {super.code, super.originalError});
}

/// 数据解析异常
class ParseException extends AppException {
  const ParseException(super.message, {super.code, super.originalError});
}

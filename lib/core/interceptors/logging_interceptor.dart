import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// 日志拦截器
class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 75,
      colors: true,
      printEmojis: true,
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
    if (options.queryParameters.isNotEmpty) {
      _logger.d('QueryParameters: ${options.queryParameters}');
    }
    if (options.data != null) {
      _logger.d('Data: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final errorMsg = StringBuffer();
    errorMsg.write(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );
    if (err.error != null) {
      errorMsg.write('\n错误: ${err.error}');
    }
    errorMsg.write('\n堆栈: ${err.stackTrace}');
    _logger.e(errorMsg.toString());
    handler.next(err);
  }
}

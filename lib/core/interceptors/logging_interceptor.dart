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
    _logger.d('Full URL: ${options.baseUrl}${options.path}');
    _logger.d('Headers: ${options.headers}');
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
    if (response.data != null) {
      try {
        final responseData = response.data;
        if (responseData is Map) {
          // 如果是Map，格式化输出
          _logger.d('Response Data: $responseData');
        } else if (responseData is String) {
          // 如果是字符串，直接输出
          _logger.d('Response Data: $responseData');
        } else {
          // 其他类型
          _logger.d('Response Data: ${responseData.toString()}');
        }
      } catch (e) {
        _logger.d('Response Data: (无法序列化)');
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final errorMsg = StringBuffer();
    errorMsg.write(
      'ERROR[${err.response?.statusCode ?? 'null'}] => PATH: ${err.requestOptions.path}',
    );
    errorMsg.write(
      '\nFull URL: ${err.requestOptions.baseUrl}${err.requestOptions.path}',
    );
    errorMsg.write('\nRequest Method: ${err.requestOptions.method}');
    errorMsg.write('\nRequest Headers: ${err.requestOptions.headers}');

    // 详细错误信息
    errorMsg.write('\nError Type: ${err.type}');
    if (err.message != null) {
      errorMsg.write('\nError Message: ${err.message}');
    }

    if (err.response != null) {
      errorMsg.write('\nResponse Status Code: ${err.response!.statusCode}');
      errorMsg.write('\nResponse Headers: ${err.response!.headers}');
      if (err.response!.data != null) {
        try {
          errorMsg.write('\nResponse Data: ${err.response!.data}');
        } catch (e) {
          errorMsg.write('\nResponse Data: (无法序列化)');
        }
      }
    } else {
      errorMsg.write('\n⚠️ 没有收到服务器响应（可能是CORS或网络问题）');
    }

    if (err.error != null) {
      errorMsg.write('\n原始错误: ${err.error}');
    }

    // 如果是连接错误，提供更详细的诊断信息
    if (err.type == DioExceptionType.connectionError) {
      errorMsg.write('\n\n💡 诊断建议：');
      errorMsg.write('\n1. 检查服务器是否运行在 ${err.requestOptions.baseUrl}');
      errorMsg.write('\n2. 检查浏览器控制台的Network标签，查看是否有CORS错误');
      errorMsg.write('\n3. 如果是CORS问题，需要后端配置CORS头');
      errorMsg.write('\n4. 检查防火墙或代理设置');
    }

    errorMsg.write('\n堆栈: ${err.stackTrace}');
    _logger.e(errorMsg.toString());
    handler.next(err);
  }
}

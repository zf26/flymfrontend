/// API统一返回结果封装
class ApiResult<T> {
  final int code;
  final String message;
  final T? data;
  final bool success;

  const ApiResult({required this.code, required this.message, this.data})
    : success = code == 200;

  /// 从响应数据创建ApiResult
  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    final code = json['code'] as int? ?? 500;
    final message = json['message'] as String? ?? '未知错误';
    final dynamic dataJson = json['data'];

    T? data;
    if (dataJson != null && fromJsonT != null) {
      try {
        data = fromJsonT(dataJson);
      } catch (e) {
        // 解析失败时返回null
        data = null;
      }
    } else if (dataJson != null) {
      data = dataJson as T?;
    }

    return ApiResult<T>(code: code, message: message, data: data);
  }

  /// 成功结果
  factory ApiResult.success(T data, {String? message}) {
    return ApiResult<T>(code: 200, message: message ?? '操作成功', data: data);
  }

  /// 失败结果
  factory ApiResult.failure(String message, {int code = 500}) {
    return ApiResult<T>(code: code, message: message, data: null);
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {'code': code, 'message': message, 'data': data};
  }
}

import 'package:dio/dio.dart';
import 'package:flymfrontend/core/exception/exception_handler.dart';
import 'package:flymfrontend/core/result/api_result.dart';
import 'package:flymfrontend/models/chat_message_model.dart';
import 'package:flymfrontend/services/api/api_service.dart';

/// IM 聊天相关 API 服务
class ImService {
  final ApiService _apiService;

  ImService(this._apiService);

  /// 获取或创建会话密钥
  Future<ApiResult<String>> getConversationKey(String roomId) async {
    try {
      final Response response = await _apiService.get('/conversation/room/$roomId');
      return ApiResult<String>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json?.toString() ?? '',
      );
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  /// 获取当前用户与目标用户的聊天历史（密文内容），由前端使用 conversationKey 解密
  Future<ApiResult<List<ChatMessageModel>>> getPrivateHistory({
    required String targetUserId,
    String? roomId,
    int limit = 100,
  }) async {
    try {
      final query = <String, dynamic>{
        'targetUserId': targetUserId,
        'limit': limit,
      };
      if (roomId != null && roomId.isNotEmpty) {
        query['roomId'] = roomId;
      }
      final Response response = await _apiService.get(
        '/im/history/private',
        queryParameters: query,
      );

      return ApiResult<List<ChatMessageModel>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          if (json is List) {
            return json
                .map(
                  (item) =>
                      ChatMessageModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return <ChatMessageModel>[];
        },
      );
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}

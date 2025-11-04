import 'package:dio/dio.dart';
import 'package:flymfrontend/services/api/api_service.dart';
import 'package:flymfrontend/core/result/api_result.dart';
import 'package:flymfrontend/core/exception/exception_handler.dart';
import 'package:flymfrontend/models/consultation_model.dart';

/// 问诊服务
class ConsultationService {
  final ApiService _apiService;

  ConsultationService(this._apiService);

  /// 获取问诊列表
  Future<ApiResult<List<ConsultationModel>>> getConsultationList({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final response = await _apiService.get(
        '/consultation/list',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (status != null) 'status': status,
        },
      );

      return ApiResult<List<ConsultationModel>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          if (json is List) {
            return json
                .map(
                  (item) =>
                      ConsultationModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return [];
        },
      );
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  /// 获取问诊详情
  Future<ApiResult<ConsultationModel>> getConsultationDetail(String id) async {
    try {
      final response = await _apiService.get('/consultation/$id');

      return ApiResult<ConsultationModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ConsultationModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  /// 创建问诊
  Future<ApiResult<ConsultationModel>> createConsultation({
    required String doctorId,
    required String description,
    List<String>? images,
  }) async {
    try {
      final response = await _apiService.post(
        '/consultation/create',
        data: {
          'doctorId': doctorId,
          'description': description,
          if (images != null) 'images': images,
        },
      );

      return ApiResult<ConsultationModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ConsultationModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  /// 取消问诊
  Future<ApiResult<void>> cancelConsultation(String id) async {
    try {
      final response = await _apiService.post('/consultation/$id/cancel');

      return ApiResult<void>.fromJson(
        response.data as Map<String, dynamic>,
        null,
      );
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}

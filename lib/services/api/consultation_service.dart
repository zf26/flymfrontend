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
    ConsultationModel? consultationModel,
    int pageNum = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiService.get(
        '/consultation/consultationsmaster/list',
        queryParameters: {
          'pageNum': pageNum,
          'pageSize': pageSize,
          if (consultationModel != null)
            'consultations': consultationModel.toJson(),
        },
      );

      // 处理分页响应格式：{total: 0, rows: [], code: 200, msg: "查询成功"}
      final responseData = response.data as Map<String, dynamic>;
      final code = responseData['code'] as int? ?? 500;
      final message =
          responseData['message'] as String? ??
          responseData['msg'] as String? ??
          '未知错误';
      final rows = responseData['rows'] as List<dynamic>? ?? [];
      final consultations =
          rows
              .map(
                (item) =>
                    ConsultationModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();

      return ApiResult<List<ConsultationModel>>(
        code: code,
        message: message,
        data: consultations,
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
      final response = await _apiService.get('/consultation/consultation/$id');

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
    String consultationType = '初诊',
    String? department,
    String consultationMethod = '文字',
    bool isAnonymous = false,
    String? priceBudget,
    String urgencyLevel = '普通',
    List<String>? symptoms,
    bool agreeToTerms = false,
  }) async {
    try {
      final response = await _apiService.post(
        '/consultation/create',
        data: {
          'doctorId': doctorId,
          'description': description,
          if (images != null) 'images': images,
          'consultationType': consultationType,
          if (department != null) 'department': department,
          'consultationMethod': consultationMethod,
          'isAnonymous': isAnonymous,
          if (priceBudget != null) 'priceBudget': priceBudget,
          'urgencyLevel': urgencyLevel,
          if (symptoms != null) 'symptoms': symptoms,
          'agreeToTerms': agreeToTerms,
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
      final response = await _apiService.post(
        '/consultation/consultation/$id/cancel',
      );

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

import 'package:dio/dio.dart';
import 'package:flymfrontend/services/api/api_service.dart';
import 'package:flymfrontend/core/result/api_result.dart';
import 'package:flymfrontend/core/exception/exception_handler.dart';
import 'package:flymfrontend/models/doctor_model.dart';

/// 医生服务
class DoctorService {
  final ApiService _apiService;

  DoctorService(this._apiService);

  /// 获取医生列表
  Future<ApiResult<List<DoctorModel>>> getDoctorList({
    int page = 1,
    int pageSize = 20,
    String? department,
    String? keyword,
  }) async {
    try {
      final response = await _apiService.get(
        '/doctor/list',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (department != null) 'department': department,
          if (keyword != null) 'keyword': keyword,
        },
      );

      return ApiResult<List<DoctorModel>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          if (json is List) {
            return json
                .map(
                  (item) => DoctorModel.fromJson(item as Map<String, dynamic>),
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

  /// 获取医生详情
  Future<ApiResult<DoctorModel>> getDoctorDetail(String id) async {
    try {
      final response = await _apiService.get('/doctor/$id');

      return ApiResult<DoctorModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DoctorModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}

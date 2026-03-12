import 'package:dio/dio.dart';
import 'package:flymfrontend/services/api/api_service.dart';
import 'package:flymfrontend/core/result/api_result.dart';
import 'package:flymfrontend/core/exception/exception_handler.dart';
import 'package:flymfrontend/models/consultation_recommendation_model.dart';

/// 症状分析服务
/// 调用NLP+知识图谱接口进行症状分析
class SymptomAnalysisService {
  final ApiService _apiService;

  SymptomAnalysisService(this._apiService);

  /// 分析症状描述
  Future<ConsultationRecommendation> analyzeSymptoms(
    String symptomDescription,
  ) async {
    try {
      final response = await _apiService.post(
        '/analysis/symptoms/analyze',
        data: {
          'symptomDescription': symptomDescription,
          'includeRecommendations': true,
        },
      );

      final result = ApiResult<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );

      if (!result.success) {
        throw Exception(result.message);
      }

      if (result.data == null) {
        throw Exception('分析结果为空');
      }

      return ConsultationRecommendation.fromJson(result.data!);
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  /// 获取症状关键词建议
  Future<List<String>> getSymptomSuggestions(String partialInput) async {
    try {
      final response = await _apiService.get(
        '/analysis/symptoms/suggestions',
        queryParameters: {'query': partialInput, 'limit': 10},
      );

      final result = ApiResult<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as List<dynamic>,
      );

      if (!result.success) {
        return [];
      }

      return result.data?.cast<String>() ?? [];
    } catch (e) {
      return [];
    }
  }

  /// 获取常见症状标签
  Future<List<String>> getCommonSymptoms() async {
    try {
      final response = await _apiService.get('/analysis/symptoms/common');

      final result = ApiResult<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as List<dynamic>,
      );

      if (!result.success) {
        return [];
      }

      return result.data?.cast<String>() ?? [];
    } catch (e) {
      return [];
    }
  }
}

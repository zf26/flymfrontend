import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flymfrontend/services/api/api_service.dart';
import 'package:flymfrontend/core/result/api_result.dart';
import 'package:flymfrontend/core/exception/exception_handler.dart';
import 'package:image_picker/image_picker.dart';

/// 图片上传服务
class UploadService {
  final ApiService _apiService;
  final ImagePicker _imagePicker = ImagePicker();

  UploadService(this._apiService);

  /// 选择图片（从相册或相机）
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('选择图片失败: ${e.toString()}');
    }
  }

  /// 上传单张图片
  Future<ApiResult<String>> uploadImage(XFile imageFile) async {
    try {
      FormData formData;

      if (kIsWeb) {
        // Web平台
        final bytes = await imageFile.readAsBytes();
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: imageFile.name),
        });
      } else {
        // 移动端平台
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.name,
          ),
        });
      }

      final response = await _apiService.post(
        '/upload/image',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      return ApiResult<String>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as String? ?? '',
      );
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  /// 批量上传图片
  Future<ApiResult<List<String>>> uploadImages(List<XFile> imageFiles) async {
    try {
      final List<String> uploadedUrls = [];

      for (final imageFile in imageFiles) {
        final result = await uploadImage(imageFile);
        if (result.success && result.data != null) {
          uploadedUrls.add(result.data!);
        } else {
          throw Exception('上传图片失败: ${result.message}');
        }
      }

      return ApiResult.success(uploadedUrls);
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }
}

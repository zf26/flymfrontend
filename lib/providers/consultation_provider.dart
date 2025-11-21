import 'package:flutter/foundation.dart';
import 'package:flymfrontend/models/consultation_model.dart';
import 'package:flymfrontend/services/api/consultation_service.dart';
import 'package:flymfrontend/core/exception/exception_handler.dart';
import 'package:flymfrontend/core/cache/cache_manager.dart';
import 'package:flymfrontend/utils/logger_util.dart';
import 'package:flymfrontend/utils/storage_util.dart';
import 'package:flymfrontend/config/app_config.dart';

/// 问诊状态管理
class ConsultationProvider with ChangeNotifier {
  final ConsultationService _consultationService;
  final CacheManager _cacheManager = CacheManager();

  ConsultationProvider(this._consultationService);

  List<ConsultationModel> _consultations = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;

  List<ConsultationModel> get consultations => _consultations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  /// 获取问诊列表
  Future<void> loadConsultations({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _consultations.clear();
    }

    if (!_hasMore || _isLoading) return;

    // 检查缓存是否启用
    final cacheEnabled = StorageUtil.getBool(AppConfig.keyCacheEnabled) ?? true;

    // 如果是第一页且启用缓存，尝试从缓存加载
    if (_currentPage == 1 && cacheEnabled && !refresh) {
      try {
        final cachedData = _cacheManager.getCache<List<dynamic>>(
          key: AppConfig.cacheKeyConsultations,
        );
        if (cachedData != null && cachedData.isNotEmpty) {
          _consultations =
              cachedData
                  .map(
                    (json) => ConsultationModel.fromJson(
                      json as Map<String, dynamic>,
                    ),
                  )
                  .toList();
          _hasMore = _consultations.length >= AppConfig.pageSize;
          _currentPage = 2;
          notifyListeners();
        }
      } catch (e) {
        LoggerUtil.w('从缓存加载问诊列表失败', e);
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _consultationService.getConsultationList(
        page: _currentPage,
        pageSize: AppConfig.pageSize,
      );

      if (result.success && result.data != null) {
        final newConsultations = result.data!;
        _consultations.addAll(newConsultations);
        _hasMore = newConsultations.length >= AppConfig.pageSize;
        _currentPage++;

        // 如果是第一页且启用缓存，保存到缓存
        if (_currentPage == 2 && cacheEnabled) {
          try {
            final cacheData = _consultations.map((c) => c.toJson()).toList();
            await _cacheManager.setCache<List<dynamic>>(
              key: AppConfig.cacheKeyConsultations,
              data: cacheData,
              expiry: const Duration(minutes: 30),
            );
          } catch (e) {
            LoggerUtil.w('保存问诊列表到缓存失败', e);
          }
        }

        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = result.message;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      LoggerUtil.e('加载问诊列表失败', e);
      _errorMessage = ExceptionHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 刷新问诊列表
  Future<void> refreshConsultations() async {
    // 清除缓存
    await _cacheManager.removeCache(AppConfig.cacheKeyConsultations);
    await loadConsultations(refresh: true);
  }

  /// 创建问诊
  Future<bool> createConsultation({
    required String doctorId,
    required String description,
    List<String>? images,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _consultationService.createConsultation(
        doctorId: doctorId,
        description: description,
        images: images,
      );

      if (result.success) {
        _isLoading = false;
        notifyListeners();
        // 创建成功后刷新列表
        await refreshConsultations();
        return true;
      } else {
        _errorMessage = result.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      LoggerUtil.e('创建问诊失败', e);
      _errorMessage = ExceptionHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

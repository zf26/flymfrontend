import 'package:flutter/foundation.dart';
import 'package:flymfrontend/models/doctor_model.dart';
import 'package:flymfrontend/services/api/doctor_service.dart';
import 'package:flymfrontend/core/exception/exception_handler.dart';
import 'package:flymfrontend/core/cache/cache_manager.dart';
import 'package:flymfrontend/utils/logger_util.dart';
import 'package:flymfrontend/utils/storage_util.dart';
import 'package:flymfrontend/config/app_config.dart';

/// 医生状态管理
class DoctorProvider with ChangeNotifier {
  final DoctorService _doctorService;
  final CacheManager _cacheManager = CacheManager();

  DoctorProvider(this._doctorService);

  List<DoctorModel> _doctors = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _currentDepartment;
  String? _currentKeyword;

  List<DoctorModel> get doctors => _doctors;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  /// 获取医生列表
  Future<void> loadDoctors({
    bool refresh = false,
    String? department,
    String? keyword,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _doctors.clear();
      _currentDepartment = department;
      _currentKeyword = keyword;
    }

    if (!_hasMore || _isLoading) return;

    // 检查缓存是否启用（只有在没有筛选条件时才使用缓存）
    final cacheEnabled = StorageUtil.getBool(AppConfig.keyCacheEnabled) ?? true;
    final hasFilter =
        (department ?? _currentDepartment) != null ||
        (keyword ?? _currentKeyword) != null;

    // 如果是第一页且启用缓存且没有筛选条件，尝试从缓存加载
    if (_currentPage == 1 && cacheEnabled && !refresh && !hasFilter) {
      try {
        final cachedData = _cacheManager.getCache<List<dynamic>>(
          key: AppConfig.cacheKeyDoctors,
        );
        if (cachedData != null && cachedData.isNotEmpty) {
          _doctors =
              cachedData
                  .map(
                    (json) =>
                        DoctorModel.fromJson(json as Map<String, dynamic>),
                  )
                  .toList();
          _hasMore = _doctors.length >= AppConfig.pageSize;
          _currentPage = 2;
          notifyListeners();
        }
      } catch (e) {
        LoggerUtil.w('从缓存加载医生列表失败', e);
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _doctorService.getDoctorList(
        page: _currentPage,
        pageSize: AppConfig.pageSize,
        department: department ?? _currentDepartment,
        keyword: keyword ?? _currentKeyword,
      );

      if (result.success && result.data != null) {
        final newDoctors = result.data!;
        _doctors.addAll(newDoctors);
        _hasMore = newDoctors.length >= AppConfig.pageSize;
        _currentPage++;

        // 如果是第一页且启用缓存且没有筛选条件，保存到缓存
        if (_currentPage == 2 && cacheEnabled && !hasFilter) {
          try {
            final cacheData = _doctors.map((d) => d.toJson()).toList();
            await _cacheManager.setCache<List<dynamic>>(
              key: AppConfig.cacheKeyDoctors,
              data: cacheData,
              expiry: const Duration(hours: 1),
            );
          } catch (e) {
            LoggerUtil.w('保存医生列表到缓存失败', e);
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
      LoggerUtil.e('加载医生列表失败', e);
      _errorMessage = ExceptionHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 刷新医生列表
  Future<void> refreshDoctors() async {
    // 清除缓存
    await _cacheManager.removeCache(AppConfig.cacheKeyDoctors);
    await loadDoctors(refresh: true);
  }

  /// 搜索医生
  Future<void> searchDoctors(String keyword) async {
    await loadDoctors(refresh: true, keyword: keyword);
  }

  /// 按科室筛选
  Future<void> filterByDepartment(String department) async {
    await loadDoctors(refresh: true, department: department);
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

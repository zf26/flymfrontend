import 'package:flutter/foundation.dart';
import 'package:flymfrontend/models/consultation_model.dart';
import 'package:flymfrontend/services/api/consultation_service.dart';
import 'package:flymfrontend/core/exception/exception_handler.dart';
import 'package:flymfrontend/utils/logger_util.dart';
import 'package:flymfrontend/config/app_config.dart';

/// 问诊状态管理
class ConsultationProvider with ChangeNotifier {
  final ConsultationService _consultationService;

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
    await loadConsultations(refresh: true);
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:flymfrontend/models/user_model.dart';
import 'package:flymfrontend/services/api/auth_service.dart';
import 'package:flymfrontend/core/exception/exception_handler.dart';
import 'package:flymfrontend/utils/storage_util.dart';
import 'package:flymfrontend/utils/logger_util.dart';
import 'package:flymfrontend/config/app_config.dart';
import 'dart:convert';

/// 认证状态管理
class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService);

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  /// 初始化用户信息
  Future<void> initUser() async {
    try {
      final userJson = StorageUtil.getString(AppConfig.keyUserInfo);
      if (userJson != null && userJson.isNotEmpty) {
        try {
          final userMap = jsonDecode(userJson) as Map<String, dynamic>;
          _user = UserModel.fromJson(userMap);
          notifyListeners();
        } catch (e) {
          LoggerUtil.e('解析用户信息失败', e);
          // 清除无效的用户信息
          await StorageUtil.remove(AppConfig.keyUserInfo);
        }
      }
    } catch (e) {
      LoggerUtil.e('初始化用户信息失败', e);
      _errorMessage = ExceptionHandler.getErrorMessage(e);
      notifyListeners();
    }
  }

  /// 登录
  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(phone, password);
      if (result.success && result.data != null) {
        // 保存用户信息
        final userData = result.data!['user'];
        if (userData != null) {
          _user = UserModel.fromJson(userData as Map<String, dynamic>);
          await StorageUtil.setString(
            AppConfig.keyUserInfo,
            jsonEncode(_user!.toJson()),
          );
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      LoggerUtil.e('登录失败', e);
      _errorMessage = ExceptionHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      await _authService.logout();
      _user = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      LoggerUtil.e('登出失败', e);
      _errorMessage = ExceptionHandler.getErrorMessage(e);
      notifyListeners();
    }
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

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

  /// 安全地解析用户数据，处理 null 值
  UserModel? _parseUserData(Map<String, dynamic> userData) {
    try {
      // 创建清理后的数据副本，处理 null 值
      final cleanedData = <String, dynamic>{};

      cleanedData['id'] = userData['id'].toString();

      // 其他字段可以为 null，但需要确保类型正确
      cleanedData['phone'] = userData['phone']?.toString();
      cleanedData['name'] = userData['name']?.toString();
      cleanedData['avatar'] = userData['avatar']?.toString();
      cleanedData['gender'] = userData['gender']?.toString();

      // age 字段需要特殊处理，可能是 int 或 null
      if (userData['age'] != null) {
        if (userData['age'] is int) {
          cleanedData['age'] = userData['age'];
        } else if (userData['age'] is num) {
          cleanedData['age'] = (userData['age'] as num).toInt();
        } else {
          cleanedData['age'] = null;
        }
      } else {
        cleanedData['age'] = null;
      }

      return UserModel.fromJson(cleanedData);
    } catch (e) {
      LoggerUtil.e('解析用户数据失败', e);
      return null;
    }
  }

  /// 初始化用户信息
  Future<void> initUser() async {
    try {
      final userJson = StorageUtil.getString(AppConfig.keyUserInfo);
      debugPrint('userJson: $userJson');
      if (userJson != null && userJson.isNotEmpty) {
        try {
          final userMap = jsonDecode(userJson) as Map<String, dynamic>;
          _user = _parseUserData(userMap);
          if (_user != null) {
            notifyListeners();
          } else {
            // 清除无效的用户信息
            await StorageUtil.remove(AppConfig.keyUserInfo);
          }
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
  Future<bool> login(
    String phone,
    String password, {
    String? uuid,
    String? code,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        phone,
        password,
        uuid: uuid,
        code: code,
      );
      if (result.success && result.data != null) {
        // 保存用户信息
        final userData = result.data!['user'];
        if (userData != null) {
          _user = _parseUserData(userData as Map<String, dynamic>);
          if (_user != null) {
            await StorageUtil.setString(
              AppConfig.keyUserInfo,
              jsonEncode(_user!.toJson()),
            );
          }
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

  /// 短信验证码登录
  Future<bool> loginWithSmsCode(String phone, String smsCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.loginWithSmsCode(phone, smsCode);
      if (result.success && result.data != null) {
        final userData = result.data!['user'];
        if (userData != null) {
          _user = _parseUserData(userData as Map<String, dynamic>);
          if (_user != null) {
            await StorageUtil.setString(
              AppConfig.keyUserInfo,
              jsonEncode(_user!.toJson()),
            );
          }
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
      LoggerUtil.e('短信登录失败', e);
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

  /// 微信登录
  Future<bool> loginWithWeChat() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: 实现微信登录逻辑
      await Future.delayed(const Duration(seconds: 1)); // 模拟请求
      _isLoading = false;
      notifyListeners();
      // 临时返回false，实际应该调用微信登录API
      _errorMessage = '微信登录功能开发中';
      return false;
    } catch (e) {
      LoggerUtil.e('微信登录失败', e);
      _errorMessage = ExceptionHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 支付宝登录
  Future<bool> loginWithAlipay() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: 实现支付宝登录逻辑
      await Future.delayed(const Duration(seconds: 1)); // 模拟请求
      _isLoading = false;
      notifyListeners();
      // 临时返回false，实际应该调用支付宝登录API
      _errorMessage = '支付宝登录功能开发中';
      return false;
    } catch (e) {
      LoggerUtil.e('支付宝登录失败', e);
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

  /// 获取短信验证码
  Future<bool> sendSmsCode(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.sendSmsCode(phone);
      _isLoading = false;
      notifyListeners();
      if (result.success) {
        return true;
      } else {
        _errorMessage = result.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      LoggerUtil.e('获取验证码失败', e);
      _errorMessage = ExceptionHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 注册
  Future<bool> register(String phone, String password, String smsCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(phone, password, smsCode);
      if (result.success && result.data != null) {
        // 保存用户信息
        final userData = result.data!['user'];
        if (userData != null) {
          _user = _parseUserData(userData as Map<String, dynamic>);
          if (_user != null) {
            await StorageUtil.setString(
              AppConfig.keyUserInfo,
              jsonEncode(_user!.toJson()),
            );
          }
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
      LoggerUtil.e('注册失败', e);
      _errorMessage = ExceptionHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flymfrontend/utils/storage_util.dart';
import 'package:flymfrontend/core/cache/cache_manager.dart';
import 'package:flymfrontend/config/app_config.dart';
import 'package:flymfrontend/utils/logger_util.dart';

/// 设置状态管理
class SettingsProvider with ChangeNotifier {
  final CacheManager _cacheManager = CacheManager();

  bool _cacheEnabled = true;
  bool _autoCleanCache = true;
  String _cacheSize = '0 MB';
  bool _isLoadingCacheSize = false;

  bool get cacheEnabled => _cacheEnabled;
  bool get autoCleanCache => _autoCleanCache;
  String get cacheSize => _cacheSize;
  bool get isLoadingCacheSize => _isLoadingCacheSize;

  SettingsProvider() {
    _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      await StorageUtil.init();
      _cacheEnabled = StorageUtil.getBool(AppConfig.keyCacheEnabled) ?? true;
      _autoCleanCache =
          StorageUtil.getBool(AppConfig.keyAutoCleanCache) ?? true;
      await _updateCacheSize();
      notifyListeners();
    } catch (e) {
      LoggerUtil.e('加载设置失败', e);
    }
  }

  /// 更新缓存大小
  Future<void> _updateCacheSize() async {
    _isLoadingCacheSize = true;
    notifyListeners();

    try {
      final size = await _cacheManager.getAppCacheSummary();
      _cacheSize = _cacheManager.formatCacheSize(size['total']);
    } catch (e) {
      LoggerUtil.e('获取缓存大小失败', e);
      _cacheSize = '0 MB';
    } finally {
      _isLoadingCacheSize = false;
      notifyListeners();
    }
  }

  /// 设置缓存启用状态
  Future<void> setCacheEnabled(bool enabled) async {
    try {
      await StorageUtil.setBool(AppConfig.keyCacheEnabled, enabled);
      _cacheEnabled = enabled;
      notifyListeners();
    } catch (e) {
      LoggerUtil.e('设置缓存启用状态失败', e);
    }
  }

  /// 设置自动清理缓存
  Future<void> setAutoCleanCache(bool enabled) async {
    try {
      await StorageUtil.setBool(AppConfig.keyAutoCleanCache, enabled);
      _autoCleanCache = enabled;
      notifyListeners();
    } catch (e) {
      LoggerUtil.e('设置自动清理缓存失败', e);
    }
  }

  /// 清除所有缓存
  Future<bool> clearAllCache() async {
    try {
      final success = await _cacheManager.clearAllCache();
      if (success) {
        await _updateCacheSize();
      }
      return success;
    } catch (e) {
      LoggerUtil.e('清除缓存失败', e);
      return false;
    }
  }

  /// 清理过期缓存
  Future<void> cleanExpiredCache() async {
    try {
      await _cacheManager.cleanExpiredCache();
      await _updateCacheSize();
    } catch (e) {
      LoggerUtil.e('清理过期缓存失败', e);
    }
  }

  /// 刷新缓存大小
  Future<void> refreshCacheSize() async {
    await _updateCacheSize();
  }
}

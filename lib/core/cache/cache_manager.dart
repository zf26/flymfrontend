import 'dart:convert';
import 'package:flymfrontend/utils/storage_util.dart';
import 'package:flymfrontend/utils/logger_util.dart';

/// 缓存项
class CacheItem<T> {
  final T data;
  final DateTime timestamp;
  final Duration? expiry;

  CacheItem({required this.data, required this.timestamp, this.expiry});

  bool get isExpired {
    if (expiry == null) return false;
    return DateTime.now().difference(timestamp) > expiry!;
  }
}

/// 缓存管理器
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // 缓存配置
  static const String _cachePrefix = 'cache_';
  static const String _cacheMetaPrefix = 'cache_meta_';

  // 默认缓存过期时间
  static const Duration defaultExpiry = Duration(hours: 1);

  // 缓存大小限制（MB）
  static const int maxCacheSizeMB = 50;

  /// 保存缓存
  Future<bool> setCache<T>({
    required String key,
    required T data,
    Duration? expiry,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final cacheKey = '$_cachePrefix$key';
      final metaKey = '$_cacheMetaPrefix$key';

      // 序列化数据
      String dataJson;
      if (data is Map || data is List) {
        dataJson = jsonEncode(data);
      } else if (data is String) {
        dataJson = data;
      } else {
        // 对于其他类型，尝试使用toJson方法
        try {
          dataJson = jsonEncode((data as dynamic).toJson());
        } catch (e) {
          LoggerUtil.w('无法序列化缓存数据: $key', e);
          return false;
        }
      }

      // 保存数据
      final dataSaved = await StorageUtil.setString(cacheKey, dataJson);

      // 保存元数据
      final meta = {
        'timestamp': DateTime.now().toIso8601String(),
        'expiry': expiry?.inMilliseconds,
        'type': T.toString(),
      };
      final metaSaved = await StorageUtil.setString(metaKey, jsonEncode(meta));

      return dataSaved && metaSaved;
    } catch (e) {
      LoggerUtil.e('保存缓存失败: $key', e);
      return false;
    }
  }

  /// 获取缓存
  T? getCache<T>({
    required String key,
    T Function(Map<String, dynamic>)? fromJson,
  }) {
    try {
      final cacheKey = '$_cachePrefix$key';
      final metaKey = '$_cacheMetaPrefix$key';

      // 获取元数据
      final metaJson = StorageUtil.getString(metaKey);
      if (metaJson == null) return null;

      final meta = jsonDecode(metaJson) as Map<String, dynamic>;
      final timestamp = DateTime.parse(meta['timestamp'] as String);
      final expiryMs = meta['expiry'] as int?;

      // 检查是否过期
      if (expiryMs != null) {
        final expiry = Duration(milliseconds: expiryMs);
        if (DateTime.now().difference(timestamp) > expiry) {
          // 缓存已过期，删除
          removeCache(key);
          return null;
        }
      }

      // 获取数据
      final dataJson = StorageUtil.getString(cacheKey);
      if (dataJson == null) return null;

      // 反序列化数据
      if (T == String) {
        return dataJson as T;
      } else if (T == Map || T == List) {
        return jsonDecode(dataJson) as T;
      } else if (fromJson != null) {
        final dataMap = jsonDecode(dataJson) as Map<String, dynamic>;
        return fromJson(dataMap);
      } else {
        // 尝试使用fromJson方法
        try {
          final dataMap = jsonDecode(dataJson) as Map<String, dynamic>;
          return (T as dynamic).fromJson(dataMap) as T;
        } catch (e) {
          LoggerUtil.w('无法反序列化缓存数据: $key', e);
          return null;
        }
      }
    } catch (e) {
      LoggerUtil.e('获取缓存失败: $key', e);
      return null;
    }
  }

  /// 获取缓存（异步方式，用于检查过期）
  Future<T?> getCacheAsync<T>({
    required String key,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return getCache<T>(key: key, fromJson: fromJson);
  }

  /// 删除缓存
  Future<bool> removeCache(String key) async {
    try {
      final cacheKey = '$_cachePrefix$key';
      final metaKey = '$_cacheMetaPrefix$key';

      final removed1 = await StorageUtil.remove(cacheKey);
      final removed2 = await StorageUtil.remove(metaKey);

      return removed1 && removed2;
    } catch (e) {
      LoggerUtil.e('删除缓存失败: $key', e);
      return false;
    }
  }

  /// 清除所有缓存
  Future<bool> clearAllCache() async {
    try {
      await StorageUtil.init();
      final keys = StorageUtil.getKeys();

      int removedCount = 0;
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_cacheMetaPrefix)) {
          await StorageUtil.remove(key);
          removedCount++;
        }
      }

      LoggerUtil.i('已清除 $removedCount 个缓存项');
      return true;
    } catch (e) {
      LoggerUtil.e('清除所有缓存失败', e);
      return false;
    }
  }

  /// 获取缓存大小（估算）
  Future<int> getCacheSize() async {
    try {
      await StorageUtil.init();
      final keys = StorageUtil.getKeys();

      int totalSize = 0;
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          final value = StorageUtil.getString(key);
          if (value != null) {
            totalSize += value.length * 2; // UTF-16编码，每个字符2字节
          }
        }
      }

      return totalSize;
    } catch (e) {
      LoggerUtil.e('获取缓存大小失败', e);
      return 0;
    }
  }

  /// 格式化缓存大小
  String formatCacheSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// 检查并清理过期缓存
  Future<void> cleanExpiredCache() async {
    try {
      await StorageUtil.init();
      final keys = StorageUtil.getKeys();

      int cleanedCount = 0;
      for (final key in keys) {
        if (key.startsWith(_cacheMetaPrefix)) {
          final metaJson = StorageUtil.getString(key);
          if (metaJson != null) {
            try {
              final meta = jsonDecode(metaJson) as Map<String, dynamic>;
              final timestamp = DateTime.parse(meta['timestamp'] as String);
              final expiryMs = meta['expiry'] as int?;

              if (expiryMs != null) {
                final expiry = Duration(milliseconds: expiryMs);
                if (DateTime.now().difference(timestamp) > expiry) {
                  // 缓存已过期，删除
                  final cacheKey = key.replaceFirst(
                    _cacheMetaPrefix,
                    _cachePrefix,
                  );
                  await StorageUtil.remove(cacheKey);
                  await StorageUtil.remove(key);
                  cleanedCount++;
                }
              }
            } catch (e) {
              // 元数据格式错误，删除
              final cacheKey = key.replaceFirst(_cacheMetaPrefix, _cachePrefix);
              await StorageUtil.remove(cacheKey);
              await StorageUtil.remove(key);
              cleanedCount++;
            }
          }
        }
      }

      if (cleanedCount > 0) {
        LoggerUtil.i('已清理 $cleanedCount 个过期缓存');
      }
    } catch (e) {
      LoggerUtil.e('清理过期缓存失败', e);
    }
  }
}

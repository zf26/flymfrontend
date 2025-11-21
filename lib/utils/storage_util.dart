import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储工具类
class StorageUtil {
  static late SharedPreferences _prefs;

  /// 初始化
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 保存字符串
  static Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  /// 获取字符串
  static String? getString(String key) {
    return _prefs.getString(key);
  }

  /// 保存整数
  static Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  /// 获取整数
  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  /// 保存布尔值
  static Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  /// 获取布尔值
  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  /// 保存字符串列表
  static Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  /// 获取字符串列表
  static List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  /// 删除指定key
  static Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  /// 清空所有数据
  static Future<bool> clear() async {
    return await _prefs.clear();
  }

  /// 检查key是否存在
  static bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  /// 获取所有keys
  static Set<String> getKeys() {
    return _prefs.getKeys();
  }

  /// 获取SharedPreferences实例（用于高级操作）
  static SharedPreferences get instance => _prefs;
}

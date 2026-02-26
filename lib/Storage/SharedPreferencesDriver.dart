import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowgame/Storage/LocalStoreDriver.dart';

/// SharedPreferences 存储驱动实现
///
/// 定位：[LocalStoreDriver] 的具体实现，基于 SharedPreferences 提供 key-value 存储。
/// 职责：封装 SharedPreferences 的读写操作，对外暴露统一的异步接口。
/// 不负责：业务逻辑、数据格式解析、版本迁移。
/// 上游依赖方：Repository 实现层（通过 [LocalStoreDriver] 接口引用）。
/// 下游依赖方：shared_preferences 包。
///
/// 跨平台说明：
///   SharedPreferences 在 Windows 上使用文件系统，在 Android 上使用原生 SharedPreferences，
///   flutter 插件已统一封装，本实现无需关心平台差异。
class SharedPreferencesDriver implements LocalStoreDriver {
  SharedPreferences? _prefs;

  /// 初始化：获取 SharedPreferences 实例
  ///
  /// 伪代码思路：
  ///   如果已初始化则跳过 -> 否则获取 SharedPreferences 实例并缓存
  @override
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 确保已初始化，未初始化则抛出异常
  SharedPreferences get _store {
    if (_prefs == null) {
      throw StateError(
        'SharedPreferencesDriver 未初始化，请先调用 init()',
      );
    }
    return _prefs!;
  }

  @override
  Future<String?> getString(String key) async {
    return _store.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _store.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _store.remove(key);
  }

  @override
  Future<Set<String>> getKeys() async {
    return _store.getKeys();
  }

  @override
  Future<void> clear() async {
    await _store.clear();
  }
}

/// 本地存储驱动抽象层
///
/// 定位：持久化体系最底层，负责封装底层 DB/文件操作的统一接口。
/// 职责：提供 key-value 形式的读写事务接口，隔离具体存储技术选型。
/// 不负责：业务逻辑、数据结构映射、版本迁移。
/// 上游依赖方：Repository 实现层通过此接口进行数据读写。
/// 下游依赖方：无（最底层）。
///
/// 设计意图：
///   - 上层代码（Repository）只面向此抽象接口编程，不关心底层是 SharedPreferences/SQLite/Hive。
///   - 切换存储引擎时只需提供新的 [LocalStoreDriver] 实现，上层零改动。
///   - 支持未来导出/导入（备份恢复）扩展。
abstract class LocalStoreDriver {
  /// 初始化存储引擎
  ///
  /// 伪代码思路：
  ///   获取底层存储实例 -> 标记为已就绪
  ///   必须在其他读写操作前调用
  Future<void> init();

  /// 读取指定 key 的 JSON 字符串
  ///
  /// 伪代码思路：
  ///   从底层存储中按 key 取出字符串 -> 返回（不存在则返回 null）
  ///   不做任何反序列化，反序列化由 Repository 层负责
  Future<String?> getString(String key);

  /// 写入指定 key 的 JSON 字符串
  ///
  /// 伪代码思路：
  ///   将 value 按 key 写入底层存储 -> 确保持久化成功
  Future<void> setString(String key, String value);

  /// 删除指定 key
  ///
  /// 伪代码思路：
  ///   从底层存储中移除 key 对应的数据
  Future<void> remove(String key);

  /// 获取所有已存储的 key 列表
  ///
  /// 伪代码思路：
  ///   遍历底层存储 -> 收集所有 key -> 返回列表
  ///   用于调试、迁移、备份场景
  Future<Set<String>> getKeys();

  /// 清除所有数据（危险操作，仅用于测试或强制重置）
  ///
  /// 伪代码思路：
  ///   清空底层存储全部内容
  Future<void> clear();
}

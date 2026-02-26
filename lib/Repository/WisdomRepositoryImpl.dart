import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nowgame/Dto/WisdomDto.dart';
import 'package:nowgame/Repository/WisdomRepository.dart';
import 'package:nowgame/Storage/LocalStoreDriver.dart';

/// Wisdom 领域仓储实现
///
/// 定位：[WisdomRepository] 的具体实现，负责 Wisdom 数据与存储驱动之间的桥接。
/// 职责：
///   - 调用 [LocalStoreDriver] 读写 JSON 数据
///   - 处理 JSON 解析异常，数据损坏时返回空默认值并记录日志
///   - 不做业务逻辑运算
/// 不负责：经验计算、等级升级、任务完成判定。
/// 上游依赖方：WisdomService（业务层）。
/// 下游依赖方：LocalStoreDriver（存储驱动层）。
///
/// 存储 key 设计：
///   使用统一的 'wisdom_data' key 存储整个 Wisdom 聚合数据，
///   替代原来分散的 'wisdom_skills'/'wisdom_skill_points'/'wisdom_tasks' 三个 key。
///   旧数据通过 MigrationStep 迁移合并。
class WisdomRepositoryImpl implements WisdomRepository {
  /// 存储 key
  static const String storageKey = 'wisdom_data';

  /// 存储驱动
  final LocalStoreDriver _driver;

  WisdomRepositoryImpl(this._driver);

  /// 加载 Wisdom 全量数据
  ///
  /// 伪代码思路：
  ///   1. 从驱动读取 storageKey 对应的 JSON 字符串
  ///   2. 如果为空（首次启动）-> 返回空的 WisdomDto
  ///   3. JSON 解析 -> 反序列化为 WisdomDto
  ///   4. 解析失败 -> 记录错误日志 -> 返回空默认值（保证不崩溃）
  @override
  Future<WisdomDto> load() async {
    try {
      final jsonStr = await _driver.getString(storageKey);
      if (jsonStr == null) return const WisdomDto();

      final Map<String, dynamic> jsonMap = json.decode(jsonStr);
      return WisdomDto.fromJson(jsonMap);
    } catch (e) {
      debugPrint('❌ [WisdomRepository] 加载数据失败，返回空默认值: $e');
      return const WisdomDto();
    }
  }

  /// 保存 Wisdom 全量数据
  ///
  /// 伪代码思路：
  ///   1. 将 WisdomDto 序列化为 JSON Map
  ///   2. encode 为 JSON 字符串
  ///   3. 通过驱动写入存储
  ///   4. 写入失败 -> 记录错误日志（不静默吞异常，向上抛出让调用方知晓）
  @override
  Future<void> save(WisdomDto dto) async {
    try {
      final jsonStr = json.encode(dto.toJson());
      await _driver.setString(storageKey, jsonStr);
    } catch (e) {
      debugPrint('❌ [WisdomRepository] 保存数据失败: $e');
      rethrow;
    }
  }
}

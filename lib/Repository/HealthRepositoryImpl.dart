import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nowgame/Dto/HealthDto.dart';
import 'package:nowgame/Repository/HealthRepository.dart';
import 'package:nowgame/Storage/LocalStoreDriver.dart';

/// Health 领域仓储实现
///
/// 定位：[HealthRepository] 的具体实现，负责 Health 数据与存储驱动之间的桥接。
/// 职责：
///   - 调用 [LocalStoreDriver] 读写 JSON 数据
///   - 处理 JSON 解析异常，数据损坏时返回空默认值并记录日志
///   - 不做业务逻辑运算
/// 不负责：分数计算、扣分逻辑、按钮重置判定。
/// 上游依赖方：HealthService（业务层）。
/// 下游依赖方：LocalStoreDriver（存储驱动层）。
///
/// 存储 key 设计：
///   使用 'health_data' key（与原 'health_data_map' 区分）。
///   旧数据通过 MigrationStep 迁移。
class HealthRepositoryImpl implements HealthRepository {
  /// 存储 key
  static const String storageKey = 'health_data';

  /// 存储驱动
  final LocalStoreDriver _driver;

  HealthRepositoryImpl(this._driver);

  /// 加载 Health 全量数据
  ///
  /// 伪代码思路：
  ///   1. 从驱动读取 storageKey 对应的 JSON 字符串
  ///   2. 如果为空 -> 返回空的 HealthDto
  ///   3. JSON 解析 -> 反序列化为 HealthDto
  ///   4. 解析失败 -> 记录错误日志 -> 返回空默认值
  @override
  Future<HealthDto> load() async {
    try {
      final jsonStr = await _driver.getString(storageKey);
      if (jsonStr == null) return const HealthDto();

      final Map<String, dynamic> jsonMap = json.decode(jsonStr);
      return HealthDto.fromJson(jsonMap);
    } catch (e) {
      debugPrint('❌ [HealthRepository] 加载数据失败，返回空默认值: $e');
      return const HealthDto();
    }
  }

  /// 保存 Health 全量数据
  ///
  /// 伪代码思路：
  ///   1. 将 HealthDto 序列化为 JSON Map
  ///   2. encode 为 JSON 字符串
  ///   3. 通过驱动写入存储
  @override
  Future<void> save(HealthDto dto) async {
    try {
      final jsonStr = json.encode(dto.toJson());
      await _driver.setString(storageKey, jsonStr);
    } catch (e) {
      debugPrint('❌ [HealthRepository] 保存数据失败: $e');
      rethrow;
    }
  }
}

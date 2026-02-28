import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nowgame/Dto/ShopDto.dart';
import 'package:nowgame/Repository/ShopRepository.dart';
import 'package:nowgame/Storage/LocalStoreDriver.dart';

/// Shop 领域仓储实现
///
/// 定位：[ShopRepository] 的具体实现，负责 Shop 数据与存储驱动之间的桥接。
/// 职责：
///   - 调用 [LocalStoreDriver] 读写 JSON 数据
///   - 处理 JSON 解析异常，数据损坏时返回空默认值并记录日志
///   - 不做业务逻辑运算
/// 不负责：抽卡随机、购买逻辑、过期清理。
/// 上游依赖方：ShopService（业务层）。
/// 下游依赖方：LocalStoreDriver（存储驱动层）。
///
/// 存储 key 设计：
///   使用独立的 'shop_data' key，与 Wisdom/Health 领域互不干涉。
class ShopRepositoryImpl implements ShopRepository {
  /// 存储 key
  static const String storageKey = 'shop_data';

  /// 存储驱动
  final LocalStoreDriver _driver;

  ShopRepositoryImpl(this._driver);

  /// 加载 Shop 全量数据
  ///
  /// 伪代码思路：
  ///   1. 从驱动读取 storageKey 对应的 JSON 字符串
  ///   2. 如果为空（首次启动）-> 返回空的 ShopDto
  ///   3. JSON 解析 -> 反序列化为 ShopDto
  ///   4. 解析失败 -> 记录错误日志 -> 返回空默认值（保证不崩溃）
  @override
  Future<ShopDto> load() async {
    try {
      final jsonStr = await _driver.getString(storageKey);
      if (jsonStr == null) return const ShopDto();

      final Map<String, dynamic> jsonMap = json.decode(jsonStr);
      return ShopDto.fromJson(jsonMap);
    } catch (e) {
      debugPrint('❌ [ShopRepository] 加载数据失败，返回空默认值: $e');
      return const ShopDto();
    }
  }

  /// 保存 Shop 全量数据
  ///
  /// 伪代码思路：
  ///   1. 将 ShopDto 序列化为 JSON Map
  ///   2. encode 为 JSON 字符串
  ///   3. 通过驱动写入存储
  @override
  Future<void> save(ShopDto dto) async {
    try {
      final jsonStr = json.encode(dto.toJson());
      await _driver.setString(storageKey, jsonStr);
    } catch (e) {
      debugPrint('❌ [ShopRepository] 保存数据失败: $e');
      rethrow;
    }
  }
}

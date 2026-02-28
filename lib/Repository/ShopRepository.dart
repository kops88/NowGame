import 'package:nowgame/Dto/ShopDto.dart';

/// Shop 领域仓储接口
///
/// 定位：仓储层抽象，定义 Shop 领域（商品 + 奖池）的数据读写契约。
/// 职责：提供 load/save 操作的统一接口，隐藏底层存储细节。
/// 不负责：抽卡逻辑、购买逻辑、过期清理、UI 展示、底层存储实现。
/// 上游依赖方：ShopService（业务层）通过此接口进行数据持久化。
/// 下游依赖方：ShopRepositoryImpl（仓储实现层）。
///
/// 扩展说明：
///   Shop 领域数据独立于 Wisdom/Health，使用独立的 storage key。
///   新增商品类型或奖池属性时只需扩展 ShopDto 和此接口。
abstract class ShopRepository {
  /// 加载全部 Shop 数据（商品列表 + 奖池列表）
  ///
  /// 伪代码思路：
  ///   从存储驱动读取 JSON 字符串 -> 反序列化为 ShopDto
  ///   -> 数据损坏时返回空的默认 ShopDto 并记录错误日志
  Future<ShopDto> load();

  /// 保存全部 Shop 数据
  ///
  /// 伪代码思路：
  ///   将 ShopDto 序列化为 JSON 字符串 -> 写入存储驱动
  Future<void> save(ShopDto dto);
}

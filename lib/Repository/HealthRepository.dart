import 'package:nowgame/Dto/HealthDto.dart';

/// Health 领域仓储接口
///
/// 定位：仓储层抽象，定义 Health 领域（每日健康数据）的数据读写契约。
/// 职责：提供 load/save 操作的统一接口，隐藏底层存储细节。
/// 不负责：健康分数计算、扣分逻辑、UI 展示、底层存储实现。
/// 上游依赖方：HealthService（业务层）通过此接口进行数据持久化。
/// 下游依赖方：HealthRepositoryImpl（仓储实现层）。
///
/// 扩展说明：
///   Health 领域数据独立于 Wisdom，互不污染。
///   新增健康维度时只需扩展 HealthDto 和此接口。
abstract class HealthRepository {
  /// 加载全部 Health 数据
  ///
  /// 伪代码思路：
  ///   从存储驱动读取 JSON 字符串 -> 反序列化为 HealthDto
  ///   -> 数据损坏时返回空的默认 HealthDto 并记录错误日志
  Future<HealthDto> load();

  /// 保存全部 Health 数据
  ///
  /// 伪代码思路：
  ///   将 HealthDto 序列化为 JSON 字符串 -> 写入存储驱动
  Future<void> save(HealthDto dto);
}

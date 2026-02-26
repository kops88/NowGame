import 'package:nowgame/Dto/WisdomDto.dart';

/// Wisdom 领域仓储接口
///
/// 定位：仓储层抽象，定义 Wisdom 领域（技能卡+技能点+任务）的数据读写契约。
/// 职责：提供 load/save 操作的统一接口，隐藏底层存储细节。
/// 不负责：业务逻辑（升级、经验计算）、UI 展示、底层存储实现。
/// 上游依赖方：WisdomService（业务层）通过此接口进行数据持久化。
/// 下游依赖方：WisdomRepositoryImpl（仓储实现层）。
///
/// 扩展说明：
///   新增 Wisdom 子模块时，只需扩展 WisdomDto 和此接口的方法，
///   不影响 Health 等其他领域的仓储。
abstract class WisdomRepository {
  /// 加载全部 Wisdom 数据
  ///
  /// 伪代码思路：
  ///   从存储驱动读取 JSON 字符串 -> 反序列化为 WisdomDto
  ///   -> 数据损坏时返回空的默认 WisdomDto 并记录错误日志
  Future<WisdomDto> load();

  /// 保存全部 Wisdom 数据
  ///
  /// 伪代码思路：
  ///   将 WisdomDto 序列化为 JSON 字符串 -> 写入存储驱动
  Future<void> save(WisdomDto dto);
}

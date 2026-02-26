import 'package:flutter/foundation.dart';
import 'package:nowgame/Storage/LocalStoreDriver.dart';

/// 数据迁移步骤定义
///
/// 定位：描述从一个版本到下一个版本的单步迁移操作。
/// 职责：封装版本号和对应的迁移函数。
/// 不负责：决定执行顺序（由 MigrationEngine 管理）。
/// 在哪一层使用：迁移模块层。
/// 与版本迁移的关系：每个 MigrationStep 代表迁移链中的一环。
class MigrationStep {
  /// 此迁移步骤的目标版本号
  ///
  /// 例如 fromVersion=1 -> toVersion=2，表示将数据从 v1 升级到 v2
  final int toVersion;

  /// 迁移执行函数
  ///
  /// 接收 [LocalStoreDriver] 以便读写底层存储数据
  /// 返回 Future<void>，迁移失败应抛出异常
  final Future<void> Function(LocalStoreDriver driver) migrate;

  const MigrationStep({
    required this.toVersion,
    required this.migrate,
  });
}

/// 数据迁移引擎
///
/// 定位：持久化体系的版本管理核心，负责检测数据版本并按序执行迁移链。
/// 职责：
///   - 启动时读取当前数据版本号
///   - 比对目标版本号，按序执行 MigrationStep 链
///   - 迁移成功后更新版本号
///   - 迁移失败时进行回滚保护（保留原始数据不破坏）
/// 不负责：具体业务数据的格式转换（由各领域的 MigrationStep 实现）。
/// 上游依赖方：Bootstrap 模块在应用启动时调用。
/// 下游依赖方：LocalStoreDriver（读写版本号和数据）。
class MigrationEngine {
  /// 存储版本号的 key
  static const String _versionKey = 'schema_version';

  /// 当前应用期望的最新数据版本
  final int targetVersion;

  /// 按版本升序排列的迁移步骤链
  final List<MigrationStep> steps;

  /// 存储驱动
  final LocalStoreDriver driver;

  /// 迁移引擎构造
  ///
  /// [targetVersion] 当前代码期望的数据版本
  /// [steps] 迁移步骤列表（必须按 toVersion 升序排列）
  /// [driver] 底层存储驱动
  MigrationEngine({
    required this.targetVersion,
    required this.steps,
    required this.driver,
  });

  /// 执行迁移
  ///
  /// 伪代码思路：
  ///   1. 读取存储中的当前版本号（不存在视为首次安装，设为 targetVersion）
  ///   2. 如果当前版本 == targetVersion，无需迁移，直接返回
  ///   3. 如果当前版本 < targetVersion，筛选需要执行的 steps（toVersion > currentVersion）
  ///   4. 按序逐个执行迁移步骤
  ///   5. 每步成功后立即更新版本号（增量落盘，防止中途崩溃时从头开始）
  ///   6. 任何步骤失败则停止迁移、保留已完成的步骤版本号，并抛出异常
  Future<void> migrate() async {
    final versionStr = await driver.getString(_versionKey);
    int currentVersion;

    if (versionStr == null) {
      // 首次安装：直接标记为最新版本，无需迁移
      await driver.setString(_versionKey, targetVersion.toString());
      debugPrint('🔧 [Migration] 首次安装，数据版本设为 v$targetVersion');
      return;
    }

    currentVersion = int.tryParse(versionStr) ?? 0;

    if (currentVersion >= targetVersion) {
      debugPrint('🔧 [Migration] 数据版本 v$currentVersion 已是最新，无需迁移');
      return;
    }

    debugPrint('🔧 [Migration] 开始迁移：v$currentVersion -> v$targetVersion');

    // 筛选需要执行的步骤并按 toVersion 排序
    final pendingSteps = steps
        .where((s) => s.toVersion > currentVersion && s.toVersion <= targetVersion)
        .toList()
      ..sort((a, b) => a.toVersion.compareTo(b.toVersion));

    for (final step in pendingSteps) {
      try {
        debugPrint('🔧 [Migration] 执行迁移步骤 -> v${step.toVersion}');
        await step.migrate(driver);
        // 每步成功后立即更新版本号
        await driver.setString(_versionKey, step.toVersion.toString());
        debugPrint('🔧 [Migration] 迁移到 v${step.toVersion} 成功');
      } catch (e) {
        debugPrint('❌ [Migration] 迁移到 v${step.toVersion} 失败: $e');
        debugPrint('❌ [Migration] 已完成到 v$currentVersion，后续步骤中止');
        rethrow;
      }
    }

    debugPrint('🔧 [Migration] 迁移完成，当前版本 v$targetVersion');
  }
}

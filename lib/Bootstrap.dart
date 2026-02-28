import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nowgame/Dto/WisdomDto.dart';
import 'package:nowgame/Repository/HealthRepository.dart';
import 'package:nowgame/Repository/HealthRepositoryImpl.dart';
import 'package:nowgame/Repository/ShopRepository.dart';
import 'package:nowgame/Repository/ShopRepositoryImpl.dart';
import 'package:nowgame/Repository/WisdomRepository.dart';
import 'package:nowgame/Repository/WisdomRepositoryImpl.dart';
import 'package:nowgame/Service/HealthService.dart';
import 'package:nowgame/Service/ShopService.dart';
import 'package:nowgame/Service/SkillPointService.dart';
import 'package:nowgame/Service/SkillService.dart';
import 'package:nowgame/Service/TaskService.dart';
import 'package:nowgame/Storage/LocalStoreDriver.dart';
import 'package:nowgame/Storage/MigrationEngine.dart';
import 'package:nowgame/Storage/SharedPreferencesDriver.dart';

/// 应用引导初始化模块
///
/// 定位：应用启动阶段的统一入口，负责按正确顺序完成所有初始化工作。
/// 职责：
///   1. 初始化存储驱动
///   2. 执行数据版本迁移
///   3. 创建 Repository 实例
///   4. 初始化所有 Service 单例并注入依赖
///   5. 从 Repository 加载数据到 Service 内存
///   6. 注册协调保存回调
/// 不负责：业务逻辑、UI 展示。
/// 上游依赖方：main.dart 在 runApp 前调用。
/// 下游依赖方：所有 Service、Repository、Storage 层。
///
/// 初始化完成前，不允许业务层读写未准备完成的仓储。
class AppBootstrap {
  /// 当前数据版本号
  ///
  /// 每次数据结构变更时递增此值，并在 [_buildMigrationSteps] 中添加对应迁移步骤。
  /// v1: 初始版本 —— 从散落的 SharedPreferences key 迁移到统一聚合存储
  /// v2: 新增 MainQuest 模块（全新 key，无需旧数据迁移，仅标记版本号升级）
  /// v3: 移除独立 MainQuest 模块，将其数据迁移到 Wisdom/Skill 体系；SkillDto 新增 deadline 字段
  /// v4: 新增 Shop 模块（商品 + 奖池，全新 key，无需旧数据迁移）
  static const int currentSchemaVersion = 4;

  /// 存储驱动（全局共享）
  late final LocalStoreDriver _driver;

  /// 仓储实例
  late final WisdomRepository _wisdomRepository;
  late final HealthRepository _healthRepository;
  late final ShopRepository _shopRepository;

  /// 执行完整的应用初始化流程
  ///
  /// 伪代码思路：
  ///   1. 创建并初始化存储驱动（SharedPreferences）
  ///   2. 构建迁移步骤链 -> 创建迁移引擎 -> 执行迁移
  ///   3. 创建 Repository 实例（注入存储驱动）
  ///   4. 初始化各 Service 单例（注入 Repository）
  ///   5. 从 Repository 加载数据到 Service
  ///   6. 为各 Service 注册协调保存回调
  ///   7. 初始化 Health Service
  Future<void> initialize() async {
    debugPrint('🚀 [Bootstrap] 开始应用初始化...');

    // 1. 初始化存储驱动
    _driver = SharedPreferencesDriver();
    await _driver.init();
    debugPrint('🚀 [Bootstrap] 存储驱动初始化完成');

    // 2. 执行数据迁移
    final migrationEngine = MigrationEngine(
      targetVersion: currentSchemaVersion,
      steps: _buildMigrationSteps(),
      driver: _driver,
    );
    await migrationEngine.migrate();
    debugPrint('🚀 [Bootstrap] 数据迁移完成');

    // 3. 创建 Repository 实例
    _wisdomRepository = WisdomRepositoryImpl(_driver);
    _healthRepository = HealthRepositoryImpl(_driver);
    _shopRepository = ShopRepositoryImpl(_driver);

    // 4. 初始化 Service 单例
    SkillService.initialize(_wisdomRepository);
    SkillPointService.initialize();
    TaskService.initialize();
    HealthService.initialize(_healthRepository);
    ShopService.initialize(_shopRepository);

    // 5. 加载 Wisdom 数据
    final wisdomDto = await _wisdomRepository.load();
    SkillService().loadFromDto(wisdomDto.skills);
    SkillPointService().loadFromDto(wisdomDto.skillPoints);
    TaskService().loadFromDto(wisdomDto.tasks);
    debugPrint('🚀 [Bootstrap] Wisdom 数据加载完成: '
        '${wisdomDto.skills.length} skills, '
        '${wisdomDto.skillPoints.length} points, '
        '${wisdomDto.tasks.length} tasks');

    // 6. 注册协调保存回调
    Future<void> saveWisdom() async {
      final dto = WisdomDto(
        skills: SkillService().toDto(),
        skillPoints: SkillPointService().toDto(),
        tasks: TaskService().toDto(),
      );
      await _wisdomRepository.save(dto);
    }

    SkillService().onSaveRequested = saveWisdom;
    SkillPointService().onSaveRequested = saveWisdom;
    TaskService().onSaveRequested = saveWisdom;

    // 7. 加载 Shop 数据
    final shopDto = await _shopRepository.load();
    ShopService().loadFromDto(shopDto);
    debugPrint('🚀 [Bootstrap] Shop 数据加载完成: '
        '${shopDto.items.length} items, '
        '${shopDto.poolItems.length} pool items');

    // 8. 初始化 Health 数据
    await HealthService().init();
    debugPrint('🚀 [Bootstrap] Health 数据加载完成');

    debugPrint('🚀 [Bootstrap] 应用初始化完成');
  }

  /// 构建迁移步骤链
  ///
  /// 伪代码思路：
  ///   返回按版本升序排列的 MigrationStep 列表。
  ///   v1: 从旧的散落 key 迁移到统一聚合 key。
  ///   v2: 新增 MainQuest 模块（全新模块无旧数据，此步骤仅标记版本号升级）。
  ///   v3: 移除独立 MainQuest 模块，将其数据迁移到 Wisdom/Skill 体系。
  ///   v4: 新增 Shop 模块（全新模块无旧数据，仅标记版本号升级）。
  ///   后续版本只需在此追加新的 MigrationStep。
  List<MigrationStep> _buildMigrationSteps() {
    return [
      MigrationStep(
        toVersion: 1,
        migrate: _migrateToV1,
      ),
      MigrationStep(
        toVersion: 2,
        migrate: _migrateToV2,
      ),
      MigrationStep(
        toVersion: 3,
        migrate: _migrateToV3,
      ),
      MigrationStep(
        toVersion: 4,
        migrate: _migrateToV4,
      ),
    ];
  }

  /// v1 迁移：从散落的 SharedPreferences key 合并到统一聚合存储
  ///
  /// 伪代码思路：
  ///   1. 读取旧的 'wisdom_skills' / 'wisdom_skill_points' / 'wisdom_tasks' key
  ///   2. 如果都不存在 -> 跳过（全新安装无需迁移）
  ///   3. 反序列化各数组 -> 组装为 WisdomDto JSON -> 写入新的 'wisdom_data' key
  ///   4. 读取旧的 'health_data_map' -> 写入新的 'health_data' key
  ///   5. 不删除旧 key（保留可恢复信息，后续版本可清理）
  static Future<void> _migrateToV1(LocalStoreDriver driver) async {
    debugPrint('🔧 [Migration v1] 开始迁移散落数据到统一聚合...');

    // 迁移 Wisdom 数据
    final skillsJson = await driver.getString('wisdom_skills');
    final pointsJson = await driver.getString('wisdom_skill_points');
    final tasksJson = await driver.getString('wisdom_tasks');

    if (skillsJson != null || pointsJson != null || tasksJson != null) {
      final wisdomMap = <String, dynamic>{
        'skills': skillsJson != null ? json.decode(skillsJson) : [],
        'skillPoints': pointsJson != null ? json.decode(pointsJson) : [],
        'tasks': tasksJson != null ? json.decode(tasksJson) : [],
      };
      await driver.setString(WisdomRepositoryImpl.storageKey, json.encode(wisdomMap));
      debugPrint('🔧 [Migration v1] Wisdom 数据迁移完成');
    }

    // 迁移 Health 数据
    final healthJson = await driver.getString('health_data_map');
    if (healthJson != null) {
      await driver.setString(HealthRepositoryImpl.storageKey, healthJson);
      debugPrint('🔧 [Migration v1] Health 数据迁移完成');
    }

    debugPrint('🔧 [Migration v1] 迁移完成');
  }

  /// v2 迁移：引入 MainQuest 模块
  ///
  /// 伪代码思路：
  ///   MainQuest 是全新模块，无旧数据需要迁移。
  ///   此步骤仅作为版本标记，确保迁移链连续性。
  ///   如果未来有其他 v2 变更（如字段重命名），在此处添加逻辑。
  static Future<void> _migrateToV2(LocalStoreDriver driver) async {
    debugPrint('🔧 [Migration v2] 新增 MainQuest 模块，无旧数据需迁移');
  }

  /// v3 迁移：移除独立 MainQuest 模块，将其数据合并到 Wisdom/Skill 体系
  ///
  /// 伪代码思路：
  ///   1. 读取 'main_quest_data' key 中的 MainQuest 数据
  ///   2. 如果无数据 -> 跳过（用户未使用过 MainQuest 功能）
  ///   3. 读取现有 'wisdom_data' key 中的 Wisdom 数据
  ///   4. 将每条 MainQuest 转换为 SkillDto 格式追加到 skills 数组
  ///      （deadline 直接映射，maxCount 映射为 maxXp，currentCount 映射为 currentXp）
  ///   5. 写回 'wisdom_data'
  ///   6. 不删除 'main_quest_data' key（保留可恢复信息）
  static Future<void> _migrateToV3(LocalStoreDriver driver) async {
    debugPrint('🔧 [Migration v3] 合并 MainQuest 数据到 Wisdom/Skill 体系...');

    final mqJsonStr = await driver.getString('main_quest_data');
    if (mqJsonStr == null) {
      debugPrint('🔧 [Migration v3] 无 MainQuest 旧数据，跳过');
      return;
    }

    try {
      final mqMap = json.decode(mqJsonStr) as Map<String, dynamic>;
      final mqQuests = mqMap['quests'] as List<dynamic>? ?? [];

      if (mqQuests.isEmpty) {
        debugPrint('🔧 [Migration v3] MainQuest 列表为空，跳过');
        return;
      }

      // 读取现有 Wisdom 数据
      final wisdomJsonStr = await driver.getString(WisdomRepositoryImpl.storageKey);
      Map<String, dynamic> wisdomMap;
      if (wisdomJsonStr != null) {
        wisdomMap = json.decode(wisdomJsonStr) as Map<String, dynamic>;
      } else {
        wisdomMap = {'skills': [], 'skillPoints': [], 'tasks': []};
      }

      final existingSkills = (wisdomMap['skills'] as List<dynamic>?) ?? [];

      // 将 MainQuest 转换为 SkillDto 格式并追加
      for (final mq in mqQuests) {
        final mqData = mq as Map<String, dynamic>;
        final convertedSkill = {
          'id': mqData['id'],
          'name': mqData['name'],
          'level': 1,
          'currentXp': mqData['currentCount'] ?? 0,
          'maxXp': mqData['maxCount'] ?? 100,
          'iconCodePoint': mqData['iconCodePoint'] ?? 0xe894,
          'deadline': mqData['deadline'],
          'createdAt': mqData['createdAt'],
        };
        existingSkills.add(convertedSkill);
      }

      wisdomMap['skills'] = existingSkills;
      await driver.setString(WisdomRepositoryImpl.storageKey, json.encode(wisdomMap));

      debugPrint('🔧 [Migration v3] 已将 ${mqQuests.length} 条 MainQuest 合并到 Wisdom');
    } catch (e) {
      debugPrint('❌ [Migration v3] 合并失败: $e');
      // 不抛出异常，避免因旧数据格式问题阻塞启动
    }
  }

  /// v4 迁移：引入 Shop 模块（商品 + 奖池）
  ///
  /// 伪代码思路：
  ///   Shop 是全新模块，无旧数据需要迁移。
  ///   此步骤仅作为版本标记，确保迁移链连续性。
  ///   如果未来有其他 v4 变更，在此处添加逻辑。
  static Future<void> _migrateToV4(LocalStoreDriver driver) async {
    debugPrint('🔧 [Migration v4] 新增 Shop 模块，无旧数据需迁移');
  }
}

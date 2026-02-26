import 'package:flutter/foundation.dart';
import 'package:nowgame/Dto/WisdomDto.dart';
import 'package:nowgame/Model/SkillData.dart';
import 'package:nowgame/Repository/WisdomRepository.dart';

/// 技能数据服务
///
/// 定位：Wisdom 领域的技能卡业务层，负责技能卡数据的业务规则与状态管理。
/// 职责：
///   - 管理内存中的技能卡列表状态
///   - 提供添加、删除、经验增加等业务操作
///   - 处理经验溢出时的自动升级逻辑
///   - 每次数据变更后通过 WisdomRepository 持久化（协调保存整个 Wisdom 聚合）
/// 不负责：底层存储实现、DTO 格式管理、UI 展示、技能点/任务管理。
/// 上游依赖方：UI 层（WisdomWidget）、SkillPointService（经验上传时调用）。
/// 下游依赖方：WisdomRepository（仓储接口）。
///
/// 依赖注入：通过 [initialize] 注入 WisdomRepository，替代原来直接操作 SharedPreferences。
/// 协调保存：因为 Wisdom 数据（技能卡+技能点+任务）存储在同一个聚合中，
///   保存时需要获取完整快照。通过 [onSaveRequested] 回调收集所有子服务数据。
class SkillService extends ChangeNotifier {
  /// 单例实例
  static SkillService? _instance;

  /// 获取单例
  factory SkillService() {
    if (_instance == null) {
      throw StateError('SkillService 未初始化，请先调用 SkillService.initialize()');
    }
    return _instance!;
  }

  /// 初始化单例并注入依赖
  static void initialize(WisdomRepository repository) {
    _instance ??= SkillService._internal(repository);
  }

  /// 重置单例（仅用于测试）
  @visibleForTesting
  static void reset() {
    _instance = null;
  }

  /// 技能列表（内部状态）
  List<SkillData> _skills = [];

  /// 协调保存回调：由 Bootstrap 注入，用于收集完整 Wisdom 快照后保存
  ///
  /// 伪代码思路：
  ///   当技能卡数据变更时，调用此回调 -> 回调内部收集所有子服务数据
  ///   -> 组装完整 WisdomDto -> 通过 repository 保存
  Future<void> Function()? onSaveRequested;

  // ignore: avoid_unused_constructor_parameters
  SkillService._internal(WisdomRepository _);

  /// 获取技能列表（只读）
  List<SkillData> get skills => List.unmodifiable(_skills);

  /// 从 DTO 加载数据（由 Bootstrap 调用）
  ///
  /// 伪代码思路：
  ///   接收 WisdomDto 中的 skills 列表 -> 转换为领域模型列表 -> 存入内存
  void loadFromDto(List<SkillDto> skillDtos) {
    _skills = skillDtos.map(_dtoToDomain).toList();
  }

  /// 导出当前数据为 DTO 列表（用于协调保存）
  List<SkillDto> toDto() {
    return _skills.map(_domainToDto).toList();
  }

  /// 添加技能
  Future<void> addSkill({
    required String name,
    int maxXp = 100,
    int iconCodePoint = 0xe894,
  }) async {
    final skill = SkillData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      maxXp: maxXp,
      iconCodePoint: iconCodePoint,
      createdAt: DateTime.now(),
    );
    _skills.add(skill);
    await _requestSave();
    notifyListeners();
  }

  /// 删除技能
  Future<void> removeSkill(String id) async {
    _skills.removeWhere((s) => s.id == id);
    await _requestSave();
    notifyListeners();
  }

  /// 增加经验值（任务完成时调用）
  /// 经验满时自动升级并重置经验
  Future<void> addExperience(String skillId, int xp) async {
    final index = _skills.indexWhere((s) => s.id == skillId);
    if (index == -1) return;

    var skill = _skills[index];
    var newXp = skill.currentXp + xp;
    var newLevel = skill.level;

    // 经验溢出时升级
    while (newXp >= skill.maxXp) {
      newXp -= skill.maxXp;
      newLevel++;
    }

    _skills[index] = skill.copyWith(
      currentXp: newXp,
      level: newLevel,
    );

    await _requestSave();
    notifyListeners();
  }

  /// 根据 ID 获取技能
  SkillData? getSkillById(String id) {
    try {
      return _skills.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 请求协调保存
  Future<void> _requestSave() async {
    if (onSaveRequested != null) {
      await onSaveRequested!();
    }
  }

  /// DTO -> Domain 转换
  SkillData _dtoToDomain(SkillDto dto) {
    return SkillData(
      id: dto.id,
      name: dto.name,
      level: dto.level,
      currentXp: dto.currentXp,
      maxXp: dto.maxXp,
      iconCodePoint: dto.iconCodePoint,
      createdAt: DateTime.parse(dto.createdAt),
    );
  }

  /// Domain -> DTO 转换
  SkillDto _domainToDto(SkillData domain) {
    return SkillDto(
      id: domain.id,
      name: domain.name,
      level: domain.level,
      currentXp: domain.currentXp,
      maxXp: domain.maxXp,
      iconCodePoint: domain.iconCodePoint,
      createdAt: domain.createdAt.toIso8601String(),
    );
  }
}

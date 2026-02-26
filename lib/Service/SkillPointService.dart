import 'package:flutter/foundation.dart';
import 'package:nowgame/Dto/WisdomDto.dart';
import 'package:nowgame/Model/SkillPointData.dart';
import 'package:nowgame/Service/SkillService.dart';

/// 技能点数据服务
///
/// 定位：Wisdom 领域的技能点业务层，负责技能点数据的业务规则与状态管理。
/// 职责：
///   - 管理内存中的技能点列表状态
///   - 提供添加、删除、经验增加等业务操作
///   - 处理经验满时向父级技能卡传递经验的联动逻辑
///   - 每次数据变更后通过协调保存回调持久化
/// 不负责：底层存储实现、DTO 格式管理、UI 展示、任务管理。
/// 上游依赖方：UI 层（WisdomDetailDialog）、TaskService（任务完成时调用）。
/// 下游依赖方：SkillService（经验上传）。
///
/// 协调保存：与 SkillService 共享同一个 Wisdom 聚合存储，
///   通过 [onSaveRequested] 回调触发整体保存。
class SkillPointService extends ChangeNotifier {
  /// 单例实例
  static SkillPointService? _instance;

  /// 获取单例
  factory SkillPointService() {
    if (_instance == null) {
      throw StateError('SkillPointService 未初始化，请先调用 SkillPointService.initialize()');
    }
    return _instance!;
  }

  /// 初始化单例
  static void initialize() {
    _instance ??= SkillPointService._internal();
  }

  /// 重置单例（仅用于测试）
  @visibleForTesting
  static void reset() {
    _instance = null;
  }

  /// 技能点列表（内部状态）
  List<SkillPointData> _points = [];

  /// 协调保存回调
  Future<void> Function()? onSaveRequested;

  SkillPointService._internal();

  /// 获取所有技能点列表（只读）
  List<SkillPointData> get points => List.unmodifiable(_points);

  /// 从 DTO 加载数据（由 Bootstrap 调用）
  void loadFromDto(List<SkillPointDto> pointDtos) {
    _points = pointDtos.map(_dtoToDomain).toList();
  }

  /// 导出当前数据为 DTO 列表（用于协调保存）
  List<SkillPointDto> toDto() {
    return _points.map(_domainToDto).toList();
  }

  /// 获取某技能卡下属的技能点列表
  List<SkillPointData> getPointsBySkillId(String skillId) {
    return _points.where((p) => p.skillId == skillId).toList();
  }

  /// 添加技能点
  Future<void> addPoint({
    required String name,
    required String skillId,
    int maxXp = 100,
    int iconCodePoint = 0xe838,
  }) async {
    final point = SkillPointData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      skillId: skillId,
      maxXp: maxXp,
      iconCodePoint: iconCodePoint,
      createdAt: DateTime.now(),
    );
    _points.add(point);
    await _requestSave();
    notifyListeners();
  }

  /// 删除技能点
  Future<void> removePoint(String id) async {
    _points.removeWhere((p) => p.id == id);
    await _requestSave();
    notifyListeners();
  }

  /// 增加经验值（任务完成时调用）
  /// 经验满时不升级技能点自身，而是重置经验值并给所属技能卡增加经验（触发技能卡升级）
  Future<void> addExperience(String pointId, int xp) async {
    final index = _points.indexWhere((p) => p.id == pointId);
    if (index == -1) return;

    var point = _points[index];
    var newXp = point.currentXp + xp;

    // 经验溢出时：重置经验并给父级技能卡增加经验
    while (newXp >= point.maxXp) {
      newXp -= point.maxXp;
      // 技能点经验满 -> 给所属技能卡增加经验，由 SkillService 处理技能卡升级
      await SkillService().addExperience(point.skillId, point.maxXp);
    }

    _points[index] = point.copyWith(currentXp: newXp);

    await _requestSave();
    notifyListeners();
  }

  /// 根据 ID 获取技能点
  SkillPointData? getPointById(String id) {
    try {
      return _points.firstWhere((p) => p.id == id);
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
  SkillPointData _dtoToDomain(SkillPointDto dto) {
    return SkillPointData(
      id: dto.id,
      name: dto.name,
      skillId: dto.skillId,
      level: dto.level,
      currentXp: dto.currentXp,
      maxXp: dto.maxXp,
      iconCodePoint: dto.iconCodePoint,
      createdAt: DateTime.parse(dto.createdAt),
    );
  }

  /// Domain -> DTO 转换
  SkillPointDto _domainToDto(SkillPointData domain) {
    return SkillPointDto(
      id: domain.id,
      name: domain.name,
      skillId: domain.skillId,
      level: domain.level,
      currentXp: domain.currentXp,
      maxXp: domain.maxXp,
      iconCodePoint: domain.iconCodePoint,
      createdAt: domain.createdAt.toIso8601String(),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:nowgame/Dto/WisdomDto.dart';
import 'package:nowgame/Model/TaskData.dart';
import 'package:nowgame/Service/SkillPointService.dart';

/// 任务数据服务
///
/// 定位：Wisdom 领域的任务业务层，负责任务数据的业务规则与状态管理。
/// 职责：
///   - 管理内存中的任务列表状态
///   - 提供添加、删除、进度增减等业务操作
///   - 处理任务完成时向关联技能点传递经验的联动逻辑
///   - 每次数据变更后通过协调保存回调持久化
/// 不负责：底层存储实现、DTO 格式管理、UI 展示、技能卡/技能点管理。
/// 上游依赖方：UI 层（TaskCard）。
/// 下游依赖方：SkillPointService（经验传递）。
///
/// 协调保存：与 SkillService、SkillPointService 共享同一个 Wisdom 聚合存储。
class TaskService extends ChangeNotifier {
  /// 每次完成任务给技能增加的经验值
  static const int xpPerCompletion = 5;

  /// 单例实例
  static TaskService? _instance;

  /// 获取单例
  factory TaskService() {
    if (_instance == null) {
      throw StateError('TaskService 未初始化，请先调用 TaskService.initialize()');
    }
    return _instance!;
  }

  /// 初始化单例
  static void initialize() {
    _instance ??= TaskService._internal();
  }

  /// 重置单例（仅用于测试）
  @visibleForTesting
  static void reset() {
    _instance = null;
  }

  /// 技能点服务引用（用于更新经验值）
  final SkillPointService _skillPointService = SkillPointService();

  /// 任务列表（内部状态）
  List<TaskData> _tasks = [];

  /// 协调保存回调
  Future<void> Function()? onSaveRequested;

  TaskService._internal();

  /// 获取任务列表（只读）
  List<TaskData> get tasks => List.unmodifiable(_tasks);

  /// 从 DTO 加载数据（由 Bootstrap 调用）
  void loadFromDto(List<TaskDto> taskDtos) {
    _tasks = taskDtos.map(_dtoToDomain).toList();
  }

  /// 导出当前数据为 DTO 列表（用于协调保存）
  List<TaskDto> toDto() {
    return _tasks.map(_domainToDto).toList();
  }

  /// 添加任务
  /// skillId 指向技能点（SkillPointData）的 ID
  Future<void> addTask({
    required String name,
    required String skillId,
    required String skillName,
    int maxCount = 10,
    int iconCodePoint = 0xe876,
  }) async {
    final task = TaskData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      skillId: skillId,
      skillName: skillName,
      maxCount: maxCount,
      iconCodePoint: iconCodePoint,
      createdAt: DateTime.now(),
    );
    _tasks.add(task);
    await _requestSave();
    notifyListeners();
  }

  /// 删除任务
  Future<void> removeTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await _requestSave();
    notifyListeners();
  }

  /// 增加任务完成次数
  /// 只在任务进度满（刚好完成）时一次性给关联技能点增加经验
  Future<void> incrementCount(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _tasks[index];
    if (task.isCompleted) return;

    final updatedTask = task.copyWith(currentCount: task.currentCount + 1);
    _tasks[index] = updatedTask;
    await _requestSave();

    // 仅在任务刚好完成时一次性增加经验
    if (updatedTask.isCompleted) {
      await _skillPointService.addExperience(task.skillId, xpPerCompletion);
    }

    notifyListeners();
  }

  /// 减少任务完成次数（不低于 0）
  Future<void> decrementCount(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _tasks[index];
    if (task.currentCount <= 0) return;

    _tasks[index] = task.copyWith(currentCount: task.currentCount - 1);
    await _requestSave();
    notifyListeners();
  }

  /// 获取指定技能点的关联任务
  List<TaskData> getTasksBySkillId(String skillPointId) {
    return _tasks.where((t) => t.skillId == skillPointId).toList();
  }

  /// 请求协调保存
  Future<void> _requestSave() async {
    if (onSaveRequested != null) {
      await onSaveRequested!();
    }
  }

  /// DTO -> Domain 转换
  TaskData _dtoToDomain(TaskDto dto) {
    return TaskData(
      id: dto.id,
      name: dto.name,
      skillId: dto.skillId,
      skillName: dto.skillName,
      maxCount: dto.maxCount,
      currentCount: dto.currentCount,
      iconCodePoint: dto.iconCodePoint,
      createdAt: DateTime.parse(dto.createdAt),
    );
  }

  /// Domain -> DTO 转换
  TaskDto _domainToDto(TaskData domain) {
    return TaskDto(
      id: domain.id,
      name: domain.name,
      skillId: domain.skillId,
      skillName: domain.skillName,
      maxCount: domain.maxCount,
      currentCount: domain.currentCount,
      iconCodePoint: domain.iconCodePoint,
      createdAt: domain.createdAt.toIso8601String(),
    );
  }
}

import 'dart:math';
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
///   - 延迟保存：增减进度时只改内存不持久化；离开页面/退出时调用 commitProgress 批量提交
///   - 提交时取 max(currentCount, savedCount)，保证存档进度只增不减
/// 不负责：底层存储实现、DTO 格式管理、UI 展示、技能卡/技能点管理。
/// 上游依赖方：UI 层（TaskCard）。
/// 下游依赖方：SkillPointService（经验传递）。
///
/// 协调保存：与 SkillService、SkillPointService 共享同一个 Wisdom 聚合存储。
///
/// 延迟保存设计说明：
///   玩家在主页操作任务进度时，可自由增减（即使满了也能减少），
///   但只有在离开主页或退出应用时才会触发 commitProgress，
///   提交时 currentCount 会与 savedCount（上次存档基线）取 max，
///   确保存档进度永远不会倒退。
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
  ///
  /// 伪代码思路：
  ///   接收 DTO 列表 -> 逐个转换为 Domain Model
  ///   -> savedCount 初始化为与 currentCount 相同（加载的数据即为存档基线）
  void loadFromDto(List<TaskDto> taskDtos) {
    _tasks = taskDtos.map(_dtoToDomain).toList();
  }

  /// 导出当前数据为 DTO 列表（用于协调保存）
  ///
  /// 注意：此方法直接导出内存中的 currentCount，
  /// 保存约束（只增不减）由 commitProgress 在调用此方法前处理。
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
    // 新增任务需要立即持久化（否则退出后任务丢失）
    await _requestSave();
    notifyListeners();
  }

  /// 删除任务
  Future<void> removeTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    // 删除需要立即持久化
    await _requestSave();
    notifyListeners();
  }

  /// 增加任务完成次数（仅修改内存，不持久化）
  ///
  /// 伪代码思路：
  ///   按 id 查找任务 -> 已达到 maxCount 则跳过
  ///   -> currentCount + 1 -> 替换内存实例 -> 通知 UI
  ///   不触发持久化，等待 commitProgress 统一提交
  void incrementCount(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _tasks[index];
    if (task.currentCount >= task.maxCount) return;

    _tasks[index] = task.copyWith(currentCount: task.currentCount + 1);
    notifyListeners();
  }

  /// 减少任务完成次数（仅修改内存，不持久化）
  ///
  /// 伪代码思路：
  ///   按 id 查找任务 -> 当前次数 <= savedCount 则跳过（不能低于已存档基线）
  ///   -> currentCount - 1 -> 替换内存实例 -> 通知 UI
  ///   允许从已满状态减少（玩家可自由调整临时进度）
  ///   不触发持久化，等待 commitProgress 统一提交
  void decrementCount(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _tasks[index];
    // 不能减到低于已存档的进度基线
    if (task.currentCount <= task.savedCount) return;

    _tasks[index] = task.copyWith(currentCount: task.currentCount - 1);
    notifyListeners();
  }

  /// 提交进度并持久化（离开页面/退出应用时调用）
  ///
  /// 伪代码思路：
  ///   遍历所有任务 -> 对每个任务取 max(currentCount, savedCount) 作为最终存档值
  ///   -> 更新 currentCount 和 savedCount 为该值
  ///   -> 检查是否有任务从"未完成"变为"完成"，触发经验奖励
  ///   -> 触发协调保存持久化 -> 通知 UI
  ///
  /// 这保证了存档进度只增不减：即使玩家在内存中把进度减少了，
  /// 提交时也会恢复到至少 savedCount 的水平。
  Future<void> commitProgress() async {
    bool changed = false;

    for (int i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      // 取 max(currentCount, savedCount) 确保只增不减
      final committedCount = max(task.currentCount, task.savedCount);

      if (committedCount != task.savedCount) {
        final wasCompleted = task.savedCount >= task.maxCount;
        _tasks[i] = task.copyWith(
          currentCount: committedCount,
          savedCount: committedCount,
        );

        // 仅在存档状态从"未完成"变为"完成"时一次性增加经验
        final nowCompleted = committedCount >= task.maxCount;
        if (!wasCompleted && nowCompleted) {
          await _skillPointService.addExperience(task.skillId, xpPerCompletion);
        }

        changed = true;
      } else if (task.currentCount != committedCount) {
        // currentCount < savedCount 的情况：恢复到 savedCount
        _tasks[i] = task.copyWith(
          currentCount: committedCount,
          savedCount: committedCount,
        );
        changed = true;
      }
    }

    if (changed) {
      await _requestSave();
      notifyListeners();
    }
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
  ///
  /// 加载时 savedCount 初始化为与 currentCount 相同，
  /// 因为从存储恢复的值就是已确认的存档基线。
  TaskData _dtoToDomain(TaskDto dto) {
    return TaskData(
      id: dto.id,
      name: dto.name,
      skillId: dto.skillId,
      skillName: dto.skillName,
      maxCount: dto.maxCount,
      currentCount: dto.currentCount,
      savedCount: dto.currentCount,
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

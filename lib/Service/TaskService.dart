import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowgame/Model/TaskData.dart';
import 'package:nowgame/Service/SkillPointService.dart';

/// 任务数据服务
/// 负责任务数据的增删改查与持久化
/// 任务完成时自动更新关联技能点的经验值
class TaskService extends ChangeNotifier {
  static const String _storageKey = 'wisdom_tasks';

  /// 每次完成任务给技能增加的经验值
  static const int xpPerCompletion = 5;

  /// 单例实例
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  /// 技能点服务引用（用于更新经验值）
  final SkillPointService _skillPointService = SkillPointService();

  /// 任务列表（内部状态）
  List<TaskData> _tasks = [];

  /// 是否已初始化
  bool _initialized = false;

  /// 获取任务列表（只读）
  List<TaskData> get tasks => List.unmodifiable(_tasks);

  /// 初始化：从持久化存储加载数据
  Future<void> init() async {
    if (_initialized) return;
    await _loadFromStorage();
    _initialized = true;
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
    await _saveToStorage();
    notifyListeners();
  }

  /// 删除任务
  Future<void> removeTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await _saveToStorage();
    notifyListeners();
  }

  /// 增加任务完成次数
  /// 同时更新关联技能的经验值
  Future<void> incrementCount(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _tasks[index];
    if (task.isCompleted) return;

    _tasks[index] = task.copyWith(currentCount: task.currentCount + 1);
    await _saveToStorage();

    // 更新关联技能点经验值
    await _skillPointService.addExperience(task.skillId, xpPerCompletion);

    notifyListeners();
  }

  /// 获取指定技能点的关联任务
  List<TaskData> getTasksBySkillId(String skillPointId) {
    return _tasks.where((t) => t.skillId == skillPointId).toList();
  }

  /// 从持久化存储加载
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr == null) return;

      final List<dynamic> jsonList = json.decode(jsonStr);
      _tasks = jsonList.map((j) => TaskData.fromJson(j)).toList();
    } catch (e) {
      debugPrint('TaskService: 加载数据失败 - $e');
    }
  }

  /// 保存到持久化存储
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(_tasks.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('TaskService: 保存数据失败 - $e');
    }
  }
}

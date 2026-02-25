import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowgame/Model/SkillPointData.dart';

/// 技能点数据服务
/// 负责技能点数据的增删改查与持久化
/// 使用 ChangeNotifier 支持响应式 UI 更新
class SkillPointService extends ChangeNotifier {
  static const String _storageKey = 'wisdom_skill_points';

  /// 单例实例
  static final SkillPointService _instance = SkillPointService._internal();
  factory SkillPointService() => _instance;
  SkillPointService._internal();

  /// 技能点列表（内部状态）
  List<SkillPointData> _points = [];

  /// 是否已初始化
  bool _initialized = false;

  /// 获取所有技能点列表（只读）
  List<SkillPointData> get points => List.unmodifiable(_points);

  /// 初始化：从持久化存储加载数据
  Future<void> init() async {
    if (_initialized) return;
    await _loadFromStorage();
    _initialized = true;
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
    await _saveToStorage();
    notifyListeners();
  }

  /// 删除技能点
  Future<void> removePoint(String id) async {
    _points.removeWhere((p) => p.id == id);
    await _saveToStorage();
    notifyListeners();
  }

  /// 增加经验值（任务完成时调用）
  /// 经验满时自动升级并重置经验
  Future<void> addExperience(String pointId, int xp) async {
    final index = _points.indexWhere((p) => p.id == pointId);
    if (index == -1) return;

    var point = _points[index];
    var newXp = point.currentXp + xp;
    var newLevel = point.level;

    // 经验溢出时升级
    while (newXp >= point.maxXp) {
      newXp -= point.maxXp;
      newLevel++;
    }

    _points[index] = point.copyWith(
      currentXp: newXp,
      level: newLevel,
    );

    await _saveToStorage();
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

  /// 从持久化存储加载
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr == null) return;

      final List<dynamic> jsonList = json.decode(jsonStr);
      _points = jsonList.map((j) => SkillPointData.fromJson(j)).toList();
    } catch (e) {
      debugPrint('SkillPointService: 加载数据失败 - $e');
    }
  }

  /// 保存到持久化存储
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(_points.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('SkillPointService: 保存数据失败 - $e');
    }
  }
}

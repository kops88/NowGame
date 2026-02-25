import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowgame/Model/SkillData.dart';

/// 技能数据服务
/// 负责技能数据的增删改查与持久化
/// 使用 ChangeNotifier 支持响应式 UI 更新
class SkillService extends ChangeNotifier {
  static const String _storageKey = 'wisdom_skills';

  /// 单例实例
  static final SkillService _instance = SkillService._internal();
  factory SkillService() => _instance;
  SkillService._internal();

  /// 技能列表（内部状态）
  List<SkillData> _skills = [];

  /// 是否已初始化
  bool _initialized = false;

  /// 获取技能列表（只读）
  List<SkillData> get skills => List.unmodifiable(_skills);

  /// 初始化：从持久化存储加载数据
  Future<void> init() async {
    if (_initialized) return;
    await _loadFromStorage();
    _initialized = true;
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
    await _saveToStorage();
    notifyListeners();
  }

  /// 删除技能
  Future<void> removeSkill(String id) async {
    _skills.removeWhere((s) => s.id == id);
    await _saveToStorage();
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

    await _saveToStorage();
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

  /// 从持久化存储加载
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr == null) return;

      final List<dynamic> jsonList = json.decode(jsonStr);
      _skills = jsonList.map((j) => SkillData.fromJson(j)).toList();
    } catch (e) {
      debugPrint('SkillService: 加载数据失败 - $e');
    }
  }

  /// 保存到持久化存储
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(_skills.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('SkillService: 保存数据失败 - $e');
    }
  }
}

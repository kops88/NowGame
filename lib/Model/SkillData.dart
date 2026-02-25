import 'package:flutter/material.dart';

/// 技能数据模型
/// 与 UI 展示解耦，支持序列化/反序列化
class SkillData {
  /// 唯一标识
  final String id;

  /// 技能名称
  final String name;

  /// 技能等级
  final int level;

  /// 当前经验值
  final int currentXp;

  /// 经验值上限
  final int maxXp;

  /// 图标的 codePoint（用于序列化 IconData）
  final int iconCodePoint;

  /// 创建时间
  final DateTime createdAt;

  const SkillData({
    required this.id,
    required this.name,
    this.level = 1,
    this.currentXp = 0,
    this.maxXp = 100,
    this.iconCodePoint = 0xe894, // Icons.star 的 codePoint
    required this.createdAt,
  });

  /// 获取 IconData
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  /// 经验值进度 (0.0 - 1.0)
  double get progress => maxXp > 0 ? (currentXp / maxXp).clamp(0.0, 1.0) : 0.0;

  /// 从 JSON 反序列化
  factory SkillData.fromJson(Map<String, dynamic> json) {
    return SkillData(
      id: json['id'] as String,
      name: json['name'] as String,
      level: json['level'] as int? ?? 1,
      currentXp: json['currentXp'] as int? ?? 0,
      maxXp: json['maxXp'] as int? ?? 100,
      iconCodePoint: json['iconCodePoint'] as int? ?? 0xe894,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'currentXp': currentXp,
      'maxXp': maxXp,
      'iconCodePoint': iconCodePoint,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 创建副本并修改部分字段
  SkillData copyWith({
    String? id,
    String? name,
    int? level,
    int? currentXp,
    int? maxXp,
    int? iconCodePoint,
    DateTime? createdAt,
  }) {
    return SkillData(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      maxXp: maxXp ?? this.maxXp,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

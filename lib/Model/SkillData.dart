import 'package:flutter/material.dart';

/// 技能数据模型（即"主线任务"一级卡片数据）
/// 与 UI 展示解耦，支持序列化/反序列化
/// 支持"限时任务"（有 deadline）和"永久任务"（deadline 为 null）两种模式
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

  /// 截止日期（可空，null 表示永久任务，有值表示限时任务）
  final DateTime? deadline;

  /// 创建时间
  final DateTime createdAt;

  const SkillData({
    required this.id,
    required this.name,
    this.level = 1,
    this.currentXp = 0,
    this.maxXp = 100,
    this.iconCodePoint = 0xe894, // Icons.star 的 codePoint
    this.deadline,
    required this.createdAt,
  });

  /// 获取 IconData
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  /// 经验值进度 (0.0 - 1.0)
  double get progress => maxXp > 0 ? (currentXp / maxXp).clamp(0.0, 1.0) : 0.0;

  /// 是否为限时任务
  bool get isTimeLimited => deadline != null;

  /// 距离截止日期的剩余天数
  ///
  /// 返回 null 表示永久任务（无截止日期）；
  /// 返回负数表示已逾期；
  /// 返回 0 表示今天截止。
  ///
  /// 伪代码思路：
  ///   无 deadline -> 返回 null
  ///   计算 deadline 日期与今天的天数差 -> 返回整数天数
  int? get remainingDays {
    if (deadline == null) return null;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final deadlineStart = DateTime(deadline!.year, deadline!.month, deadline!.day);
    return deadlineStart.difference(todayStart).inDays;
  }

  /// 格式化剩余天数为展示文本
  ///
  /// 伪代码思路：
  ///   永久任务 -> "永久"
  ///   已逾期 -> "已逾期 X 天"
  ///   今天截止 -> "今天截止"
  ///   未来 -> "还剩 X 天"
  String get remainingDaysText {
    final days = remainingDays;
    if (days == null) return '永久';
    if (days < 0) return '已逾期 ${-days} 天';
    if (days == 0) return '今天截止';
    return '还剩 $days 天';
  }

  /// 时间标签颜色策略
  ///
  /// 伪代码思路：
  ///   永久任务 -> 蓝灰色调
  ///   > 7天 -> 蓝色调
  ///   ≤ 7天 -> 橙色调
  ///   ≤ 2天或已逾期 -> 红色调
  Color get deadlineColor {
    final days = remainingDays;
    if (days == null) return const Color(0xFF78909C); // 蓝灰（永久）
    if (days < 0 || days <= 2) return Colors.redAccent;
    if (days <= 7) return Colors.orange;
    return const Color(0xFF90CAF9); // 蓝色
  }

  /// 从 JSON 反序列化
  factory SkillData.fromJson(Map<String, dynamic> json) {
    return SkillData(
      id: json['id'] as String,
      name: json['name'] as String,
      level: json['level'] as int? ?? 1,
      currentXp: json['currentXp'] as int? ?? 0,
      maxXp: json['maxXp'] as int? ?? 100,
      iconCodePoint: json['iconCodePoint'] as int? ?? 0xe894,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
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
      'deadline': deadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 创建副本并修改部分字段
  /// 注意：要清除 deadline 请使用 clearDeadline 参数
  SkillData copyWith({
    String? id,
    String? name,
    int? level,
    int? currentXp,
    int? maxXp,
    int? iconCodePoint,
    DateTime? deadline,
    bool clearDeadline = false,
    DateTime? createdAt,
  }) {
    return SkillData(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      maxXp: maxXp ?? this.maxXp,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 任务数据模型
/// 关联特定技能点（SkillPointData），任务完成时可增加技能点经验值
class TaskData {
  /// 唯一标识
  final String id;

  /// 任务名称
  final String name;

  /// 关联的技能点 ID（指向 SkillPointData）
  final String skillId;

  /// 关联的技能点名称（用于展示）
  final String skillName;

  /// 最大次数
  final int maxCount;

  /// 当前完成次数
  final int currentCount;

  /// 图标的 codePoint
  final int iconCodePoint;

  /// 创建时间
  final DateTime createdAt;

  const TaskData({
    required this.id,
    required this.name,
    required this.skillId,
    required this.skillName,
    this.maxCount = 10,
    this.currentCount = 0,
    this.iconCodePoint = 0xe876, // Icons.check_circle
    required this.createdAt,
  });

  /// 是否已完成
  bool get isCompleted => currentCount >= maxCount;

  /// 进度 (0.0 - 1.0)
  double get progress => maxCount > 0 ? (currentCount / maxCount).clamp(0.0, 1.0) : 0.0;

  /// 从 JSON 反序列化
  factory TaskData.fromJson(Map<String, dynamic> json) {
    return TaskData(
      id: json['id'] as String,
      name: json['name'] as String,
      skillId: json['skillId'] as String,
      skillName: json['skillName'] as String? ?? '',
      maxCount: json['maxCount'] as int? ?? 10,
      currentCount: json['currentCount'] as int? ?? 0,
      iconCodePoint: json['iconCodePoint'] as int? ?? 0xe876,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'skillId': skillId,
      'skillName': skillName,
      'maxCount': maxCount,
      'currentCount': currentCount,
      'iconCodePoint': iconCodePoint,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 创建副本并修改部分字段
  TaskData copyWith({
    String? id,
    String? name,
    String? skillId,
    String? skillName,
    int? maxCount,
    int? currentCount,
    int? iconCodePoint,
    DateTime? createdAt,
  }) {
    return TaskData(
      id: id ?? this.id,
      name: name ?? this.name,
      skillId: skillId ?? this.skillId,
      skillName: skillName ?? this.skillName,
      maxCount: maxCount ?? this.maxCount,
      currentCount: currentCount ?? this.currentCount,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

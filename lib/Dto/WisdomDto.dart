/// Wisdom 领域数据传输对象（DTO）
///
/// 定位：持久化 DTO 层，专用于 Wisdom 相关数据的序列化/反序列化与版本迁移。
/// 职责：将 Wisdom 领域的全部数据（技能卡、技能点、任务）打包为一个可序列化结构。
/// 不负责：业务逻辑运算、UI 展示。
/// 在哪一层使用：Repository 实现层（Domain <-> DTO 映射时使用）。
/// 与版本迁移的关系：受 schemaVersion 管理，字段变更通过 MigrationStep 处理。
///
/// 包含三个子 DTO：SkillDto、SkillPointDto、TaskDto，
/// 与领域模型（SkillData、SkillPointData、TaskData）一一对应但职责不同：
///   - DTO 专注序列化格式稳定性
///   - 领域模型专注业务属性和计算
class WisdomDto {
  /// 技能卡列表
  final List<SkillDto> skills;

  /// 技能点列表
  final List<SkillPointDto> skillPoints;

  /// 任务列表
  final List<TaskDto> tasks;

  const WisdomDto({
    this.skills = const [],
    this.skillPoints = const [],
    this.tasks = const [],
  });

  /// 从 JSON 反序列化
  ///
  /// 伪代码思路：
  ///   从 json map 中分别取出 skills/skillPoints/tasks 数组
  ///   -> 逐个反序列化为子 DTO -> 组装为 WisdomDto
  ///   任何子数组缺失时回退为空列表
  factory WisdomDto.fromJson(Map<String, dynamic> json) {
    return WisdomDto(
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => SkillDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      skillPoints: (json['skillPoints'] as List<dynamic>?)
              ?.map((e) => SkillPointDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((e) => TaskDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() => {
        'skills': skills.map((e) => e.toJson()).toList(),
        'skillPoints': skillPoints.map((e) => e.toJson()).toList(),
        'tasks': tasks.map((e) => e.toJson()).toList(),
      };
}

/// 技能卡 DTO
///
/// 定位：SkillData 的持久化传输对象。
/// 在哪一层使用：Repository 实现层。
/// 与版本迁移的关系：字段变更通过 MigrationStep 处理。
/// v3 新增 deadline 字段（可空），旧数据无此字段时默认 null（表示永久任务）。
class SkillDto {
  final String id;
  final String name;
  final int level;
  final int currentXp;
  final int maxXp;
  final int iconCodePoint;

  /// 截止日期（ISO8601 字符串，可空，null 表示永久任务）
  final String? deadline;

  final String createdAt;

  const SkillDto({
    required this.id,
    required this.name,
    this.level = 1,
    this.currentXp = 0,
    this.maxXp = 100,
    this.iconCodePoint = 0xe894,
    this.deadline,
    required this.createdAt,
  });

  factory SkillDto.fromJson(Map<String, dynamic> json) => SkillDto(
        id: json['id'] as String,
        name: json['name'] as String,
        level: json['level'] as int? ?? 1,
        currentXp: json['currentXp'] as int? ?? 0,
        maxXp: json['maxXp'] as int? ?? 100,
        iconCodePoint: json['iconCodePoint'] as int? ?? 0xe894,
        deadline: json['deadline'] as String?,
        createdAt: json['createdAt'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
        'currentXp': currentXp,
        'maxXp': maxXp,
        'iconCodePoint': iconCodePoint,
        'deadline': deadline,
        'createdAt': createdAt,
      };
}

/// 技能点 DTO
///
/// 定位：SkillPointData 的持久化传输对象。
/// 在哪一层使用：Repository 实现层。
/// 与版本迁移的关系：字段变更通过 MigrationStep 处理。
class SkillPointDto {
  final String id;
  final String name;
  final String skillId;
  final int level;
  final int currentXp;
  final int maxXp;
  final int iconCodePoint;
  final String createdAt;

  const SkillPointDto({
    required this.id,
    required this.name,
    required this.skillId,
    this.level = 1,
    this.currentXp = 0,
    this.maxXp = 100,
    this.iconCodePoint = 0xe838,
    required this.createdAt,
  });

  factory SkillPointDto.fromJson(Map<String, dynamic> json) => SkillPointDto(
        id: json['id'] as String,
        name: json['name'] as String,
        skillId: json['skillId'] as String,
        level: json['level'] as int? ?? 1,
        currentXp: json['currentXp'] as int? ?? 0,
        maxXp: json['maxXp'] as int? ?? 100,
        iconCodePoint: json['iconCodePoint'] as int? ?? 0xe838,
        createdAt: json['createdAt'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'skillId': skillId,
        'level': level,
        'currentXp': currentXp,
        'maxXp': maxXp,
        'iconCodePoint': iconCodePoint,
        'createdAt': createdAt,
      };
}

/// 任务 DTO
///
/// 定位：TaskData 的持久化传输对象。
/// 在哪一层使用：Repository 实现层。
/// 与版本迁移的关系：字段变更通过 MigrationStep 处理。
class TaskDto {
  final String id;
  final String name;
  final String skillId;
  final String skillName;
  final int maxCount;
  final int currentCount;
  final int iconCodePoint;
  final String createdAt;

  const TaskDto({
    required this.id,
    required this.name,
    required this.skillId,
    this.skillName = '',
    this.maxCount = 10,
    this.currentCount = 0,
    this.iconCodePoint = 0xe876,
    required this.createdAt,
  });

  factory TaskDto.fromJson(Map<String, dynamic> json) => TaskDto(
        id: json['id'] as String,
        name: json['name'] as String,
        skillId: json['skillId'] as String,
        skillName: json['skillName'] as String? ?? '',
        maxCount: json['maxCount'] as int? ?? 10,
        currentCount: json['currentCount'] as int? ?? 0,
        iconCodePoint: json['iconCodePoint'] as int? ?? 0xe876,
        createdAt: json['createdAt'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'skillId': skillId,
        'skillName': skillName,
        'maxCount': maxCount,
        'currentCount': currentCount,
        'iconCodePoint': iconCodePoint,
        'createdAt': createdAt,
      };
}

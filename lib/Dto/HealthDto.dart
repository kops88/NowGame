/// Health 领域数据传输对象（DTO）
///
/// 定位：持久化 DTO 层，专用于 Health 相关数据的序列化/反序列化与版本迁移。
/// 职责：将每日健康数据打包为可序列化结构，以日期为 key 的 Map 形式存储。
/// 不负责：健康分数计算逻辑、UI 展示、按钮重置判定。
/// 在哪一层使用：Repository 实现层（Domain <-> DTO 映射时使用）。
/// 与版本迁移的关系：受 schemaVersion 管理，字段变更通过 MigrationStep 处理。
class HealthDto {
  /// 以日期字符串（yyyy-MM-dd）为 key 的每日健康数据 map
  final Map<String, DayHealthDto> dataMap;

  const HealthDto({this.dataMap = const {}});

  /// 从 JSON 反序列化
  ///
  /// 伪代码思路：
  ///   接收一个 Map<String, dynamic> -> 遍历每个 key-value
  ///   -> value 反序列化为 DayHealthDto -> 组装为 HealthDto
  factory HealthDto.fromJson(Map<String, dynamic> json) {
    final map = <String, DayHealthDto>{};
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        map[key] = DayHealthDto.fromJson(value);
      }
    });
    return HealthDto(dataMap: map);
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    dataMap.forEach((key, value) {
      map[key] = value.toJson();
    });
    return map;
  }
}

/// 单日健康数据 DTO
///
/// 定位：DayHealthData 的持久化传输对象。
/// 在哪一层使用：Repository 实现层。
/// 与版本迁移的关系：字段变更通过 MigrationStep 处理。
class DayHealthDto {
  final int? baseScore;
  final int visionDeduction;
  final int neckDeduction;
  final int waistDeduction;
  final String date;
  final String? visionClickTime;
  final String? neckClickTime;
  final String? waistClickTime;

  const DayHealthDto({
    this.baseScore,
    this.visionDeduction = 0,
    this.neckDeduction = 0,
    this.waistDeduction = 0,
    required this.date,
    this.visionClickTime,
    this.neckClickTime,
    this.waistClickTime,
  });

  factory DayHealthDto.fromJson(Map<String, dynamic> json) => DayHealthDto(
        baseScore: json['baseScore'] as int?,
        visionDeduction: json['visionDeduction'] as int? ?? 0,
        neckDeduction: json['neckDeduction'] as int? ?? 0,
        waistDeduction: json['waistDeduction'] as int? ?? 0,
        date: json['date'] as String,
        visionClickTime: json['visionClickTime'] as String?,
        neckClickTime: json['neckClickTime'] as String?,
        waistClickTime: json['waistClickTime'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'baseScore': baseScore,
        'visionDeduction': visionDeduction,
        'neckDeduction': neckDeduction,
        'waistDeduction': waistDeduction,
        'date': date,
        'visionClickTime': visionClickTime,
        'neckClickTime': neckClickTime,
        'waistClickTime': waistClickTime,
      };
}

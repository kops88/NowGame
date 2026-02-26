/// 每日健康数据领域模型
///
/// 定位：Health 领域的核心领域模型，表达一天内的健康分数状态。
/// 职责：承载每日基准分数、各项扣分累计、按钮点击时间等健康状态数据。
/// 不负责：持久化序列化（由 DayHealthDto 负责）、UI 展示。
/// 在哪一层使用：业务层（HealthService）和 UI 层（只读取不修改）。
/// 与版本迁移的关系：不直接参与迁移，通过 DTO 层间接受管理。
///
/// 从原 ChartDetailDialog.dart 中抽离，保持与存储无关。
class DayHealthData {
  /// 基准分数 0-100（null 表示未手动设置，需继承昨天最终分数）
  int? baseScore;

  /// 视力扣分累计
  int visionDeduction;

  /// 颈部扣分累计
  int neckDeduction;

  /// 腰部扣分累计
  int waistDeduction;

  /// 日期
  DateTime date;

  /// 视力按钮最后点击时间
  DateTime? visionClickTime;

  /// 颈按钮最后点击时间
  DateTime? neckClickTime;

  /// 腰按钮最后点击时间
  DateTime? waistClickTime;

  DayHealthData({
    this.baseScore,
    this.visionDeduction = 0,
    this.neckDeduction = 0,
    this.waistDeduction = 0,
    required this.date,
    this.visionClickTime,
    this.neckClickTime,
    this.waistClickTime,
  });

  /// 获取当日最终分数（基准 - 各项扣分）
  int? get finalScore {
    if (baseScore == null) return null;
    return (baseScore! - visionDeduction - neckDeduction - waistDeduction)
        .clamp(0, 100);
  }

  /// 复制并修改
  DayHealthData copyWith({
    int? baseScore,
    int? visionDeduction,
    int? neckDeduction,
    int? waistDeduction,
    DateTime? date,
    DateTime? visionClickTime,
    DateTime? neckClickTime,
    DateTime? waistClickTime,
    bool clearVisionClick = false,
    bool clearNeckClick = false,
    bool clearWaistClick = false,
  }) {
    return DayHealthData(
      baseScore: baseScore ?? this.baseScore,
      visionDeduction: visionDeduction ?? this.visionDeduction,
      neckDeduction: neckDeduction ?? this.neckDeduction,
      waistDeduction: waistDeduction ?? this.waistDeduction,
      date: date ?? this.date,
      visionClickTime: clearVisionClick ? null : (visionClickTime ?? this.visionClickTime),
      neckClickTime: clearNeckClick ? null : (neckClickTime ?? this.neckClickTime),
      waistClickTime: clearWaistClick ? null : (waistClickTime ?? this.waistClickTime),
    );
  }
}

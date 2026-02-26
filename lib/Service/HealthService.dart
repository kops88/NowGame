import 'package:flutter/foundation.dart';
import 'package:nowgame/Dto/HealthDto.dart';
import 'package:nowgame/Model/DayHealthData.dart';
import 'package:nowgame/Repository/HealthRepository.dart';

/// 健康数据服务
///
/// 定位：Health 领域的业务层，负责健康数据的业务规则与状态管理。
/// 职责：
///   - 管理内存中的健康数据状态（Map<String, DayHealthData>）
///   - 提供按日期查询、扣分、基准分设置等业务操作
///   - 处理按钮每日重置逻辑
///   - 每次数据变更后通过 Repository 持久化
/// 不负责：底层存储实现、DTO 格式管理、UI 展示。
/// 上游依赖方：UI 层（HealthWidget、ChartDetailDialog）监听变化并展示。
/// 下游依赖方：HealthRepository（仓储接口）。
///
/// 从原 ChartDetailDialog.dart 中的 HealthDataManager 重构而来，
/// 增加了 ChangeNotifier 支持和 Repository 模式的持久化。
class HealthService extends ChangeNotifier {
  /// 每天早上7点重置
  static const int _resetHour = 7;

  /// 单例实例
  static HealthService? _instance;

  /// 获取单例（必须先通过 [initialize] 注入依赖）
  factory HealthService() {
    if (_instance == null) {
      throw StateError('HealthService 未初始化，请先调用 HealthService.initialize()');
    }
    return _instance!;
  }

  /// 初始化单例并注入 Repository 依赖
  ///
  /// 伪代码思路：
  ///   如果已有实例则直接返回 -> 否则创建实例并注入 repository
  static void initialize(HealthRepository repository) {
    _instance ??= HealthService._internal(repository);
  }

  /// 重置单例（仅用于测试）
  @visibleForTesting
  static void reset() {
    _instance = null;
  }

  final HealthRepository _repository;

  /// 内存中的健康数据
  final Map<String, DayHealthData> _dataMap = {};

  /// 是否已加载
  bool _initialized = false;

  HealthService._internal(this._repository);

  /// 日期格式化为存储 key
  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// 初始化：从 Repository 加载数据
  ///
  /// 伪代码思路：
  ///   如果已初始化则跳过 -> 从 repository 加载 HealthDto
  ///   -> 将 DTO 转换为领域模型并填充到内存 map -> 标记已初始化
  Future<void> init() async {
    if (_initialized) return;

    final dto = await _repository.load();
    _dataMap.clear();
    dto.dataMap.forEach((key, dayDto) {
      _dataMap[key] = _dtoToDomain(dayDto);
    });

    _initialized = true;
  }

  /// 获取指定日期的数据
  DayHealthData getDataForDate(DateTime date) {
    final key = _dateKey(date);
    return _dataMap[key] ?? DayHealthData(date: date);
  }

  /// 保存指定日期的数据并持久化
  ///
  /// 伪代码思路：
  ///   将数据存入内存 map -> 将整个 map 转为 DTO -> 通过 repository 持久化
  ///   -> 通知监听者数据变化
  Future<void> saveDataForDate(DayHealthData data) async {
    final key = _dateKey(data.date);
    _dataMap[key] = data;
    await _saveAll();
    notifyListeners();
  }

  /// 获取昨天的最终分数（作为今日基准）
  ///
  /// 伪代码思路：
  ///   从昨天开始向前查找最多30天 -> 找到第一个有 baseScore 的数据
  ///   -> 计算其最终分数（基准 - 扣分）并返回
  int? getYesterdayFinalScore() {
    for (int i = 1; i <= 30; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final key = _dateKey(date);
      final data = _dataMap[key];
      if (data != null && data.baseScore != null) {
        return (data.baseScore! - data.visionDeduction - data.neckDeduction - data.waistDeduction).clamp(0, 100);
      }
    }
    return null;
  }

  /// 获取今日有效的基准分数（自动继承昨天的最终分数）
  int? getTodayEffectiveBaseScore() {
    final today = getDataForDate(DateTime.now());
    if (today.baseScore != null) return today.baseScore;
    return getYesterdayFinalScore();
  }

  /// 检查按钮是否可点击（基于重置时间判断）
  ///
  /// 伪代码思路：
  ///   获取对应类型的最后点击时间 -> 如果为 null 则可点击
  ///   -> 计算今日重置时间点（早上7点）
  ///   -> 判断上次点击是否在本次重置周期之前
  bool canClickButton(String type, DayHealthData data) {
    DateTime? clickTime;
    switch (type) {
      case 'vision':
        clickTime = data.visionClickTime;
        break;
      case 'neck':
        clickTime = data.neckClickTime;
        break;
      case 'waist':
        clickTime = data.waistClickTime;
        break;
    }

    if (clickTime == null) return true;

    final now = DateTime.now();
    final todayResetTime = DateTime(now.year, now.month, now.day, _resetHour);

    if (now.isAfter(todayResetTime)) {
      return clickTime.isBefore(todayResetTime);
    } else {
      final yesterdayResetTime = todayResetTime.subtract(const Duration(days: 1));
      return clickTime.isBefore(yesterdayResetTime);
    }
  }

  /// 将全部内存数据保存到 Repository
  Future<void> _saveAll() async {
    final dtoMap = <String, DayHealthDto>{};
    _dataMap.forEach((key, domain) {
      dtoMap[key] = _domainToDto(domain);
    });
    await _repository.save(HealthDto(dataMap: dtoMap));
  }

  /// DTO -> Domain 转换
  DayHealthData _dtoToDomain(DayHealthDto dto) {
    return DayHealthData(
      baseScore: dto.baseScore,
      visionDeduction: dto.visionDeduction,
      neckDeduction: dto.neckDeduction,
      waistDeduction: dto.waistDeduction,
      date: DateTime.parse(dto.date),
      visionClickTime: dto.visionClickTime != null ? DateTime.parse(dto.visionClickTime!) : null,
      neckClickTime: dto.neckClickTime != null ? DateTime.parse(dto.neckClickTime!) : null,
      waistClickTime: dto.waistClickTime != null ? DateTime.parse(dto.waistClickTime!) : null,
    );
  }

  /// Domain -> DTO 转换
  DayHealthDto _domainToDto(DayHealthData domain) {
    return DayHealthDto(
      baseScore: domain.baseScore,
      visionDeduction: domain.visionDeduction,
      neckDeduction: domain.neckDeduction,
      waistDeduction: domain.waistDeduction,
      date: domain.date.toIso8601String(),
      visionClickTime: domain.visionClickTime?.toIso8601String(),
      neckClickTime: domain.neckClickTime?.toIso8601String(),
      waistClickTime: domain.waistClickTime?.toIso8601String(),
    );
  }
}

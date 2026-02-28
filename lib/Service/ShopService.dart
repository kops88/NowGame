import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:nowgame/Dto/ShopDto.dart';
import 'package:nowgame/Model/PoolItemData.dart';
import 'package:nowgame/Model/ShopItemData.dart';
import 'package:nowgame/Repository/ShopRepository.dart';
import 'package:nowgame/Service/TaskService.dart';

/// 商店业务服务
///
/// 定位：Shop 领域的核心业务层，负责商品状态管理、抽卡逻辑、购买流程、过期清理。
/// 职责：
///   - 管理内存中的商品列表和奖池列表状态
///   - 抽卡逻辑：消耗货币、从奖池随机抽取、生成商品
///   - 购买逻辑：扣款 + 调用 TaskService 创建任务 + 移除商品
///   - 过期清理：懒检查模式，每次访问商品列表时过滤已过期的商品
///   - 奖池管理：增删奖池条目
///   - 持久化：通过 ShopRepository 独立保存（不与 Wisdom 聚合混在一起）
/// 不负责：底层存储实现、DTO 格式管理、UI 渲染。
/// 上游依赖方：UI 层（ShopPage、ShopItemCard）。
/// 下游依赖方：ShopRepository（仓储接口）、TaskService（购买后创建任务）。
///
/// 拆分预留：
///   当前阶段商品种类单一（仅任务券），所有逻辑合并在一个 Service 中。
///   当商品种类增多时可拆分为：
///     - GachaService：抽卡随机逻辑 + 奖池管理
///     - ShopService：商品展示状态 + 购买流程
class ShopService extends ChangeNotifier {
  /// 抽卡消耗的固定货币数量（未来接入 MoneyService 时替换为动态值）
  static const int gachaCost = 10;

  /// 商品默认有效时长（抽到后多久过期）
  static const Duration defaultItemDuration = Duration(hours: 24);

  /// 购买任务券时创建的任务默认 maxCount
  static const int taskVoucherMaxCount = 6;

  /// 单例实例
  static ShopService? _instance;

  /// 获取单例
  factory ShopService() {
    if (_instance == null) {
      throw StateError('ShopService 未初始化，请先调用 ShopService.initialize()');
    }
    return _instance!;
  }

  /// 初始化单例并注入依赖
  static void initialize(ShopRepository repository) {
    _instance ??= ShopService._internal(repository);
  }

  /// 重置单例（仅用于测试）
  @visibleForTesting
  static void reset() {
    _instance = null;
  }

  /// 仓储接口
  final ShopRepository _repository;

  /// 商品列表（内部状态）
  List<ShopItemData> _items = [];

  /// 奖池条目列表（内部状态）
  List<PoolItemData> _poolItems = [];

  /// 随机数生成器
  final Random _random = Random();

  ShopService._internal(this._repository);

  /// 获取有效商品列表（懒清理过期商品）
  ///
  /// 伪代码思路：
  ///   遍历商品列表 -> 过滤掉已过期的 -> 如果有商品被过滤掉则异步持久化
  ///   返回过滤后的只读列表
  List<ShopItemData> get items {
    final validItems = _items.where((item) => !item.isExpired).toList();
    if (validItems.length != _items.length) {
      _items = validItems;
      _saveAsync();
    }
    return List.unmodifiable(_items);
  }

  /// 获取奖池条目列表（只读）
  List<PoolItemData> get poolItems => List.unmodifiable(_poolItems);

  /// 从 DTO 加载数据（由 Bootstrap 调用）
  ///
  /// 伪代码思路：
  ///   接收 ShopDto -> 分别将 items 和 poolItems 转换为 Domain Model
  ///   -> 存入内存（不立即过滤过期商品，访问时懒清理）
  void loadFromDto(ShopDto dto) {
    _items = dto.items.map(_itemDtoToDomain).toList();
    _poolItems = dto.poolItems.map(_poolItemDtoToDomain).toList();
    debugPrint('🛒 [ShopService] 加载完成: ${_items.length} items, ${_poolItems.length} pool items');
  }

  /// 导出当前数据为 DTO（用于持久化）
  ShopDto toDto() {
    return ShopDto(
      items: _items.map(_itemDomainToDto).toList(),
      poolItems: _poolItems.map(_poolItemDomainToDto).toList(),
    );
  }

  /// 执行抽卡
  ///
  /// 伪代码思路：
  ///   1. 检查奖池是否有可抽取的条目（remainingCount > 0）
  ///   2. 若无可抽取条目 -> 返回 null 表示失败
  ///   3. 从可抽取条目中随机选取一个
  ///   4. 被选中的条目 remainingCount - 1
  ///   5. 生成一个 ShopItemData（类型由奖池条目决定，当前统一为 taskVoucher）
  ///   6. 将商品添加到商品列表 -> 持久化 -> 通知 UI
  ///   7. 返回抽到的商品
  ///
  /// 注意：货币消耗暂不实现（硬编码常量 gachaCost 仅用于 UI 展示），
  ///   待 MoneyService 就绪后接入扣款逻辑。
  Future<ShopItemData?> performGacha() async {
    // 过滤出仍有剩余次数的奖池条目
    final availablePool = <int>[];
    for (int i = 0; i < _poolItems.length; i++) {
      if (!_poolItems[i].isExhausted) {
        availablePool.add(i);
      }
    }

    if (availablePool.isEmpty) {
      debugPrint('🛒 [ShopService] 奖池为空或全部耗尽，无法抽卡');
      return null;
    }

    // 随机选取一个可用条目
    final selectedPoolIndex = availablePool[_random.nextInt(availablePool.length)];
    final poolItem = _poolItems[selectedPoolIndex];

    // 减少奖池条目的剩余次数
    _poolItems[selectedPoolIndex] = poolItem.copyWith(
      remainingCount: poolItem.remainingCount - 1,
    );

    // 生成商品
    final now = DateTime.now();
    final newItem = ShopItemData(
      id: now.millisecondsSinceEpoch.toString(),
      name: poolItem.name,
      type: ShopItemType.taskVoucher,
      iconCodePoint: poolItem.iconCodePoint,
      price: poolItem.price,
      createdAt: now,
      expireAt: now.add(defaultItemDuration),
      totalDuration: defaultItemDuration,
    );

    _items.add(newItem);
    await _save();
    notifyListeners();

    debugPrint('🛒 [ShopService] 抽卡成功: ${newItem.name}，价格: ${newItem.price}');
    return newItem;
  }

  /// 购买商品
  ///
  /// 伪代码思路：
  ///   1. 按 id 查找商品 -> 未找到或已过期 -> 返回 false
  ///   2. 根据商品类型分发处理：
  ///      - taskVoucher: 调用 TaskService.addTask 创建一条新任务
  ///   3. 从商品列表移除 -> 持久化 -> 通知 UI
  ///   4. 返回 true 表示购买成功
  ///
  /// 注意：扣款逻辑暂不实现，待 MoneyService 就绪后接入。
  Future<bool> purchaseItem(String itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index == -1) {
      debugPrint('🛒 [ShopService] 购买失败: 商品不存在 ($itemId)');
      return false;
    }

    final item = _items[index];
    if (item.isExpired) {
      debugPrint('🛒 [ShopService] 购买失败: 商品已过期 (${item.name})');
      _items.removeAt(index);
      await _save();
      notifyListeners();
      return false;
    }

    // 根据商品类型分发执行购买效果
    await _applyPurchaseEffect(item);

    // 从商品列表移除
    _items.removeAt(index);
    await _save();
    notifyListeners();

    debugPrint('🛒 [ShopService] 购买成功: ${item.name}');
    return true;
  }

  /// 应用购买效果（根据商品类型分发）
  ///
  /// 伪代码思路：
  ///   switch item.type:
  ///     taskVoucher -> 调用 TaskService.addTask 创建任务
  ///   未来新增商品类型时在此添加 case
  Future<void> _applyPurchaseEffect(ShopItemData item) async {
    switch (item.type) {
      case ShopItemType.taskVoucher:
        await TaskService().addTask(
          name: item.name,
          skillId: item.relatedSkillId,
          skillName: item.relatedSkillName,
          maxCount: taskVoucherMaxCount,
          iconCodePoint: item.iconCodePoint,
        );
    }
  }

  /// 添加奖池条目
  ///
  /// 伪代码思路：
  ///   创建新的 PoolItemData -> 添加到列表 -> 持久化 -> 通知 UI
  Future<void> addPoolItem({
    required String name,
    required int price,
    int iconCodePoint = 0xe8e5,
    required int totalCount,
  }) async {
    final poolItem = PoolItemData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      price: price,
      iconCodePoint: iconCodePoint,
      remainingCount: totalCount,
      totalCount: totalCount,
    );
    _poolItems.add(poolItem);
    await _save();
    notifyListeners();
    debugPrint('🛒 [ShopService] 添加奖池条目: $name (×$totalCount)');
  }

  /// 删除奖池条目
  Future<void> removePoolItem(String id) async {
    _poolItems.removeWhere((p) => p.id == id);
    await _save();
    notifyListeners();
  }

  /// 持久化保存
  Future<void> _save() async {
    try {
      await _repository.save(toDto());
    } catch (e) {
      debugPrint('❌ [ShopService] 保存失败: $e');
    }
  }

  /// 异步保存（懒清理时使用，不阻塞 getter）
  void _saveAsync() {
    _save();
  }

  // ==================== DTO <-> Domain 转换 ====================

  /// ShopItemDto -> ShopItemData
  ShopItemData _itemDtoToDomain(ShopItemDto dto) {
    return ShopItemData(
      id: dto.id,
      name: dto.name,
      type: ShopItemType.values.firstWhere(
        (e) => e.name == dto.type,
        orElse: () => ShopItemType.taskVoucher,
      ),
      iconCodePoint: dto.iconCodePoint,
      price: dto.price,
      createdAt: DateTime.parse(dto.createdAt),
      expireAt: DateTime.parse(dto.expireAt),
      totalDuration: Duration(seconds: dto.totalDurationSecs),
      relatedSkillId: dto.relatedSkillId,
      relatedSkillName: dto.relatedSkillName,
    );
  }

  /// ShopItemData -> ShopItemDto
  ShopItemDto _itemDomainToDto(ShopItemData domain) {
    return ShopItemDto(
      id: domain.id,
      name: domain.name,
      type: domain.type.name,
      iconCodePoint: domain.iconCodePoint,
      price: domain.price,
      createdAt: domain.createdAt.toIso8601String(),
      expireAt: domain.expireAt.toIso8601String(),
      totalDurationSecs: domain.totalDuration.inSeconds,
      relatedSkillId: domain.relatedSkillId,
      relatedSkillName: domain.relatedSkillName,
    );
  }

  /// PoolItemDto -> PoolItemData
  PoolItemData _poolItemDtoToDomain(PoolItemDto dto) {
    return PoolItemData(
      id: dto.id,
      name: dto.name,
      price: dto.price,
      iconCodePoint: dto.iconCodePoint,
      remainingCount: dto.remainingCount,
      totalCount: dto.totalCount,
    );
  }

  /// PoolItemData -> PoolItemDto
  PoolItemDto _poolItemDomainToDto(PoolItemData domain) {
    return PoolItemDto(
      id: domain.id,
      name: domain.name,
      price: domain.price,
      iconCodePoint: domain.iconCodePoint,
      remainingCount: domain.remainingCount,
      totalCount: domain.totalCount,
    );
  }
}

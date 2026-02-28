/// Shop 领域数据传输对象（DTO）
///
/// 定位：持久化 DTO 层，专用于 Shop 领域数据的序列化/反序列化。
/// 职责：将商店商品列表 + 奖池条目列表打包为一个可序列化结构。
/// 不负责：业务逻辑（过期清理/购买/抽卡）、UI 展示。
/// 在哪一层使用：Repository 实现层（Domain <-> DTO 映射时使用）。
///
/// 包含两个子 DTO：ShopItemDto（商品）、PoolItemDto（奖池条目），
/// 与领域模型（ShopItemData、PoolItemData）一一对应但职责不同：
///   - DTO 专注序列化格式稳定性和版本兼容
///   - 领域模型专注业务属性和计算
class ShopDto {
  /// 商品列表
  final List<ShopItemDto> items;

  /// 奖池条目列表
  final List<PoolItemDto> poolItems;

  const ShopDto({
    this.items = const [],
    this.poolItems = const [],
  });

  /// 从 JSON 反序列化
  ///
  /// 伪代码思路：
  ///   从 json map 中分别取出 items/poolItems 数组
  ///   -> 逐个反序列化为子 DTO -> 组装为 ShopDto
  ///   任何子数组缺失时回退为空列表
  factory ShopDto.fromJson(Map<String, dynamic> json) {
    return ShopDto(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ShopItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      poolItems: (json['poolItems'] as List<dynamic>?)
              ?.map((e) => PoolItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'poolItems': poolItems.map((e) => e.toJson()).toList(),
      };
}

/// 商品 DTO
///
/// 定位：ShopItemData 的持久化传输对象。
/// 在哪一层使用：Repository 实现层。
/// 日期字段以 ISO8601 字符串存储，Duration 以秒数存储。
class ShopItemDto {
  final String id;
  final String name;
  final String type;
  final int iconCodePoint;
  final int price;
  final String createdAt;
  final String expireAt;
  final int totalDurationSecs;
  final String relatedSkillId;
  final String relatedSkillName;

  const ShopItemDto({
    required this.id,
    required this.name,
    this.type = 'taskVoucher',
    this.iconCodePoint = 0xe8e5,
    this.price = 10,
    required this.createdAt,
    required this.expireAt,
    this.totalDurationSecs = 3600,
    this.relatedSkillId = '',
    this.relatedSkillName = '',
  });

  factory ShopItemDto.fromJson(Map<String, dynamic> json) => ShopItemDto(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String? ?? 'taskVoucher',
        iconCodePoint: json['iconCodePoint'] as int? ?? 0xe8e5,
        price: json['price'] as int? ?? 10,
        createdAt: json['createdAt'] as String,
        expireAt: json['expireAt'] as String,
        totalDurationSecs: json['totalDurationSecs'] as int? ?? 3600,
        relatedSkillId: json['relatedSkillId'] as String? ?? '',
        relatedSkillName: json['relatedSkillName'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'iconCodePoint': iconCodePoint,
        'price': price,
        'createdAt': createdAt,
        'expireAt': expireAt,
        'totalDurationSecs': totalDurationSecs,
        'relatedSkillId': relatedSkillId,
        'relatedSkillName': relatedSkillName,
      };
}

/// 奖池条目 DTO
///
/// 定位：PoolItemData 的持久化传输对象。
/// 在哪一层使用：Repository 实现层。
class PoolItemDto {
  final String id;
  final String name;
  final int price;
  final int iconCodePoint;
  final int remainingCount;
  final int totalCount;

  const PoolItemDto({
    required this.id,
    required this.name,
    this.price = 10,
    this.iconCodePoint = 0xe8e5,
    this.remainingCount = 0,
    this.totalCount = 0,
  });

  factory PoolItemDto.fromJson(Map<String, dynamic> json) => PoolItemDto(
        id: json['id'] as String,
        name: json['name'] as String,
        price: json['price'] as int? ?? 10,
        iconCodePoint: json['iconCodePoint'] as int? ?? 0xe8e5,
        remainingCount: json['remainingCount'] as int? ?? 0,
        totalCount: json['totalCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'iconCodePoint': iconCodePoint,
        'remainingCount': remainingCount,
        'totalCount': totalCount,
      };
}

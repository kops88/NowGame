/// 商品类型枚举
///
/// 定位：Shop 领域的商品种类标识。
/// 职责：区分不同类型的商品，支持未来扩展新品类。
/// 不负责：商品的具体行为实现（由 ShopService 根据类型分发处理）。
///
/// 当前仅有 taskVoucher（任务券），购买后在 TaskService 中创建一条新任务。
/// 扩展方式：新增枚举值 + 在 ShopService 购买逻辑中新增对应 case。
enum ShopItemType {
  /// 任务券：购买后创建一条任务
  taskVoucher,
}

/// 商品领域模型
///
/// 定位：Shop 领域的核心数据结构，描述一件可购买的商品。
/// 职责：承载商品属性（名称、价格、过期时间、关联信息），提供时间相关的计算属性。
/// 不负责：序列化格式（由 ShopItemDto 负责）、业务逻辑（由 ShopService 负责）、UI 渲染。
/// 使用层级：Service 层（ShopService）在内存中持有此模型列表。
///
/// 数据描述：
///   - id: 唯一标识（时间戳生成）
///   - name: 商品名称（来源于抽到的奖池条目名称）
///   - type: 商品类型（当前仅 taskVoucher）
///   - iconCodePoint: 展示图标的 MaterialIcons 码点
///   - price: 购买价格
///   - createdAt: 商品生成时间（抽卡获得的时间）
///   - expireAt: 过期时间（超过后商品从列表消失）
///   - totalDuration: 商品总有效时长（用于计算透明度）
///   - relatedSkillId: 关联技能 ID（购买后创建任务时使用）
///   - relatedSkillName: 关联技能名称（购买后创建任务时使用）
///
/// 扩展预留：未来可添加 rarity（稀有度）、description（描述）等字段
class ShopItemData {
  final String id;
  final String name;
  final ShopItemType type;
  final int iconCodePoint;
  final int price;
  final DateTime createdAt;
  final DateTime expireAt;
  final Duration totalDuration;

  /// 关联技能 ID（购买任务券时用于创建任务）
  final String relatedSkillId;

  /// 关联技能名称（购买任务券时用于创建任务的展示名称）
  final String relatedSkillName;

  const ShopItemData({
    required this.id,
    required this.name,
    this.type = ShopItemType.taskVoucher,
    this.iconCodePoint = 0xe8e5, // Icons.receipt_long
    required this.price,
    required this.createdAt,
    required this.expireAt,
    required this.totalDuration,
    this.relatedSkillId = '',
    this.relatedSkillName = '',
  });

  /// 是否已过期
  ///
  /// 伪代码思路：当前时间 >= expireAt -> 已过期
  bool get isExpired => DateTime.now().isAfter(expireAt);

  /// 剩余时间
  ///
  /// 伪代码思路：expireAt - now，若为负则返回 Duration.zero
  Duration get remainingTime {
    final diff = expireAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// 透明度（基于剩余时间比例）
  ///
  /// 伪代码思路：
  ///   opacity = remainingTime / totalDuration
  ///   限制下界为 0.05（即使快过期也不完全透明，保持可见性）
  ///   限制上界为 1.0
  double get opacity {
    if (totalDuration.inSeconds <= 0) return 0.05;
    final ratio = remainingTime.inSeconds / totalDuration.inSeconds;
    return ratio.clamp(0.05, 1.0);
  }

  /// 剩余时间格式化文本
  ///
  /// 伪代码思路：
  ///   已过期 -> "已过期"
  ///   >= 1天 -> "Xd"
  ///   >= 1小时 -> "Xh"
  ///   >= 1分钟 -> "Xm"
  ///   < 1分钟 -> "<1m"
  String get remainingTimeText {
    if (isExpired) return '已过期';
    final remaining = remainingTime;
    if (remaining.inDays > 0) return '${remaining.inDays}d';
    if (remaining.inHours > 0) return '${remaining.inHours}h';
    if (remaining.inMinutes > 0) return '${remaining.inMinutes}m';
    return '<1m';
  }

  /// 从 JSON 反序列化
  factory ShopItemData.fromJson(Map<String, dynamic> json) {
    return ShopItemData(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ShopItemType.values.firstWhere(
        (e) => e.name == (json['type'] as String?),
        orElse: () => ShopItemType.taskVoucher,
      ),
      iconCodePoint: json['iconCodePoint'] as int? ?? 0xe8e5,
      price: json['price'] as int? ?? 10,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expireAt: DateTime.parse(json['expireAt'] as String),
      totalDuration: Duration(seconds: json['totalDurationSecs'] as int? ?? 3600),
      relatedSkillId: json['relatedSkillId'] as String? ?? '',
      relatedSkillName: json['relatedSkillName'] as String? ?? '',
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'iconCodePoint': iconCodePoint,
        'price': price,
        'createdAt': createdAt.toIso8601String(),
        'expireAt': expireAt.toIso8601String(),
        'totalDurationSecs': totalDuration.inSeconds,
        'relatedSkillId': relatedSkillId,
        'relatedSkillName': relatedSkillName,
      };

  /// 创建副本并修改部分字段
  ShopItemData copyWith({
    String? id,
    String? name,
    ShopItemType? type,
    int? iconCodePoint,
    int? price,
    DateTime? createdAt,
    DateTime? expireAt,
    Duration? totalDuration,
    String? relatedSkillId,
    String? relatedSkillName,
  }) {
    return ShopItemData(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      expireAt: expireAt ?? this.expireAt,
      totalDuration: totalDuration ?? this.totalDuration,
      relatedSkillId: relatedSkillId ?? this.relatedSkillId,
      relatedSkillName: relatedSkillName ?? this.relatedSkillName,
    );
  }
}

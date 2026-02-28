/// 奖池条目领域模型
///
/// 定位：Shop 领域的奖池子模块，描述一个可被抽取的奖品模板。
/// 职责：承载奖品的属性（名称、价格、图标、可抽取次数），提供 copyWith / 序列化方法。
/// 不负责：序列化格式管理（由 PoolItemDto 负责）、业务逻辑（由 ShopService 负责）、UI 渲染。
/// 使用层级：Service 层（ShopService）在内存中持有此模型列表。
///
/// 数据描述：
///   - id: 唯一标识（时间戳生成）
///   - name: 奖品名称（用于抽中后的商品展示和创建任务时的名称）
///   - price: 抽中后商品的售价
///   - iconCodePoint: 展示图标的 MaterialIcons 码点
///   - remainingCount: 剩余可抽取次数（每次被抽中后减 1，为 0 时不再参与抽取）
///   - totalCount: 总可抽取次数（用于展示 "剩余 X/Y 次"）
///
/// 扩展预留：未来可添加 rarity（稀有度）、weight（权重）等字段
class PoolItemData {
  final String id;
  final String name;
  final int price;
  final int iconCodePoint;
  final int remainingCount;
  final int totalCount;

  const PoolItemData({
    required this.id,
    required this.name,
    required this.price,
    this.iconCodePoint = 0xe8e5, // Icons.receipt_long
    required this.remainingCount,
    required this.totalCount,
  });

  /// 是否已耗尽（剩余次数 <= 0）
  bool get isExhausted => remainingCount <= 0;

  /// 剩余次数展示文本（如 "3/5"）
  String get remainingText => '$remainingCount/$totalCount';

  /// 从 JSON 反序列化
  factory PoolItemData.fromJson(Map<String, dynamic> json) {
    return PoolItemData(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int? ?? 10,
      iconCodePoint: json['iconCodePoint'] as int? ?? 0xe8e5,
      remainingCount: json['remainingCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'iconCodePoint': iconCodePoint,
        'remainingCount': remainingCount,
        'totalCount': totalCount,
      };

  /// 创建副本并修改部分字段
  PoolItemData copyWith({
    String? id,
    String? name,
    int? price,
    int? iconCodePoint,
    int? remainingCount,
    int? totalCount,
  }) {
    return PoolItemData(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      remainingCount: remainingCount ?? this.remainingCount,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

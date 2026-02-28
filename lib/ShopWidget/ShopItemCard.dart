import 'package:flutter/material.dart';
import 'package:nowgame/Model/ShopItemData.dart';
import 'package:nowgame/Util/DebugWidget.dart';

/// 商品卡片样式配置类
///
/// 定位：集中管理 ShopItemCard 和 PoolItemCard 的所有视觉参数。
/// 职责：避免样式参数散落在 Widget build 方法中。
/// 不负责：业务逻辑、动画控制。
class ShopItemCardStyle {
  /// 卡片背景色
  final Color backgroundColor;

  /// 卡片圆角半径
  final double borderRadius;

  /// 卡片内边距
  final EdgeInsets padding;

  /// 图标大小
  final double iconSize;

  /// 名称文字样式
  final TextStyle nameStyle;

  /// 剩余时间文字样式
  final TextStyle remainingTimeStyle;

  /// 价格文字样式
  final TextStyle priceStyle;

  /// 价格角标背景色
  final Color priceBadgeColor;

  const ShopItemCardStyle({
    this.backgroundColor = const Color(0xFF2A2A2E),
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(10),
    this.iconSize = 36.0,
    this.nameStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    this.remainingTimeStyle = const TextStyle(
      fontSize: 11,
      color: Colors.white54,
    ),
    this.priceStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Colors.amber,
    ),
    this.priceBadgeColor = const Color(0xFF3A3A3E),
  });
}

/// 商品卡片组件
///
/// 定位：Shop 领域 UI 层的原子组件，负责渲染单个可购买商品。
/// 职责：展示商品图标、名称、价格标签、剩余时间，根据透明度反映时间流逝。
/// 不负责：购买逻辑（通过 onTap 回调上报）、过期清理、持久化。
/// 上游依赖方：ShopPage 通过 GridView 使用此组件。
///
/// 视觉设计：
///   - 深色圆角矩形卡片
///   - 中央：图标 + 名称
///   - 右上角：价格标签（金币图标 + 金额）
///   - 名称下方：剩余时间（灰色小字）
///   - 整体透明度随时间降低（最低 5%）
class ShopItemCard extends StatelessWidget {
  final ShopItemData item;
  final ShopItemCardStyle style;
  final VoidCallback? onTap;

  const ShopItemCard({
    super.key,
    required this.item,
    this.style = const ShopItemCardStyle(),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: item.opacity,
        child: Container(
          padding: style.padding,
          decoration: BoxDecoration(
            color: style.backgroundColor,
            borderRadius: BorderRadius.circular(style.borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Stack(
            children: [
              // 主体内容（居中布局）
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 商品图标
                    Icon(
                      IconData(item.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: Colors.tealAccent,
                      size: style.iconSize,
                    ),
                    const SizedBox(height: 8),
                    // 商品名称
                    MText(
                      item.name,
                      style: style.nameStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    // 剩余时间
                    MText(
                      item.remainingTimeText,
                      style: style.remainingTimeStyle,
                    ),
                  ],
                ),
              ),
              // 右上角价格标签
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: style.priceBadgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 12),
                      const SizedBox(width: 2),
                      MText(
                        '${item.price}',
                        style: style.priceStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

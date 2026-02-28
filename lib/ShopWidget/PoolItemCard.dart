import 'package:flutter/material.dart';
import 'package:nowgame/Model/PoolItemData.dart';
import 'package:nowgame/ShopWidget/ShopItemCard.dart';
import 'package:nowgame/Util/DebugWidget.dart';

/// 奖池条目卡片组件
///
/// 定位：Shop 领域 UI 层的原子组件，负责渲染奖池中单个可抽取奖品的预览卡片。
/// 职责：展示奖品图标、名称、价格标签、剩余可抽取次数。
/// 不负责：业务逻辑（添加/删除奖池条目）、配置表单。
/// 上游依赖方：PoolPreviewDialog 通过 GridView 使用此组件。
///
/// 视觉设计：
///   - 复用 ShopItemCard 的外观风格（深色圆角矩形、中央图标、底部名称）
///   - 右上角：价格标签（与 ShopItemCard 一致）
///   - 底部：替换剩余时间为"剩余 X/Y"文字
///   - 不显示：抽卡按钮、剩余倒计时
///   - 次数耗尽时整体半透明
class PoolItemCard extends StatelessWidget {
  final PoolItemData item;
  final ShopItemCardStyle style;
  final VoidCallback? onTap;

  const PoolItemCard({
    super.key,
    required this.item,
    this.style = const ShopItemCardStyle(),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = item.isExhausted ? 0.4 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: opacity,
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
                    // 奖品图标
                    Icon(
                      IconData(item.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: Colors.tealAccent,
                      size: style.iconSize,
                    ),
                    const SizedBox(height: 8),
                    // 奖品名称
                    MText(
                      item.name,
                      style: style.nameStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    // 剩余次数（替代 ShopItemCard 的剩余时间）
                    MText(
                      '剩余 ${item.remainingText}',
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

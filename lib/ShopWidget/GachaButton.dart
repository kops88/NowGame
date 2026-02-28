import 'package:flutter/material.dart';
import 'package:nowgame/Service/ShopService.dart';
import 'package:nowgame/Util/DebugWidget.dart';

/// 抽卡按钮组件
///
/// 定位：Shop 领域 UI 层的原子组件，负责渲染抽卡操作入口。
/// 职责：展示加号图标 + 消耗货币数量，点击触发抽卡回调。
/// 不负责：抽卡逻辑（通过 onTap 回调上报给 ShopPage）。
/// 上游依赖方：ShopPage 在 GridView 中作为固定位置使用此组件。
///
/// 视觉设计：
///   - 与 ShopItemCard 等高等宽的灰色虚线边框矩形
///   - 中央：大号加号图标
///   - 底部：消耗货币数量提示
class GachaButton extends StatelessWidget {
  final VoidCallback? onTap;

  /// 抽卡按钮样式参数
  static const double _borderRadius = 12.0;
  static const double _iconSize = 36.0;

  const GachaButton({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_borderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: Colors.white.withValues(alpha: 0.6),
                size: _iconSize,
              ),
              const SizedBox(height: 8),
              // 消耗货币提示
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  MText(
                    '${ShopService.gachaCost}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

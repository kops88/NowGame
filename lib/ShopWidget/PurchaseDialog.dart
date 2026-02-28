import 'package:flutter/material.dart';
import 'package:nowgame/Model/ShopItemData.dart';
import 'package:nowgame/Service/ShopService.dart';
import 'package:nowgame/Util/DebugWidget.dart';

/// 购买确认弹窗
///
/// 定位：Shop 领域 UI 层的交互组件，确认购买操作。
/// 职责：展示商品信息、确认/取消按钮，通过 Navigator.pop 返回用户选择。
/// 不负责：实际购买逻辑（由调用方根据返回值处理）、持久化。
/// 上游依赖方：ShopPage 中点击商品卡片时触发。
/// 下游依赖方：无。
class PurchaseDialog {
  PurchaseDialog._();

  /// 显示购买确认弹窗
  ///
  /// 伪代码思路：
  ///   1. 使用 showDialog 弹出 AlertDialog
  ///   2. 展示商品图标、名称、价格信息
  ///   3. 用户点击"购买" -> pop(true)
  ///   4. 用户点击"取消" -> pop(false)
  ///   5. 调用方根据返回值决定是否执行购买
  static Future<bool> show(BuildContext context, ShopItemData item) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _PurchaseDialogContent(item: item),
    );
    return result ?? false;
  }
}

/// 购买确认弹窗内容
///
/// 负责：渲染商品信息和操作按钮。
/// 不负责：购买逻辑、持久化。
class _PurchaseDialogContent extends StatelessWidget {
  final ShopItemData item;

  const _PurchaseDialogContent({required this.item});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const MText(
        '确认购买',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 商品图标
          Icon(
            IconData(item.iconCodePoint, fontFamily: 'MaterialIcons'),
            color: Colors.tealAccent,
            size: 48,
          ),
          const SizedBox(height: 12),
          // 商品名称
          MText(
            item.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // 价格信息
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              MText(
                '${item.price}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 剩余时间
          MText(
            '剩余时间: ${item.remainingTimeText}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          // 购买效果提示
          MText(
            '购买后将获得一条任务（进度上限 ${ShopService.taskVoucherMaxCount}）',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('购买'),
        ),
      ],
    );
  }
}

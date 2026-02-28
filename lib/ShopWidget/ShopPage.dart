import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nowgame/Model/ShopItemData.dart';
import 'package:nowgame/Service/ShopService.dart';
import 'package:nowgame/ShopWidget/GachaButton.dart';
import 'package:nowgame/ShopWidget/PoolPreviewDialog.dart';
import 'package:nowgame/ShopWidget/PurchaseDialog.dart';
import 'package:nowgame/ShopWidget/ShopItemCard.dart';
import 'package:nowgame/Util/DebugWidget.dart';
import 'package:nowgame/Util/ExpandablePopup.dart';

/// 商店页面
///
/// 定位：Shop 领域 UI 层的页面级组件，负责商店整体布局和交互协调。
/// 职责：
///   - 横向网格布局（一行 3 个）展示商品卡片 + 固定的抽卡按钮
///   - 监听 ShopService 数据变化以实时更新 UI
///   - 协调抽卡操作和购买确认弹窗
///   - 定时刷新 UI 以反映商品透明度和剩余时间的变化
/// 不负责：抽卡/购买的具体业务逻辑（委托给 ShopService）、导航管理。
/// 上游依赖方：AppShell 通过 Tab 切换展示此页面。
/// 下游依赖方：ShopService（数据源）、ShopItemCard / GachaButton / PurchaseDialog（子组件）。
///
/// 布局设计：
///   - AppBar: 标题 "商店" + 右侧 "Pool" 按钮（打开奖池预览）
///   - Body: GridView（crossAxisCount: 3），最后一个位置固定为 GachaButton
///   - 空状态：仅显示 GachaButton
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final ShopService _shopService = ShopService();

  /// "Pool" 按钮的 GlobalKey，用于获取弹窗动画起始位置
  final GlobalKey _poolButtonKey = GlobalKey();

  /// 定时刷新 Timer（每分钟刷新一次以更新透明度和剩余时间）
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _shopService.addListener(_onDataChanged);
    // 每 60 秒刷新一次 UI，反映时间流逝导致的透明度变化
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _shopService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  /// 处理抽卡按钮点击
  ///
  /// 伪代码思路：
  ///   调用 ShopService.performGacha() -> 成功则 SnackBar 提示
  ///   -> 失败则提示奖池为空
  Future<void> _onGachaTap() async {
    final result = await _shopService.performGacha();
    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 抽到了: ${result.name}'),
          backgroundColor: Colors.teal,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('奖池为空或已全部抽完'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 处理商品卡片点击 -> 弹出购买确认弹窗
  ///
  /// 伪代码思路：
  ///   弹出 PurchaseDialog -> 用户确认 -> 调用 ShopService.purchaseItem
  Future<void> _onItemTap(ShopItemData item) async {
    final confirmed = await PurchaseDialog.show(context, item);
    if (!confirmed || !mounted) return;

    final success = await _shopService.purchaseItem(item.id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 购买成功: ${item.name}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 打开奖池预览弹窗
  ///
  /// 伪代码思路：获取 "Pool" 按钮位置 -> 调用 PoolPreviewDialog.show
  Future<void> _onPoolTap() async {
    final sourceRect = getWidgetRect(_poolButtonKey);
    if (sourceRect == null) return;

    await PoolPreviewDialog.show(context, sourceRect: sourceRect);
  }

  @override
  Widget build(BuildContext context) {
    final shopItems = _shopService.items;

    return Scaffold(
      appBar: AppBar(
        title: const MText('商店', style: TextStyle(color: Colors.white)),
        actions: [
          // "Pool" 按钮：打开奖池预览
          TextButton(
            key: _poolButtonKey,
            onPressed: _onPoolTap,
            child: const MText(
              'Pool',
              style: TextStyle(
                color: Colors.tealAccent,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildGrid(shopItems),
        ),
      ),
    );
  }

  /// 构建商品网格
  ///
  /// 伪代码思路：
  ///   GridView 3 列，itemCount = shopItems.length + 1（最后一个是抽卡按钮）
  ///   index < shopItems.length -> ShopItemCard
  ///   index == shopItems.length -> GachaButton（固定在末尾）
  Widget _buildGrid(List<ShopItemData> shopItems) {
    final totalCount = shopItems.length + 1; // +1 for GachaButton

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        // 最后一个位置固定为抽卡按钮
        if (index == shopItems.length) {
          return GachaButton(onTap: _onGachaTap);
        }

        // 商品卡片
        final item = shopItems[index];
        return ShopItemCard(
          item: item,
          onTap: () => _onItemTap(item),
        );
      },
    );
  }
}

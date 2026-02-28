import 'package:flutter/material.dart';
import 'package:nowgame/Model/PoolItemData.dart';
import 'package:nowgame/Service/ShopService.dart';
import 'package:nowgame/ShopWidget/PoolItemCard.dart';
import 'package:nowgame/ShopWidget/PoolItemConfigDialog.dart';
import 'package:nowgame/Util/DebugWidget.dart';
import 'package:nowgame/Util/ExpandablePopup.dart';

/// 奖池预览弹窗
///
/// 定位：Shop 领域 UI 层的弹窗组件，展示所有奖池条目的网格预览。
/// 职责：
///   - 通过 ExpandablePopup.show() 从按钮位置展开带动画的弹窗
///   - 以网格形式展示所有奖池条目卡片（复用 PoolItemCard）
///   - 底部提供"添加"按钮，触发 PoolItemConfigDialog
///   - 监听 ShopService 变化以实时更新奖池列表
/// 不负责：奖池条目配置（委托给 PoolItemConfigDialog）、抽卡逻辑。
/// 上游依赖方：ShopPage AppBar 中的 "Pool" 按钮触发。
/// 下游依赖方：ShopService（读取奖池数据）、PoolItemConfigDialog（添加条目）。
///
/// 布局设计：
///   - 顶部标题 "Pool"
///   - 中间 GridView（crossAxisCount: 3）展示奖池条目
///   - 底部居中"添加"按钮
class PoolPreviewDialog {
  PoolPreviewDialog._();

  /// 显示奖池预览弹窗
  ///
  /// 伪代码思路：
  ///   1. 使用 ExpandablePopup.show() 从 sourceRect 位置展开
  ///   2. 内部渲染 _PoolPreviewContent（含网格 + 添加按钮）
  ///   3. 点击背景区域时自动关闭（由 ExpandablePopup 处理）
  static Future<void> show(
    BuildContext context, {
    required Rect sourceRect,
  }) {
    return ExpandablePopup.show(
      context,
      sourceRect: sourceRect,
      config: const ExpandablePopupConfig(
        horizontalMargin: 24.0,
        topRatio: 0.12,
        maxBlurSigma: 10.0,
        maxOverlayOpacity: 0.4,
      ),
      contentBuilder: (ctx, animationValue) {
        return _PoolPreviewContent(animationValue: animationValue);
      },
    );
  }
}

/// 奖池预览弹窗内容
///
/// 负责：渲染奖池网格列表和底部"添加"按钮。
/// 不负责：弹窗动画、数据持久化。
class _PoolPreviewContent extends StatefulWidget {
  final double animationValue;

  const _PoolPreviewContent({required this.animationValue});

  @override
  State<_PoolPreviewContent> createState() => _PoolPreviewContentState();
}

class _PoolPreviewContentState extends State<_PoolPreviewContent> {
  final ShopService _shopService = ShopService();

  /// "添加"按钮的 GlobalKey，用于获取弹窗动画起始位置
  final GlobalKey _addButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _shopService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _shopService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  /// 处理"添加"按钮点击 -> 弹出配置弹窗
  ///
  /// 伪代码思路：
  ///   1. 获取"添加"按钮的屏幕 Rect 作为动画起点
  ///   2. 弹出 PoolItemConfigDialog
  ///   3. 用户确认后调用 ShopService.addPoolItem 添加到奖池
  Future<void> _onAddTap() async {
    final sourceRect = getWidgetRect(_addButtonKey);
    if (sourceRect == null) return;

    final result = await PoolItemConfigDialog.show(
      context,
      sourceRect: sourceRect,
    );
    if (result == null) return;

    await _shopService.addPoolItem(
      name: result['name'] as String,
      price: result['price'] as int,
      iconCodePoint: result['iconCodePoint'] as int,
      totalCount: result['totalCount'] as int,
    );
  }

  @override
  Widget build(BuildContext context) {
    final poolItems = _shopService.poolItems;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: MText(
              'Pool',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // 奖池网格
          Expanded(
            child: poolItems.isEmpty
                ? _buildEmptyState()
                : _buildPoolGrid(poolItems),
          ),
          // 底部添加按钮
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              key: _addButtonKey,
              onPressed: _onAddTap,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent.withValues(alpha: 0.2),
                foregroundColor: Colors.tealAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态提示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          MText(
            '奖池为空，点击下方添加',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建奖池网格
  ///
  /// 伪代码思路：
  ///   GridView 3 列展示所有奖池条目，使用 PoolItemCard 渲染每个条目
  Widget _buildPoolGrid(List<PoolItemData> poolItems) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: poolItems.length,
      itemBuilder: (context, index) {
        final item = poolItems[index];
        return PoolItemCard(item: item);
      },
    );
  }
}

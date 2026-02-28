import 'package:flutter/material.dart';
import 'package:nowgame/MainWidget/SkillConfigDialog.dart';
import 'package:nowgame/Util/DebugWidget.dart';
import 'package:nowgame/Util/ExpandablePopup.dart';

/// 奖池条目配置弹窗
///
/// 定位：Shop 领域 UI 层的交互组件，收集"添加奖池条目"所需的表单数据。
/// 职责：
///   - 通过 ExpandablePopup.showConfigDialog 展示带动画的配置弹窗
///   - 渲染名称、价格、图标选择、可购买次数四个字段
///   - 验证输入后通过 Navigator.pop 返回结果
/// 不负责：动画控制（委托给 ExpandablePopup）、数据持久化（由调用方通过返回值处理）。
/// 上游依赖方：PoolPreviewDialog 中"添加"按钮触发。
/// 下游依赖方：无。
class PoolItemConfigDialog {
  PoolItemConfigDialog._();

  /// 通过统一动画弹窗显示奖池条目配置表单
  ///
  /// 伪代码思路：
  ///   1. 使用 ExpandablePopup.showConfigDialog 从 sourceRect 位置弹出
  ///   2. 内部渲染 _PoolItemConfigFormContent 表单
  ///   3. 用户确认后通过 Navigator.pop 返回 {name, price, iconCodePoint, totalCount}
  ///   4. 用户取消则返回 null
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required Rect sourceRect,
  }) {
    return ExpandablePopup.showConfigDialog<Map<String, dynamic>>(
      context,
      sourceRect: sourceRect,
      config: kConfigDialogPopupConfig.copyWith(targetHeight: 480.0),
      contentBuilder: (ctx, animationValue) {
        return _PoolItemConfigFormContent(animationValue: animationValue);
      },
    );
  }
}

/// 预置可选图标列表
///
/// 提供常用的 MaterialIcons 供用户选择作为奖池条目图标。
/// 每个条目为 (codePoint, 展示名称) 的组合。
const List<(int, String)> _presetIcons = [
  (0xe8e5, 'receipt'),      // Icons.receipt_long
  (0xe80e, 'bolt'),         // Icons.bolt
  (0xe87d, 'star'),         // Icons.star
  (0xe838, 'favorite'),     // Icons.favorite
  (0xe3e7, 'palette'),      // Icons.palette
  (0xe3a9, 'music'),        // Icons.music_note
  (0xe865, 'code'),         // Icons.code
  (0xea77, 'fitness'),      // Icons.fitness_center
  (0xe5f5, 'self_improve'), // Icons.self_improvement
  (0xef63, 'book'),         // Icons.menu_book
  (0xe163, 'build'),        // Icons.build
  (0xe8b8, 'school'),       // Icons.school
];

/// 奖池条目配置表单内容
///
/// 负责：渲染表单字段（名称、价格、图标、可购买次数）、验证输入、返回结果。
/// 不负责：动画、弹窗容器、数据持久化。
class _PoolItemConfigFormContent extends StatefulWidget {
  final double animationValue;

  const _PoolItemConfigFormContent({required this.animationValue});

  @override
  State<_PoolItemConfigFormContent> createState() =>
      _PoolItemConfigFormContentState();
}

class _PoolItemConfigFormContentState
    extends State<_PoolItemConfigFormContent> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController(text: '10');
  final _countController = TextEditingController(text: '5');
  final _formKey = GlobalKey<FormState>();

  /// 当前选中的图标码点
  int _selectedIconCodePoint = _presetIcons[0].$1;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _countController.dispose();
    super.dispose();
  }

  /// 验证并返回表单数据
  ///
  /// 伪代码思路：校验 formKey -> 组装 Map -> pop 返回
  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'price': int.tryParse(_priceController.text.trim()) ?? 10,
      'iconCodePoint': _selectedIconCodePoint,
      'totalCount': int.tryParse(_countController.text.trim()) ?? 5,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MText(
                'Add Pool Item',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              // 名称字段
              ConfigFormField(
                label: 'Name',
                controller: _nameController,
                hintText: 'Enter item name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 价格字段
              ConfigFormField(
                label: 'Price',
                controller: _priceController,
                hintText: '10',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final num = int.tryParse(value ?? '');
                  if (num == null || num <= 0) {
                    return 'Must be a positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 可购买次数字段
              ConfigFormField(
                label: 'Total Count',
                controller: _countController,
                hintText: '5',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final num = int.tryParse(value ?? '');
                  if (num == null || num <= 0) {
                    return 'Must be a positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 图标选择区域
              Text(
                'Icon',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              _buildIconSelector(),
              const SizedBox(height: 24),
              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建图标选择网格
  ///
  /// 伪代码思路：
  ///   GridView 展示预置图标列表 -> 点击选中 -> 选中项高亮边框
  Widget _buildIconSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presetIcons.map((entry) {
        final (codePoint, _) = entry;
        final isSelected = codePoint == _selectedIconCodePoint;
        return GestureDetector(
          onTap: () => setState(() => _selectedIconCodePoint = codePoint),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.tealAccent.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: Colors.tealAccent, width: 2)
                  : null,
            ),
            child: Icon(
              IconData(codePoint, fontFamily: 'MaterialIcons'),
              color: isSelected ? Colors.tealAccent : Colors.white54,
              size: 22,
            ),
          ),
        );
      }).toList(),
    );
  }
}

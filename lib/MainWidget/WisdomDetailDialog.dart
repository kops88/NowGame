import 'package:flutter/material.dart';
import 'package:nowgame/Util/ExpandablePopup.dart';
import 'package:nowgame/MainWidget/SkillDetailCard.dart';
import 'package:nowgame/MainWidget/SkillConfigDialog.dart';
import 'package:nowgame/Model/SkillPointData.dart';
import 'package:nowgame/Service/SkillPointService.dart';
import 'package:nowgame/Service/TaskService.dart';

/// Wisdom 详情弹出层
/// 负责：接收技能卡 ID 与 sourceRect，组装通用弹出层容器，展示该技能卡下属的技能点列表
/// 依赖通用弹出层模块，不包含动画实现细节
class WisdomDetailDialog {
  WisdomDetailDialog._();

  /// 弹出层配置常量
  static const _config = ExpandablePopupConfig(
    openDuration: Duration(milliseconds: 350),
    closeDuration: Duration(milliseconds: 250),
    maxBlurSigma: 10.0,
    maxOverlayOpacity: 0.3,
    horizontalMargin: 24.0,
    topRatio: 0.12,
    targetHeight: 480.0,
    cardBorderRadius: 16.0,
    cardBackgroundColor: Color(0xFF1C1C1E),
  );

  /// 显示 Wisdom 详情弹出层
  /// [context] 上下文
  /// [sourceRect] 原始元素的位置（用于动画起点）
  /// [skillId] 技能卡 ID（用于过滤该技能卡下属的技能点）
  /// [skillName] 技能卡名称（用于标题展示）
  /// [onDismiss] 关闭回调（可选）
  static Future<void> show(
    BuildContext context, {
    required Rect sourceRect,
    required String skillId,
    String? skillName,
    VoidCallback? onDismiss,
  }) {
    return ExpandablePopup.show(
      context,
      sourceRect: sourceRect,
      config: _config,
      onDismiss: onDismiss,
      contentBuilder: (context, animationValue) {
        return _WisdomDetailContent(
          skillId: skillId,
          skillName: skillName,
          animationValue: animationValue,
        );
      },
    );
  }
}

/// Wisdom 弹出层内容组件
/// 内部使用，负责渲染该技能卡下属的技能点列表和任务配置区域
class _WisdomDetailContent extends StatefulWidget {
  final String skillId;
  final String? skillName;
  final double animationValue;

  const _WisdomDetailContent({
    required this.skillId,
    this.skillName,
    required this.animationValue,
  });

  @override
  State<_WisdomDetailContent> createState() => _WisdomDetailContentState();
}

class _WisdomDetailContentState extends State<_WisdomDetailContent> {
  final SkillPointService _skillPointService = SkillPointService();
  final TaskService _taskService = TaskService();

  /// 当前选中的技能点（用于显示任务配置区域）
  SkillPointData? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _skillPointService.addListener(_onDataChanged);
    _taskService.addListener(_onDataChanged);
    _initServices();
  }

  @override
  void dispose() {
    _skillPointService.removeListener(_onDataChanged);
    _taskService.removeListener(_onDataChanged);
    super.dispose();
  }

  Future<void> _initServices() async {
    await _skillPointService.init();
    await _taskService.init();
    if (mounted) setState(() {});
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _onPointTap(SkillPointData point) {
    setState(() {
      // 如果已选中则取消，否则选中
      _selectedPoint = _selectedPoint?.id == point.id ? null : point;
    });
  }

  /// 添加技能点弹窗
  Future<void> _showAddPointDialog() async {
    final result = await SkillPointConfigDialog.show(context);
    if (result == null) return;

    await _skillPointService.addPoint(
      name: result['name'] as String,
      skillId: widget.skillId,
      maxXp: result['maxXp'] as int,
    );
  }

  Future<void> _onTaskConfigConfirm(Map<String, dynamic> result) async {
    if (_selectedPoint == null) return;

    await _taskService.addTask(
      name: result['name'] as String,
      skillId: _selectedPoint!.id,
      skillName: _selectedPoint!.name,
      maxCount: result['maxCount'] as int,
    );

    setState(() {
      _selectedPoint = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final points = _skillPointService.getPointsBySkillId(widget.skillId);
    final hasSelected = _selectedPoint != null;

    return Column(
      children: [
        // 技能点列表区域（选中时缩小以让出空间）
        Flexible(
          flex: hasSelected ? 1 : 1,
          child: SkillPointListContent(
            skillPoints: points,
            title: widget.skillName ?? 'Skill Points',
            titleAction: GestureDetector(
              onTap: _showAddPointDialog,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.add_circle_outline, color: Colors.white70, size: 22),
              ),
            ),
            contentPadding: const EdgeInsets.all(20.0),
            itemSpacing: 12.0,
            onPointTap: _onPointTap,
            cardStyle: const SkillCardStyle(
              borderRadius: 12.0,
              backgroundOpacity: 0.15,
              padding: EdgeInsets.all(16.0),
              iconSize: 24.0,
              titleFontSize: 16.0,
              levelFontSize: 14.0,
              progressBarHeight: 8.0,
              accentColor: Colors.orangeAccent,
            ),
          ),
        ),

        // 任务配置区域（点击技能点后显示，左对齐）
        if (hasSelected)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TaskConfigWidget(
                skillId: _selectedPoint!.id,
                skillName: _selectedPoint!.name,
                onConfirm: _onTaskConfigConfirm,
                onCancel: () => setState(() => _selectedPoint = null),
              ),
            ),
          ),
      ],
    );
  }
}

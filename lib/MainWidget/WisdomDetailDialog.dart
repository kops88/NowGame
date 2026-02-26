import 'package:flutter/material.dart';
import 'package:nowgame/Util/ExpandablePopup.dart';
import 'package:nowgame/MainWidget/SkillDetailCard.dart';
import 'package:nowgame/MainWidget/SkillConfigDialog.dart';
import 'package:nowgame/Model/SkillPointData.dart';
import 'package:nowgame/Service/SkillPointService.dart';
import 'package:nowgame/Service/TaskService.dart';

/// Wisdom 详情弹出层（二级弹窗）
/// 负责：接收技能卡 ID 与 sourceRect，通过 ExpandablePopup 组装弹出层容器，
///       展示该技能卡下属的技能点列表
/// 不负责：动画实现（委托给 ExpandablePopup）、数据持久化（委托给 Service 层）
/// 依赖上游：ExpandablePopup（动画基础设施）
/// 依赖下游：SkillPointListContent（列表渲染）、SkillPointConfigDialog（添加技能点表单）
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
  /// 伪代码思路：
  ///   1. 创建 _WisdomDetailCoordinator 来统一管理"技能点列表区域"和"弹窗下方任务配置区域"的状态
  ///   2. 使用 ExpandablePopup.show 的 contentBuilder 渲染列表，bottomContentBuilder 渲染任务配置
  ///   3. 两个区域通过 _WisdomDetailCoordinator 共享选中状态
  /// [skillId] 技能卡 ID（用于过滤该技能卡下属的技能点）
  /// [skillName] 技能卡名称（用于标题展示）
  static Future<void> show(
    BuildContext context, {
    required Rect sourceRect,
    required String skillId,
    String? skillName,
    VoidCallback? onDismiss,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _WisdomDetailCoordinator(
            sourceRect: sourceRect,
            skillId: skillId,
            skillName: skillName,
            config: _config,
            onDismiss: onDismiss,
          );
        },
      ),
    );
  }
}

/// Wisdom 详情弹窗的交互编排器
/// 负责：统一管理"主卡片内容区域（技能点列表）"和"卡片下方附加区域（任务配置）"的共享状态
/// 不负责：动画（委托给 ExpandablePopup）、数据持久化（委托给 Service 层）
/// 依赖上游：ExpandablePopup（动画容器）
/// 依赖下游：_WisdomDetailContent（列表）、TaskConfigWidget（任务配置表单）
class _WisdomDetailCoordinator extends StatefulWidget {
  final Rect sourceRect;
  final String skillId;
  final String? skillName;
  final ExpandablePopupConfig config;
  final VoidCallback? onDismiss;

  const _WisdomDetailCoordinator({
    required this.sourceRect,
    required this.skillId,
    this.skillName,
    required this.config,
    this.onDismiss,
  });

  @override
  State<_WisdomDetailCoordinator> createState() => _WisdomDetailCoordinatorState();
}

class _WisdomDetailCoordinatorState extends State<_WisdomDetailCoordinator>
    with SingleTickerProviderStateMixin {
  /// 当前选中的技能点（用于在弹窗下方显示任务配置区域）
  SkillPointData? _selectedPoint;

  /// 底部配置区域的展开/收起动画控制器
  /// 伪代码思路：选中技能点时 forward 展开，取消选中时 reverse 收起后再清空 _selectedPoint
  late final AnimationController _bottomAnimController;

  /// 底部配置区域的缩放动画
  late final Animation<double> _bottomScaleAnimation;

  /// 底部配置区域的透明度动画
  late final Animation<double> _bottomOpacityAnimation;

  /// 底部配置区域动画时长配置
  static const _bottomAnimDuration = Duration(milliseconds: 280);
  static const _bottomAnimReverseDuration = Duration(milliseconds: 200);
  static const _bottomAnimCurve = Curves.easeOutCubic;
  static const _bottomAnimReverseCurve = Curves.easeInCubic;

  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _taskService.addListener(_onDataChanged);
    _initTaskService();

    _bottomAnimController = AnimationController(
      duration: _bottomAnimDuration,
      reverseDuration: _bottomAnimReverseDuration,
      vsync: this,
    );

    final curvedAnim = CurvedAnimation(
      parent: _bottomAnimController,
      curve: _bottomAnimCurve,
      reverseCurve: _bottomAnimReverseCurve,
    );

    /// 缩放：从 0.85 放大到 1.0
    _bottomScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnim);

    /// 透明度：从 0.0 渐显到 1.0
    _bottomOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnim);
  }

  @override
  void dispose() {
    _bottomAnimController.dispose();
    _taskService.removeListener(_onDataChanged);
    super.dispose();
  }

  /// Bootstrap 已完成数据加载，直接刷新
  void _initTaskService() {
    if (mounted) setState(() {});
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  /// 点击技能点卡片：切换选中状态并驱动底部配置区域动画
  /// 伪代码思路：
  ///   1. 若点击已选中的同一项 -> 执行收起动画，动画结束后清空 _selectedPoint
  ///   2. 若点击不同项 -> 先收起再切换再展开（若当前已有选中）；或直接设置并展开
  void _onPointTap(SkillPointData point) {
    if (_selectedPoint?.id == point.id) {
      // 取消选中：先播收起动画，结束后清空
      _dismissBottomContent();
    } else if (_selectedPoint != null) {
      // 切换到另一个技能点：先收起，再切换并展开
      _bottomAnimController.reverse().then((_) {
        if (!mounted) return;
        setState(() => _selectedPoint = point);
        _bottomAnimController.forward();
      });
    } else {
      // 首次选中：直接设置并展开
      setState(() => _selectedPoint = point);
      _bottomAnimController.forward();
    }
  }

  /// 收起底部配置区域（动画收起后清空选中状态）
  /// 伪代码思路：reverse 动画 -> 动画结束 -> setState 清空 _selectedPoint
  void _dismissBottomContent() {
    _bottomAnimController.reverse().then((_) {
      if (!mounted) return;
      setState(() => _selectedPoint = null);
    });
  }

  /// 任务配置确认回调
  /// 伪代码思路：
  ///   1. 检查 _selectedPoint 不为 null
  ///   2. 调用 TaskService.addTask 关联到当前选中的技能点
  ///   3. 播放收起动画后清空选中状态
  Future<void> _onTaskConfigConfirm(Map<String, dynamic> result) async {
    if (_selectedPoint == null) return;

    await _taskService.addTask(
      name: result['name'] as String,
      skillId: _selectedPoint!.id,
      skillName: _selectedPoint!.name,
      maxCount: result['maxCount'] as int,
    );

    _dismissBottomContent();
  }

  @override
  Widget build(BuildContext context) {
    final hasSelected = _selectedPoint != null;

    return ExpandablePopup(
      sourceRect: widget.sourceRect,
      config: widget.config,
      onDismiss: widget.onDismiss,
      contentBuilder: (context, animationValue) {
        return _WisdomDetailContent(
          skillId: widget.skillId,
          skillName: widget.skillName,
          animationValue: animationValue,
          onPointTap: _onPointTap,
        );
      },
      /// 附加内容区域：任务配置表单（带缩放+透明度展开动画）
      /// 伪代码思路：当有选中的技能点时，在弹窗下方左对齐显示 TaskConfigWidget，
      ///   并通过 _bottomAnimController 驱动缩放 + 透明度过渡动画
      bottomContentBuilder: hasSelected
          ? (context, animationValue) {
              return AnimatedBuilder(
                animation: _bottomAnimController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _bottomOpacityAnimation.value,
                    child: Transform.scale(
                      scale: _bottomScaleAnimation.value,
                      alignment: Alignment.topCenter,
                      child: child,
                    ),
                  );
                },
                child: TaskConfigWidget(
                  skillId: _selectedPoint!.id,
                  skillName: _selectedPoint!.name,
                  onConfirm: _onTaskConfigConfirm,
                  onCancel: _dismissBottomContent,
                ),
              );
            }
          : null,
    );
  }
}

/// Wisdom 弹出层内容组件（仅技能点列表区域）
/// 负责：渲染技能点列表 + 右上角"+"按钮
/// 不负责：弹窗动画容器（由 ExpandablePopup 管理）、
///         任务配置区域（由 _WisdomDetailCoordinator 通过 bottomContentBuilder 管理）、
///         数据持久化（委托给 Service）
/// 依赖上游：_WisdomDetailCoordinator（提供 onPointTap 回调）
/// 依赖下游：SkillPointService（获取技能点数据）、SkillPointConfigDialog（添加技能点表单）
class _WisdomDetailContent extends StatefulWidget {
  final String skillId;
  final String? skillName;
  final double animationValue;
  final void Function(SkillPointData point) onPointTap;

  const _WisdomDetailContent({
    required this.skillId,
    this.skillName,
    required this.animationValue,
    required this.onPointTap,
  });

  @override
  State<_WisdomDetailContent> createState() => _WisdomDetailContentState();
}

class _WisdomDetailContentState extends State<_WisdomDetailContent> {
  final SkillPointService _skillPointService = SkillPointService();

  /// "+"按钮的 GlobalKey，用于获取动画起点位置
  final GlobalKey _addPointButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _skillPointService.addListener(_onDataChanged);
    _initServices();
  }

  @override
  void dispose() {
    _skillPointService.removeListener(_onDataChanged);
    super.dispose();
  }

  /// Bootstrap 已完成数据加载，直接刷新
  void _initServices() {
    if (mounted) setState(() {});
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  /// 点击二级窗口右上角"+"：通过统一动画弹出技能点配置弹窗
  /// 伪代码思路：
  ///   1. 从 _addPointButtonKey 获取按钮位置（作为动画起点）
  ///   2. 调用 SkillPointConfigDialog.show 弹出统一动画配置弹窗
  ///   3. 若用户确认，调用 SkillPointService.addPoint 持久化
  Future<void> _showAddPointDialog() async {
    final sourceRect = getWidgetRect(_addPointButtonKey);
    if (sourceRect == null) return;

    final result = await SkillPointConfigDialog.show(
      context,
      sourceRect: sourceRect,
    );
    if (result == null) return;

    await _skillPointService.addPoint(
      name: result['name'] as String,
      skillId: widget.skillId,
      maxXp: result['maxXp'] as int,
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = _skillPointService.getPointsBySkillId(widget.skillId);

    return SkillPointListContent(
      skillPoints: points,
      title: widget.skillName ?? 'Skill Points',
      titleAction: _buildAddPointButton(),
      contentPadding: const EdgeInsets.all(20.0),
      itemSpacing: 12.0,
      onPointTap: widget.onPointTap,
      cardStyle: const SkillCardStyle(
        borderRadius: 12.0,
        backgroundOpacity: 0.15,
        padding: EdgeInsets.all(16.0),
        iconSize: 24.0,
        titleFontSize: 16.0,
        levelFontSize: 14.0,
        progressBarHeight: 8.0,
        accentColor: Colors.orangeAccent,
        showLevel: false,
      ),
    );
  }

  /// 构建"+"按钮 Widget
  /// 伪代码思路：使用 Material + InkWell 隔离点击事件，挂载 _addPointButtonKey 获取位置
  Widget _buildAddPointButton() {
    return Material(
      key: _addPointButtonKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _showAddPointDialog,
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.add_circle_outline, color: Colors.white70, size: 22),
        ),
      ),
    );
  }
}

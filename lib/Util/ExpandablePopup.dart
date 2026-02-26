import 'dart:ui';
import 'package:flutter/material.dart';

/// 弹出层动画配置参数
/// 集中管理所有动画相关的可配置参数，避免魔法数散落
/// 被 ExpandablePopup 读取，不感知任何业务实体（技能卡/技能点/任务）
class ExpandablePopupConfig {
  /// 打开动画时长
  final Duration openDuration;
  
  /// 关闭动画时长
  final Duration closeDuration;
  
  /// 打开动画曲线
  final Curve openCurve;
  
  /// 关闭动画曲线
  final Curve closeCurve;
  
  /// 最大模糊强度
  final double maxBlurSigma;
  
  /// 背景遮罩最大透明度
  final double maxOverlayOpacity;
  
  /// 目标位置水平边距
  final double horizontalMargin;
  
  /// 目标位置距顶部比例 (0.0-1.0)
  final double topRatio;
  
  /// 目标高度（null 表示自适应）
  final double? targetHeight;
  
  /// 最大目标高度（自适应时的上限）
  final double? maxTargetHeight;
  
  /// 卡片圆角
  final double cardBorderRadius;
  
  /// 卡片背景色
  final Color cardBackgroundColor;

  /// 是否居中显示（用于配置弹窗等不需要固定 topRatio 的场景）
  /// 伪代码思路：当为 true 时，目标 Rect 以屏幕中心为锚点上下对称分布
  final bool centerVertically;

  const ExpandablePopupConfig({
    this.openDuration = const Duration(milliseconds: 350),
    this.closeDuration = const Duration(milliseconds: 250),
    this.openCurve = Curves.easeOutCubic,
    this.closeCurve = Curves.easeInCubic,
    this.maxBlurSigma = 10.0,
    this.maxOverlayOpacity = 0.3,
    this.horizontalMargin = 24.0,
    this.topRatio = 0.15,
    this.targetHeight,
    this.maxTargetHeight,
    this.cardBorderRadius = 16.0,
    this.cardBackgroundColor = const Color(0xFF1C1C1E),
    this.centerVertically = false,
  });

  /// 创建副本并修改部分参数
  ExpandablePopupConfig copyWith({
    Duration? openDuration,
    Duration? closeDuration,
    Curve? openCurve,
    Curve? closeCurve,
    double? maxBlurSigma,
    double? maxOverlayOpacity,
    double? horizontalMargin,
    double? topRatio,
    double? targetHeight,
    double? maxTargetHeight,
    double? cardBorderRadius,
    Color? cardBackgroundColor,
    bool? centerVertically,
  }) {
    return ExpandablePopupConfig(
      openDuration: openDuration ?? this.openDuration,
      closeDuration: closeDuration ?? this.closeDuration,
      openCurve: openCurve ?? this.openCurve,
      closeCurve: closeCurve ?? this.closeCurve,
      maxBlurSigma: maxBlurSigma ?? this.maxBlurSigma,
      maxOverlayOpacity: maxOverlayOpacity ?? this.maxOverlayOpacity,
      horizontalMargin: horizontalMargin ?? this.horizontalMargin,
      topRatio: topRatio ?? this.topRatio,
      targetHeight: targetHeight ?? this.targetHeight,
      maxTargetHeight: maxTargetHeight ?? this.maxTargetHeight,
      cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
      cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
      centerVertically: centerVertically ?? this.centerVertically,
    );
  }
}

/// 配置弹窗专用的预设配置
/// 伪代码思路：小尺寸、居中、模糊+透明度+缩放动画，适用于"添加技能卡/添加技能点"等表单弹窗
/// 不依赖：任何业务实体，仅提供动画参数预设
const kConfigDialogPopupConfig = ExpandablePopupConfig(
  openDuration: Duration(milliseconds: 300),
  closeDuration: Duration(milliseconds: 200),
  maxBlurSigma: 8.0,
  maxOverlayOpacity: 0.4,
  horizontalMargin: 40.0,
  topRatio: 0.0,
  targetHeight: 400.0,
  cardBorderRadius: 16.0,
  cardBackgroundColor: Color(0xFF2C2C2E),
  centerVertically: true,
);

/// 通用可展开弹出层容器
/// 负责：从 sourceRect 到 targetRect 的插值动画、背景模糊、遮罩、收起动画与 pop
/// 不负责：具体业务内容渲染、数据持久化
/// 不依赖任何具体业务逻辑
class ExpandablePopup extends StatefulWidget {
  /// 原始元素的位置和大小
  final Rect sourceRect;
  
  /// 弹出层内容构建器
  /// 参数：animationValue (0.0-1.0)，可用于内容区域的渐显效果
  final Widget Function(BuildContext context, double animationValue) contentBuilder;

  /// 主卡片下方的附加内容构建器（可选）
  /// 伪代码思路：在主卡片 Positioned 之后额外放置一个 Positioned Widget，
  ///   锚定在主卡片底边下方，与主卡片左对齐、等宽
  /// 使用场景：二级弹窗中点击技能点后，在弹窗下方显示任务配置区域
  /// 不负责：配置区域的具体内容，由调用方提供
  final Widget Function(BuildContext context, double animationValue)? bottomContentBuilder;
  
  /// 动画配置
  final ExpandablePopupConfig config;
  
  /// 关闭回调（在动画结束后、pop 之前调用）
  final VoidCallback? onDismiss;

  const ExpandablePopup({
    super.key,
    required this.sourceRect,
    required this.contentBuilder,
    this.bottomContentBuilder,
    this.config = const ExpandablePopupConfig(),
    this.onDismiss,
  });

  /// 显示弹出层的静态方法
  /// 伪代码思路：创建透明页面路由，将 ExpandablePopup 作为全屏层压入导航栈
  /// [sourceRect] 原始元素的全局位置（动画起点）
  /// [contentBuilder] 内容构建器，接收 animationValue 用于渐显
  /// [config] 动画配置（含居中/非居中策略）
  /// [onDismiss] 关闭回调
  static Future<T?> show<T>(
    BuildContext context, {
    required Rect sourceRect,
    required Widget Function(BuildContext context, double animationValue) contentBuilder,
    Widget Function(BuildContext context, double animationValue)? bottomContentBuilder,
    ExpandablePopupConfig config = const ExpandablePopupConfig(),
    VoidCallback? onDismiss,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ExpandablePopup(
            sourceRect: sourceRect,
            contentBuilder: contentBuilder,
            bottomContentBuilder: bottomContentBuilder,
            config: config,
            onDismiss: onDismiss,
          );
        },
      ),
    );
  }

  /// 显示配置弹窗的便捷方法
  /// 伪代码思路：使用居中预设配置 + 自适应高度，从 sourceRect 出发做模糊+缩放+透明度动画
  /// 不解决：具体表单内容、业务验证，这些交由 contentBuilder 内的 Widget 负责
  /// [sourceRect] 触发按钮的位置（动画起点）
  /// [contentBuilder] 表单内容构建器
  /// [config] 可选覆盖配置，默认使用 kConfigDialogPopupConfig
  static Future<T?> showConfigDialog<T>(
    BuildContext context, {
    required Rect sourceRect,
    required Widget Function(BuildContext context, double animationValue) contentBuilder,
    ExpandablePopupConfig config = kConfigDialogPopupConfig,
    VoidCallback? onDismiss,
  }) {
    return show<T>(
      context,
      sourceRect: sourceRect,
      contentBuilder: contentBuilder,
      config: config,
      onDismiss: onDismiss,
    );
  }

  @override
  State<ExpandablePopup> createState() => ExpandablePopupState();
}

class ExpandablePopupState extends State<ExpandablePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _curvedAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _contentOpacityAnimation;
  
  late Rect _targetRect;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.config.openDuration,
      reverseDuration: widget.config.closeDuration,
      vsync: this,
    );

    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.config.openCurve,
      reverseCurve: widget.config.closeCurve,
    );

    _blurAnimation = Tween<double>(
      begin: 0,
      end: widget.config.maxBlurSigma,
    ).animate(_curvedAnimation);

    // 内容透明度动画：打开时快速显现，关闭时逐渐消失
    _contentOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
        reverseCurve: const Interval(0.0, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateTargetRect();
  }

  /// 计算弹出层的目标 Rect
  /// 伪代码思路：
  ///   1. 根据 config.horizontalMargin 计算目标宽度
  ///   2. 根据 config.targetHeight 或自适应策略计算目标高度
  ///   3. 若 centerVertically=true，则以屏幕中心为锚点上下对称分布
  ///   4. 否则使用 topRatio 计算顶部偏移
  void _calculateTargetRect() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final config = widget.config;

    final targetWidth = screenWidth - config.horizontalMargin * 2;
    
    // 计算目标高度
    double targetHeight;
    if (config.targetHeight != null) {
      targetHeight = config.targetHeight!;
    } else {
      // 自适应高度：默认为屏幕高度的 60%，但不超过 maxTargetHeight
      targetHeight = screenHeight * 0.6;
      if (config.maxTargetHeight != null && targetHeight > config.maxTargetHeight!) {
        targetHeight = config.maxTargetHeight!;
      }
    }

    // 计算顶部偏移
    final double targetTop;
    if (config.centerVertically) {
      // 居中模式：以屏幕中心为锚点
      targetTop = (screenHeight - targetHeight) / 2;
    } else {
      targetTop = screenHeight * config.topRatio;
    }

    _targetRect = Rect.fromLTWH(
      config.horizontalMargin,
      targetTop,
      targetWidth,
      targetHeight,
    );
  }

  /// 关闭弹出层（执行收起动画）
  /// 可供外部调用
  void dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final currentRect = Rect.lerp(
            widget.sourceRect,
            _targetRect,
            _curvedAnimation.value,
          )!;

          return Stack(
            children: [
              // 背景模糊层
              _buildBlurredBackground(currentRect),
              
              // 主内容卡片
              // 使用 ClipRect 裁剪动画过渡中溢出的内容，
              // OverflowBox 让子 widget 以目标尺寸布局（避免 layout overflow 警告），
              // 视觉上由外层 ClipRect 裁剪到 currentRect 大小
              Positioned(
                left: currentRect.left,
                top: currentRect.top,
                width: currentRect.width,
                height: currentRect.height,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    maxWidth: _targetRect.width,
                    maxHeight: _targetRect.height,
                    child: Opacity(
                      opacity: _contentOpacityAnimation.value,
                      child: _buildContentCard(),
                    ),
                  ),
                ),
              ),

              // 附加内容区域（挂载在主卡片下方）
              // 伪代码思路：当 bottomContentBuilder 非 null 时，
              //   在主卡片底边下方 8px 处放置附加内容，与主卡片等宽左对齐
              if (widget.bottomContentBuilder != null)
                Positioned(
                  left: currentRect.left,
                  top: currentRect.top + currentRect.height + 8,
                  width: currentRect.width,
                  child: Opacity(
                    opacity: _contentOpacityAnimation.value,
                    child: widget.bottomContentBuilder!(context, _curvedAnimation.value),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// 构建模糊背景
  Widget _buildBlurredBackground(Rect currentRect) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: dismiss,
        child: Stack(
          children: [
            // 模糊层（排除原始区域）
            ClipPath(
              clipper: InvertedRectClipper(
                excludeRect: widget.sourceRect,
                animationValue: _curvedAnimation.value,
                borderRadius: widget.config.cardBorderRadius,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurAnimation.value,
                  sigmaY: _blurAnimation.value,
                ),
                child: Container(
                  color: Colors.black.withValues(alpha:
                    widget.config.maxOverlayOpacity * _curvedAnimation.value,
                  ),
                ),
              ),
            ),
            // 原始位置的遮罩（动画过程中逐渐显示模糊）
            Positioned.fill(
              child: Opacity(
                opacity: _curvedAnimation.value,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value,
                    sigmaY: _blurAnimation.value,
                  ),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建内容卡片容器
  /// 伪代码思路：用 clipBehavior 裁剪溢出内容，避免动画过渡中出现 overflow 警告
  Widget _buildContentCard() {
    return GestureDetector(
      onTap: () {}, // 阻止点击穿透
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: widget.config.cardBackgroundColor,
          borderRadius: BorderRadius.circular(widget.config.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3 * _curvedAnimation.value),
              blurRadius: 20 * _curvedAnimation.value,
              offset: Offset(0, 10 * _curvedAnimation.value),
            ),
          ],
        ),
        child: widget.contentBuilder(context, _curvedAnimation.value),
      ),
    );
  }
}

/// 自定义裁剪器：排除指定矩形区域的反向裁剪
/// 用于实现"原位置保持清晰，其余区域模糊"的效果
class InvertedRectClipper extends CustomClipper<Path> {
  final Rect excludeRect;
  final double animationValue;
  final double borderRadius;

  InvertedRectClipper({
    required this.excludeRect,
    required this.animationValue,
    this.borderRadius = 16.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    // 添加整个屏幕区域
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 计算需要排除的区域（随动画逐渐缩小到无）
    if (animationValue < 1.0) {
      final shrinkFactor = 1.0 - animationValue;
      final excludeWidth = excludeRect.width * shrinkFactor;
      final excludeHeight = excludeRect.height * shrinkFactor;
      final excludeLeft = excludeRect.left + (excludeRect.width - excludeWidth) / 2;
      final excludeTop = excludeRect.top + (excludeRect.height - excludeHeight) / 2;

      final animatedExcludeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(excludeLeft, excludeTop, excludeWidth, excludeHeight),
        Radius.circular(borderRadius),
      );

      path.addRRect(animatedExcludeRect);
    }

    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(InvertedRectClipper oldClipper) {
    return oldClipper.excludeRect != excludeRect ||
        oldClipper.animationValue != animationValue ||
        oldClipper.borderRadius != borderRadius;
  }
}

/// 用于获取 Widget 全局位置的工具方法
/// 返回 Widget 在屏幕上的 Rect
Rect? getWidgetRect(GlobalKey key) {
  final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return null;
  
  final position = renderBox.localToGlobal(Offset.zero);
  final size = renderBox.size;
  return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
}

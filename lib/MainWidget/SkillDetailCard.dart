import 'package:flutter/material.dart';
import 'package:nowgame/Util/DebugWidget.dart';
import 'package:nowgame/Model/SkillPointData.dart';

/// 技能点卡片样式配置
/// 集中管理样式参数，便于统一调整和复用
class SkillCardStyle {
  /// 卡片圆角
  final double borderRadius;
  
  /// 卡片背景透明度
  final double backgroundOpacity;
  
  /// 卡片内边距
  final EdgeInsets padding;
  
  /// 图标大小
  final double iconSize;
  
  /// 标题字体大小
  final double titleFontSize;
  
  /// 等级字体大小
  final double levelFontSize;
  
  /// 经验条高度
  final double progressBarHeight;
  
  /// 经验条圆角
  final double progressBarRadius;
  
  /// 主题色（用于等级文字、经验条等）
  final Color accentColor;

  const SkillCardStyle({
    this.borderRadius = 12.0,
    this.backgroundOpacity = 0.1,
    this.padding = const EdgeInsets.all(16.0),
    this.iconSize = 24.0,
    this.titleFontSize = 16.0,
    this.levelFontSize = 14.0,
    this.progressBarHeight = 8.0,
    this.progressBarRadius = 4.0,
    this.accentColor = Colors.orangeAccent,
  });
}

/// 单个技能点详情卡片组件
/// 负责展示单个技能点的 icon、标题、等级、经验条等信息
/// 不包含任何路由或动画控制逻辑
class SkillDetailCard extends StatelessWidget {
  final SkillPointData skillPoint;
  final SkillCardStyle style;
  final VoidCallback? onTap;
  final List<Widget>? actions;

  const SkillDetailCard({
    super.key,
    required this.skillPoint,
    this.style = const SkillCardStyle(),
    this.onTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: style.padding,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: style.backgroundOpacity),
          borderRadius: BorderRadius.circular(style.borderRadius),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：图标、标题、等级
            Row(
              children: [
                Icon(skillPoint.icon, color: Colors.white70, size: style.iconSize),
                const SizedBox(width: 12),
                Expanded(
                  child: MText(
                    skillPoint.name,
                    style: TextStyle(
                      fontSize: style.titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: style.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: MText(
                    'Lv. ${skillPoint.level}',
                    style: TextStyle(
                      fontSize: style.levelFontSize,
                      fontWeight: FontWeight.bold,
                      color: style.accentColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 经验条区域
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MText(
                  'Experience',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                MText(
                  '${skillPoint.currentXp} / ${skillPoint.maxXp} XP',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(style.progressBarRadius),
              child: LinearProgressIndicator(
                value: skillPoint.progress,
                backgroundColor: Colors.black26,
                color: style.accentColor,
                minHeight: style.progressBarHeight,
              ),
            ),
            
            // 操作按钮区域（可选）
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 弹出层内容容器组件
/// 负责技能点列表的布局、间距、滚动策略
/// 不包含动画或路由逻辑
class SkillPointListContent extends StatelessWidget {
  /// 技能点数据列表
  final List<SkillPointData> skillPoints;
  
  /// 卡片样式
  final SkillCardStyle cardStyle;
  
  /// 卡片间距
  final double itemSpacing;
  
  /// 内容区域内边距
  final EdgeInsets contentPadding;
  
  /// 标题（可选）
  final String? title;

  /// 标题右侧的操作 Widget（如"+"按钮）
  final Widget? titleAction;
  
  /// 为每个技能点卡片构建操作按钮的回调（可选）
  final List<Widget> Function(SkillPointData point)? actionsBuilder;

  /// 技能点卡片点击回调
  final void Function(SkillPointData point)? onPointTap;

  const SkillPointListContent({
    super.key,
    required this.skillPoints,
    this.cardStyle = const SkillCardStyle(),
    this.itemSpacing = 12.0,
    this.contentPadding = const EdgeInsets.all(16.0),
    this.title,
    this.titleAction,
    this.actionsBuilder,
    this.onPointTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏（可选）
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MText(
                  title!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (titleAction != null) titleAction!,
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // 可滚动的技能点列表
          Expanded(
            child: skillPoints.isEmpty
                ? Center(
                    child: MText(
                      'No skill points yet. Tap + to add one.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: skillPoints.length,
                    separatorBuilder: (_, __) => SizedBox(height: itemSpacing),
                    itemBuilder: (context, index) {
                      final point = skillPoints[index];
                      return SkillDetailCard(
                        skillPoint: point,
                        style: cardStyle,
                        onTap: onPointTap != null ? () => onPointTap!(point) : null,
                        actions: actionsBuilder?.call(point),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

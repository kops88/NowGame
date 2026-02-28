

import 'package:flutter/material.dart';
import 'package:nowgame/Util/DebugWidget.dart';
import 'package:nowgame/Util/ExpandablePopup.dart';
import 'package:nowgame/MainWidget/WisdomDetailDialog.dart';
import 'package:nowgame/MainWidget/SkillConfigDialog.dart';
import 'package:nowgame/Model/SkillData.dart';
import 'package:nowgame/Service/SkillService.dart';

/// MainQuest 主卡片组件（原 Wisdom/Skills）
/// 负责：展示技能卡总览列表、右上角"+"按钮触发添加技能卡、点击技能卡项触发技能点弹窗
/// 不负责：弹窗动画实现（委托给 ExpandablePopup）、数据持久化（委托给 SkillService）
/// 依赖上游：SkillService（数据读取与监听）
/// 依赖下游：WisdomDetailDialog（技能点弹窗）、SkillConfigDialog（添加技能卡弹窗）
class MainQuestSkillsWidget extends StatefulWidget {
  const MainQuestSkillsWidget({Key? key}) : super(key: key);

  @override
  State<MainQuestSkillsWidget> createState() => _MainQuestSkillsWidgetState();
}

class _MainQuestSkillsWidgetState extends State<MainQuestSkillsWidget> {
  final SkillService _skillService = SkillService();

  /// "+"按钮的 GlobalKey，用于获取动画起点位置
  final GlobalKey _addButtonKey = GlobalKey();

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _skillService.addListener(_onDataChanged);
    _initServices();
  }

  @override
  void dispose() {
    _skillService.removeListener(_onDataChanged);
    super.dispose();
  }

  /// Bootstrap 已完成数据加载，直接标记为已初始化
  void _initServices() {
    _initialized = true;
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  /// 点击"+"按钮：通过统一动画弹出添加技能卡配置窗口
  /// 伪代码思路：
  ///   1. 从 _addButtonKey 获取按钮在屏幕上的 Rect（作为动画起点）
  ///   2. 调用 SkillConfigDialog.show 弹出统一动画的配置弹窗
  ///   3. 若用户确认，调用 SkillService.addSkill 持久化
  Future<void> _showAddSkillDialog() async {
    final sourceRect = getWidgetRect(_addButtonKey);
    if (sourceRect == null) return;

    final result = await SkillConfigDialog.show(context, sourceRect: sourceRect);
    if (result == null) return;

    await _skillService.addSkill(
      name: result['name'] as String,
      maxXp: result['maxXp'] as int,
      deadline: result['deadline'] as DateTime?,
    );
  }

  @override
  Widget build(BuildContext context) {
    final skills = _skillService.skills;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const MText(
                'Main Quests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // "+"按钮：使用 Material + InkWell 确保事件隔离，不被外层手势吞噬
              Material(
                key: _addButtonKey,
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _showAddSkillDialog,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.add_circle_outline, color: Colors.white70, size: 24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!_initialized)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (skills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: MText(
                  'No skills yet. Tap + to add.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: skills.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                return _SkillListItem(skill: skills[index]);
              },
            ),
        ],
      ),
    );
  }
}

/// 技能列表项组件（主卡片内的简略展示）
/// 负责：展示单个技能卡的简略信息（图标、名称、时间标签、等级）、点击触发技能点弹窗
/// 不负责：数据管理、弹窗内容渲染
/// 每个技能卡项有独立的 GlobalKey，点击时获取位置作为弹窗动画起点
class _SkillListItem extends StatelessWidget {
  final SkillData skill;

  /// 用于获取点击位置的 GlobalKey
  final GlobalKey _itemKey = GlobalKey();

  _SkillListItem({required this.skill});

  /// 点击技能卡项：弹出该技能卡下的技能点列表
  /// 伪代码思路：从 _itemKey 获取位置 -> 调用 WisdomDetailDialog.show
  void _showSkillPointsDialog(BuildContext context) {
    final sourceRect = getWidgetRect(_itemKey);
    if (sourceRect == null) return;

    WisdomDetailDialog.show(
      context,
      sourceRect: sourceRect,
      skillId: skill.id,
      skillName: skill.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _itemKey,
      onTap: () => _showSkillPointsDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(skill.icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: MText(
                skill.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            // 时间标签（显示在等级左侧）
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: skill.deadlineColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: MText(
                skill.remainingDaysText,
                style: TextStyle(
                  fontSize: 11,
                  color: skill.deadlineColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            MText(
              'Lv. ${skill.level}',
              style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: Colors.white30),
          ],
        ),
      ),
    );
  }
}

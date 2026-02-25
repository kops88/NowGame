

import 'package:flutter/material.dart';
import 'package:nowgame/Util/DebugWidget.dart';
import 'package:nowgame/Util/ExpandablePopup.dart';
import 'package:nowgame/MainWidget/WisdomDetailDialog.dart';
import 'package:nowgame/MainWidget/SkillConfigDialog.dart';
import 'package:nowgame/Model/SkillData.dart';
import 'package:nowgame/Service/SkillService.dart';

/// Wisdom/Skills 主卡片组件
/// 负责展示技能总览、右侧"+"按钮、点击触发弹窗
class WisdomSkillsWidget extends StatefulWidget {
  const WisdomSkillsWidget({Key? key}) : super(key: key);

  @override
  State<WisdomSkillsWidget> createState() => _WisdomSkillsWidgetState();
}

class _WisdomSkillsWidgetState extends State<WisdomSkillsWidget> {
  final SkillService _skillService = SkillService();
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

  Future<void> _initServices() async {
    await _skillService.init();
    if (mounted) setState(() => _initialized = true);
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  /// 点击"+"按钮：弹出添加技能卡弹窗
  Future<void> _showAddSkillDialog() async {
    final result = await SkillConfigDialog.show(context);
    if (result == null) return;

    await _skillService.addSkill(
      name: result['name'] as String,
      maxXp: result['maxXp'] as int,
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
                'Wisdom / Skills',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // "+"按钮：使用 Material + InkWell 确保事件隔离
              Material(
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
/// 每个技能卡有独立的 GlobalKey，点击时弹出该技能卡的技能点弹窗
class _SkillListItem extends StatelessWidget {
  final SkillData skill;

  /// 用于获取点击位置的 GlobalKey
  final GlobalKey _itemKey = GlobalKey();

  _SkillListItem({required this.skill});

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

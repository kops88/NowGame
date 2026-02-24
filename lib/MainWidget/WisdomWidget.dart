
import 'package:flutter/material.dart';
import 'package:nowgame/MainWidget/TimeRingWidget.dart';
import 'package:nowgame/Util/DebugWidget.dart';

class WisdomSkillsWidget extends StatelessWidget {
  const WisdomSkillsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 模拟测试数据
    final skills = [
      SkillData(name: 'English', level: 5, currentXp: 80, requiredXp: 100, icon: Icons.language),
      SkillData(name: 'Python', level: 3, currentXp: 20, requiredXp: 100, icon: Icons.code),
      SkillData(name: 'Reading', level: 12, currentXp: 95, requiredXp: 100, icon: Icons.book),
    ];

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
              const MText('Wisdom / Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                onPressed: () {
                  // TODO: 弹出添加技能悬浮窗
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: skills.length,
            separatorBuilder: (ctx, index) => const SizedBox(height: 8),
            itemBuilder: (ctx, index) {
              return SkillCardWidget(skill: skills[index]);
            },
          ),
        ],
      ),
    );
  }
}

class SkillData {
  final String name;
  final int level;
  final int currentXp;
  final int requiredXp;
  final IconData icon;

  SkillData({
    required this.name, 
    required this.level, 
    required this.currentXp, 
    required this.requiredXp,
    required this.icon,
  });
}

class SkillCardWidget extends StatefulWidget {
  final SkillData skill;

  const SkillCardWidget({Key? key, required this.skill}) : super(key: key);

  @override
  State<SkillCardWidget> createState() => _SkillCardWidgetState();
}

class _SkillCardWidgetState extends State<SkillCardWidget> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpand,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: _isExpanded ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: _isExpanded ? Border.all(color: Colors.white24) : Border.all(color: Colors.transparent),
        ),
        child: Column(
          children: [
            // 头部：折叠状态展示
            Row(
              children: [
                Icon(widget.skill.icon, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: MText(
                    widget.skill.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                MText(
                  'Lv. ${widget.skill.level}',
                  style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.white30,
                ),
              ],
            ),
            
            // 展开部分：经验条详情
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(), // 折叠时高度为0
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MText(
                          'Experience',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                        ),
                        MText(
                          '${widget.skill.currentXp} / ${widget.skill.requiredXp} XP',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: widget.skill.currentXp / widget.skill.requiredXp,
                        backgroundColor: Colors.black26,
                        color: Colors.orange,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 模拟操作按钮 (打卡/阅读)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            // TODO: 增加经验逻辑
                          },
                          icon: const Icon(Icons.timer, size: 16),
                          label: const MText('Practice'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}
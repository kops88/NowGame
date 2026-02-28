import 'package:flutter/material.dart';
import 'package:nowgame/Util/DebugWidget.dart';
import 'package:nowgame/Util/ExpandablePopup.dart';

/// 技能卡配置弹窗
/// 负责：收集"添加技能卡"所需的表单数据（名称、经验值上限）
/// 不负责：动画控制（委托给 ExpandablePopup）、数据持久化（由调用方通过返回值处理）
/// 依赖上游：ExpandablePopup（动画基础设施）
/// 依赖下游：无
class SkillConfigDialog {
  SkillConfigDialog._();

  /// 通过统一动画弹窗显示技能卡配置表单
  /// 伪代码思路：
  ///   1. 使用 ExpandablePopup.showConfigDialog 从 sourceRect 位置弹出
  ///   2. 内部渲染 _ConfigFormContent 表单
  ///   3. 用户确认后通过 Navigator.pop 返回 {name, maxXp}
  ///   4. 用户取消则返回 null
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required Rect sourceRect,
  }) {
    return ExpandablePopup.showConfigDialog<Map<String, dynamic>>(
      context,
      sourceRect: sourceRect,
      contentBuilder: (ctx, animationValue) {
        return _SkillConfigFormContent(animationValue: animationValue);
      },
    );
  }
}

/// 技能卡配置表单内容
/// 负责：渲染表单字段（名称、最大XP、截止日期）、验证输入、返回结果
/// 不负责：动画、弹窗容器、数据持久化
class _SkillConfigFormContent extends StatefulWidget {
  final double animationValue;

  const _SkillConfigFormContent({required this.animationValue});

  @override
  State<_SkillConfigFormContent> createState() => _SkillConfigFormContentState();
}

class _SkillConfigFormContentState extends State<_SkillConfigFormContent> {
  final _nameController = TextEditingController();
  final _maxXpController = TextEditingController(text: '100');
  final _formKey = GlobalKey<FormState>();

  /// 用户选择的截止日期（null 表示永久任务）
  DateTime? _selectedDeadline;

  @override
  void dispose() {
    _nameController.dispose();
    _maxXpController.dispose();
    super.dispose();
  }

  /// 验证并返回表单数据
  /// 伪代码思路：校验 formKey -> 组装 Map（含 deadline） -> pop 返回
  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'maxXp': int.tryParse(_maxXpController.text.trim()) ?? 100,
      'deadline': _selectedDeadline,
    });
  }

  /// 弹出日期选择器
  /// 伪代码思路：showDatePicker -> 选中后更新 _selectedDeadline 并 setState
  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _selectedDeadline = date);
    }
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
                'Add Skill',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              ConfigFormField(
                label: 'Skill Name',
                controller: _nameController,
                hintText: 'Enter skill name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ConfigFormField(
                label: 'Max XP',
                controller: _maxXpController,
                hintText: '100',
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
              // 截止日期选择区域
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deadline (optional)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickDeadline,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedDeadline != null
                                  ? '${_selectedDeadline!.year}-${_selectedDeadline!.month.toString().padLeft(2, '0')}-${_selectedDeadline!.day.toString().padLeft(2, '0')}'
                                  : '永久任务（点击选择截止日期）',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedDeadline != null
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          if (_selectedDeadline != null)
                            GestureDetector(
                              onTap: () => setState(() => _selectedDeadline = null),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.close, size: 16, color: Colors.white54),
                              ),
                            )
                          else
                            const Icon(Icons.calendar_today, size: 16, color: Colors.white38),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
}

/// 技能点配置弹窗
/// 负责：收集"添加技能点"所需的表单数据（名称、经验值上限）
/// 不负责：动画控制（委托给 ExpandablePopup）、数据持久化
/// 依赖上游：ExpandablePopup（动画基础设施）
/// 依赖下游：无
class SkillPointConfigDialog {
  SkillPointConfigDialog._();

  /// 通过统一动画弹窗显示技能点配置表单
  /// 伪代码思路：
  ///   1. 使用 ExpandablePopup.showConfigDialog 从 sourceRect 位置弹出
  ///   2. 内部渲染 _SkillPointConfigFormContent 表单
  ///   3. 确认返回 {name, maxXp}，取消返回 null
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required Rect sourceRect,
  }) {
    return ExpandablePopup.showConfigDialog<Map<String, dynamic>>(
      context,
      sourceRect: sourceRect,
      contentBuilder: (ctx, animationValue) {
        return _SkillPointConfigFormContent(animationValue: animationValue);
      },
    );
  }
}

/// 技能点配置表单内容
/// 负责：渲染表单字段（名称、最大XP）、验证输入、返回结果
/// 不负责：动画、弹窗容器、数据持久化
class _SkillPointConfigFormContent extends StatefulWidget {
  final double animationValue;

  const _SkillPointConfigFormContent({required this.animationValue});

  @override
  State<_SkillPointConfigFormContent> createState() => _SkillPointConfigFormContentState();
}

class _SkillPointConfigFormContentState extends State<_SkillPointConfigFormContent> {
  final _nameController = TextEditingController();
  final _maxXpController = TextEditingController(text: '100');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _maxXpController.dispose();
    super.dispose();
  }

  /// 验证并返回表单数据
  /// 伪代码思路：校验 formKey -> 组装 Map -> pop 返回
  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'maxXp': int.tryParse(_maxXpController.text.trim()) ?? 100,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MText(
              'Add Skill Point',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            ConfigFormField(
              label: 'Point Name',
              controller: _nameController,
              hintText: 'Enter skill point name',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ConfigFormField(
              label: 'Max XP',
              controller: _maxXpController,
              hintText: '100',
              keyboardType: TextInputType.number,
              validator: (value) {
                final num = int.tryParse(value ?? '');
                if (num == null || num <= 0) {
                  return 'Must be a positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 任务配置组件
/// 负责：收集"添加任务"所需的表单数据（名称、最大次数）
/// 不负责：弹窗动画、数据持久化（通过 onConfirm 回调返回数据给调用方处理）
/// 使用场景：嵌入到弹窗下方的内联配置区域（非独立弹窗）
/// 依赖上游：调用方提供的 skillId/skillName
/// 依赖下游：无
class TaskConfigWidget extends StatefulWidget {
  /// 关联的技能点 ID
  final String skillId;

  /// 关联的技能点名称（用于展示）
  final String skillName;

  /// 确认回调，返回 {name, maxCount}
  final void Function(Map<String, dynamic> result) onConfirm;

  /// 取消回调
  final VoidCallback onCancel;

  const TaskConfigWidget({
    super.key,
    required this.skillId,
    required this.skillName,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<TaskConfigWidget> createState() => _TaskConfigWidgetState();
}

class _TaskConfigWidgetState extends State<TaskConfigWidget> {
  final _nameController = TextEditingController();
  final _maxCountController = TextEditingController(text: '10');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _maxCountController.dispose();
    super.dispose();
  }

  /// 验证并通过回调返回表单数据
  /// 伪代码思路：校验 formKey -> 组装 Map -> 调用 widget.onConfirm
  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;

    widget.onConfirm({
      'name': _nameController.text.trim(),
      'maxCount': int.tryParse(_maxCountController.text.trim()) ?? 10,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MText(
              'Add Task for ${widget.skillName}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            ConfigFormField(
              label: 'Task Name',
              controller: _nameController,
              hintText: 'Enter task name',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            ConfigFormField(
              label: 'Max Count',
              controller: _maxCountController,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 可复用的配置表单字段组件
/// 负责：渲染单个"标签 + 输入框"组合，支持验证
/// 不负责：表单整体布局、确认/取消按钮
/// 被以下组件使用：SkillConfigDialog、SkillPointConfigDialog、TaskConfigWidget
class ConfigFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const ConfigFormField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
}

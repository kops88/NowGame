import 'package:flutter/material.dart';
import 'package:nowgame/Util/DebugWidget.dart';
import 'package:nowgame/Model/TaskData.dart';
import 'package:nowgame/Service/TaskService.dart';

/// 任务卡片样式配置
class TaskCardStyle {
  /// 卡片圆角
  final double borderRadius;

  /// 进度条颜色
  final Color progressColor;

  /// 进度条高度
  final double progressBarHeight;

  /// 卡片背景色
  final Color backgroundColor;

  /// 卡片内边距
  final EdgeInsets padding;

  const TaskCardStyle({
    this.borderRadius = 4.0,
    this.progressColor = const Color(0xFF4CAF50),
    this.progressBarHeight = 6.0,
    this.backgroundColor = const Color(0xFF1E1E1E),
    this.padding = const EdgeInsets.all(12.0),
  });
}

/// 单个任务卡片组件
/// 方形四角、icon + 名称 + 绿色进度条
/// 点击增加完成次数
class TaskCard extends StatelessWidget {
  final TaskData task;
  final TaskCardStyle style;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TaskCard({
    super.key,
    required this.task,
    this.style = const TaskCardStyle(),
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: style.padding,
        decoration: BoxDecoration(
          color: style.backgroundColor,
          borderRadius: BorderRadius.circular(style.borderRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上部：icon + 名称 + 进度文字
            Row(
              children: [
                Icon(
                  IconData(task.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: style.progressColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MText(
                    task.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                MText(
                  '${task.currentCount} / ${task.maxCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: task.progress,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                color: task.isCompleted
                    ? style.progressColor.withValues(alpha: 0.5)
                    : style.progressColor,
                minHeight: style.progressBarHeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 主页底部任务卡片列表区域
/// 负责展示所有任务卡片，支持动态增减和滚动
class TaskCardList extends StatefulWidget {
  const TaskCardList({super.key});

  @override
  State<TaskCardList> createState() => _TaskCardListState();
}

class _TaskCardListState extends State<TaskCardList> {
  final TaskService _taskService = TaskService();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _taskService.addListener(_onDataChanged);
    _initService();
  }

  @override
  void dispose() {
    _taskService.removeListener(_onDataChanged);
    super.dispose();
  }

  Future<void> _initService() async {
    await _taskService.init();
    if (mounted) setState(() => _initialized = true);
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onTaskTap(TaskData task) async {
    if (task.isCompleted) return;
    await _taskService.incrementCount(task.id);
  }

  Future<void> _onTaskLongPress(TaskData task) async {
    // 长按删除确认
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text('Delete Task', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${task.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _taskService.removeTask(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();

    final tasks = _taskService.tasks;
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: MText(
            'Tasks',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final task = tasks[index];
            return TaskCard(
              task: task,
              onTap: () => _onTaskTap(task),
              onLongPress: () => _onTaskLongPress(task),
            );
          },
        ),
      ],
    );
  }
}

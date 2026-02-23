import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '人生卷轴',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),
      home: Scaffold(
        body: DashboardScreen(),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('主页', style: TextStyle(color: Colors.white)),
        ),
      body: SafeArea(
        // 使用 ListView 构建垂直滚动的卡片流
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: const [
              // 1. 顶部核心区：时间 (5层同心圆环)
              TimeRingsWidget(),
              SizedBox(height: 16),

              // 2. 数据监控区：金钱 & 影响力 (网格布局)
              // 文档变更：原健康放在此处，现根据最新UI文档调整：
              // 第二行是 金钱和影响力
              MoneyAndInfluenceRow(),
              SizedBox(height: 16),

              // 3. 成长系统：智慧 (技能列表)
              WisdomSkillsWidget(),
              SizedBox(height: 16),
              
              // 补充：健康卡片 (根据设计大纲，健康也是核心监控区，
              // 虽然UI文档没明确提第二行包含健康，但通常建议保留或放下放，
              // 这里暂按大纲逻辑补全，或按需调整顺序)
              HealthCardWidget(),
              SizedBox(height: 16),

              // 4. 底部行动区：主线任务
              MainQuestListWidget(),
              SizedBox(height: 32), // 底部留白
            ],
          ),
        ),
        bottomNavigationBar: Container(
          color: Colors.grey,
          height: 65,
          child: Center(
            child: Text('底部区域'),
          ),
        ),
      );
  }
}

// -----------------------------------------------------------------------------
// 1. 时间模块：TimeRingsWidget (CustomPainter 实现)
// -----------------------------------------------------------------------------
class TimeRingsWidget extends StatelessWidget {
  const TimeRingsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 模拟测试数据 (0.0 - 1.0)
    final progressData = [
      0.35, // 人生进度 (红) - 假设35岁/80岁
      0.75, // 今年进度 (橙) - 假设9月
      0.60, // 本月进度 (黄) - 假设20号
      0.40, // 本周进度 (绿) - 假设周三
      0.80, // 今日进度 (青) - 假设晚上
    ];

    // 环的颜色定义
    final ringColors = [
      const Color(0xFFD32F2F), // Life: 深红
      Colors.orange,           // Year: 橙色
      Colors.yellow,           // Month: 黄色
      Colors.green,            // Week: 绿色
      Colors.cyan,             // Day: 青色/蓝色
    ];

    return Container(
      height: 320, // 稍微增加高度以容纳圆环
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 自定义绘制层
          CustomPaint(
            size: const Size(280, 280), // 画布大小
            painter: TimeRingsPainter(
              progressData: progressData,
              ringColors: ringColors,
              backgroundColor: const Color(0xFF2C2C2C), // 深灰色底色
            ),
          ),
          // 中心文案
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Today',
                style: TextStyle(color: Colors.white30, fontSize: 12),
              ),
              Text(
                '4h left', // 模拟倒计时
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 24, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TimeRingsPainter extends CustomPainter {
  final List<double> progressData;
  final List<Color> ringColors;
  final Color backgroundColor;

  TimeRingsPainter({
    required this.progressData,
    required this.ringColors,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    const strokeWidth = 18.0; // 环的粗细，文档要求稍微粗一些
    const gap = 4.0;          // 环之间的间距

    // 从外向内绘制，最外层是第0个数据
    for (int i = 0; i < progressData.length; i++) {
      final radius = maxRadius - (i * (strokeWidth + gap));
      final progress = progressData[i].clamp(0.0, 1.0); // 确保在 0~1 之间
      final color = ringColors[i];

      // 1. 绘制底色环 (未完成部分)
      final bgPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, bgPaint);

      // 2. 绘制进度环 (已完成部分)
      // -pi/2 是 12点钟方向
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * 3.141592653589793 * progress;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.141592653589793 / 2, // 起始角度：12点钟
        sweepAngle,             // 扫过角度
        false,                  // useCenter: false (空心)
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TimeRingsPainter oldDelegate) {
    return oldDelegate.progressData != progressData;
  }
}

// -----------------------------------------------------------------------------
// 2. 金钱 & 影响力模块：MoneyAndInfluenceRow
// -----------------------------------------------------------------------------
class MoneyAndInfluenceRow extends StatelessWidget {
  const MoneyAndInfluenceRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 金钱卡片
        Expanded(
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2), // 蓝色圆角背景
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.attach_money, color: Colors.blue),
                SizedBox(height: 8),
                Text('Money', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Monthly Salary', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 影响力卡片
        Expanded(
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2), // 灰色背景
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.lock_outline, color: Colors.grey),
                SizedBox(height: 8),
                Text('Influence', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Locked (Lv.10)', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 3. 智慧模块：WisdomSkillsWidget (AnimatedSize 展开/折叠)
// -----------------------------------------------------------------------------
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
              const Text('Wisdom / Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  child: Text(
                    widget.skill.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
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
                        Text(
                          'Experience',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                        ),
                        Text(
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
                          label: const Text('Practice'),
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

// -----------------------------------------------------------------------------
// 补充：健康模块：HealthCardWidget (fl_chart 实现)
// -----------------------------------------------------------------------------
class HealthCardWidget extends StatelessWidget {
  const HealthCardWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 随机生成 7 天的数据 (60-98之间)
    final random = Random();
    final dataPoints = List.generate(10, (index) {
      return FlSpot(index.toDouble(), 60 + random.nextDouble() * 38);
    });

    return Container(
      height: 220, // 稍微增加高度
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // 标题栏
          Row(
            children: const [
              Icon(Icons.favorite, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Health', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          
          // 折线图区域
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false), // 不显示网格
                titlesData: FlTitlesData(show: false), // 不显示轴标题
                borderData: FlBorderData(show: false), // 不显示边框
                minX: 0,
                maxX: 9,
                minY: 50,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: dataPoints,
                    isCurved: true, // 平滑曲线
                    color: Colors.redAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false), // 不显示数据点
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.redAccent.withOpacity(0.1), // 红色渐变填充
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 底部统计信息
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Avg', '85', isPrimary: true),
              _buildStatItem('Max', '98'),
              _buildStatItem('Min', '60'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool isPrimary = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isPrimary ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white30,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 4. 主线任务模块：MainQuestListWidget
// -----------------------------------------------------------------------------
class MainQuestListWidget extends StatelessWidget {
  const MainQuestListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Main Quests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        // 模拟任务列表
        _buildQuestItem(Icons.fitness_center, 'Lose 5kg', '31 days left', 0.3),
        const SizedBox(height: 12),
        _buildQuestItem(Icons.book, 'PMP Certificate', '12 days left', 0.7),
      ],
    );
  }

  Widget _buildQuestItem(IconData icon, String title, String deadline, double progress) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // 左侧图标
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white70),
          ),
          const SizedBox(width: 16),
          // 中间标题与进度条
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.black,
                  color: Colors.greenAccent,
                  minHeight: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 右侧倒计时
          Text(deadline, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
        ],
      ),
    );
  }
}

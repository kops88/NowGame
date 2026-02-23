import 'package:flutter/material.dart';

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
// 3. 智慧模块：WisdomSkillsWidget
// -----------------------------------------------------------------------------
class WisdomSkillsWidget extends StatelessWidget {
  const WisdomSkillsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            children: const [
              Text('Wisdom / Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(Icons.add_circle_outline, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 16),
          // 模拟技能列表项占位
          _buildSkillPlaceholder('English', 'Lv. 5'),
          const SizedBox(height: 8),
          _buildSkillPlaceholder('Flutter', 'Lv. 3'),
          const SizedBox(height: 8),
          _buildSkillPlaceholder('Reading', 'Lv. 12'),
        ],
      ),
    );
  }

  Widget _buildSkillPlaceholder(String name, String level) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Text(level, style: const TextStyle(color: Colors.orangeAccent)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 补充：健康模块：HealthCardWidget
// -----------------------------------------------------------------------------
class HealthCardWidget extends StatelessWidget {
  const HealthCardWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.favorite, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Health', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Expanded(
            child: Center(
              child: Text(
                '[Chart Placeholder]\nHeart Rate / Mood Graph',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white30),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('Avg: 85', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Max: 98', style: TextStyle(fontSize: 12, color: Colors.white70)),
              Text('Min: 60', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ],
      ),
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

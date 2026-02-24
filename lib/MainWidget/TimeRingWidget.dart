import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:nowgame/Util/DebugWidget.dart';

const Color LifeTimeColor = Color(0xFFD32F2F);
const Color YearTimeColor = Colors.orange;
const Color MonthTimeColor = Colors.yellow;
const Color WeekTimeColor = Colors.cyan;
const Color DayTimeColor = Colors.green;


const strokeWidth = 18.0; // 环的粗细，文档要求稍微粗一些
const gap = 4.0;          // 环之间的间距

const double GrayDensity = 0.7; // 圆环未完成部分的灰度
const double RadiusRatio = 2.7; // 圆环半径 = size.width / RadiusRatio



class TimeRingsWidget extends StatelessWidget {
  const TimeRingsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // 本日
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final dayTotalSeconds = endOfDay.difference(startOfDay).inSeconds.toDouble();
    final dayPassedSeconds = now.difference(startOfDay).inSeconds.toDouble();
    final dayProgress = (dayPassedSeconds / dayTotalSeconds).clamp(0.0, 1.0);
    final dayRemainHours = endOfDay.difference(now).inHours;

    // 本周（以周一为一周开始）
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final weekTotalSeconds = endOfWeek.difference(startOfWeek).inSeconds.toDouble();
    final weekPassedSeconds = now.difference(startOfWeek).inSeconds.toDouble();
    final weekProgress = (weekPassedSeconds / weekTotalSeconds).clamp(0.0, 1.0);
    final weekRemainDays = (7 - now.weekday).clamp(0, 7);

    // 本月
    int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    final monthTotalSeconds = endOfMonth.difference(startOfMonth).inSeconds.toDouble();
    final monthPassedSeconds = now.difference(startOfMonth).inSeconds.toDouble();
    final monthProgress = (monthPassedSeconds / monthTotalSeconds).clamp(0.0, 1.0);
    final monthDays = daysInMonth(now.year, now.month);
    final monthRemainDays = (monthDays - now.day).clamp(0, monthDays) as int;

    

    // 年剩余（按日）：从今日零点到明年1月1日
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year + 1, 1, 1);
    final yearTotalDays = endOfYear.difference(startOfYear).inDays;
    final yearRemainDays = endOfYear.difference(DateTime(now.year, now.month, now.day)).inDays.clamp(0, yearTotalDays);
    final yearRemainRatio = (yearRemainDays / yearTotalDays).clamp(0.0, 1.0);

    // 人生剩余（按日）：目标寿命70岁，生日2002-07-15
    final birthDate = DateTime(2002, 7, 15);
    final lifeEnd = DateTime(2002 + 70, 7, 15);
    final lifeTotalDays = lifeEnd.difference(birthDate).inDays;
    final lifeRemainDays = lifeEnd.difference(DateTime(now.year, now.month, now.day)).inDays.clamp(0, lifeTotalDays);
    final lifeRemainRatio = (lifeRemainDays / lifeTotalDays).clamp(0.0, 1.0);

  // 进度数组（外-中-内）：月、周、日
    final remainRatios = [
      lifeRemainRatio.clamp(0.0, 1.0),
      yearRemainRatio.clamp(0.0, 1.0),
      (1 - monthProgress).clamp(0.0, 1.0),
      (1 - weekProgress).clamp(0.0, 1.0),
      (1 - dayProgress).clamp(0.0, 1.0),
    ];
    // 环的颜色定义
    final ringColors = [
      LifeTimeColor,
      YearTimeColor,
      MonthTimeColor,           // Month: 黄色
      WeekTimeColor,            // Week: 绿色
      DayTimeColor,             // Day: 青色/蓝色
    ];

    final totals = [lifeTotalDays, yearTotalDays, monthDays, 7, 24];
    final remain = [lifeRemainDays, yearRemainDays, monthRemainDays, weekRemainDays, dayRemainHours];

    return Container(
      // height: 260,
      // padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Row(
          children: [
            Expanded(
                child: CustomPaint(
                    size: const Size(220, 220),
                    painter: TimeRingsPainter(
                      remainRatios: remainRatios,
                      ringColors: ringColors,
                    ),
                 ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatLine('人生', '${remain[0]}/${totals[0]}', '天', LifeTimeColor),
                    const SizedBox(height: 12),
                    _buildStatLine('本年', '${remain[1]}/${totals[1]}', '天', YearTimeColor),
                    const SizedBox(height: 12),
                    _buildStatLine('本月', '${remain[2]}/${totals[2]}', '天', MonthTimeColor),
                    const SizedBox(height: 12),
                    _buildStatLine('本周', '${remain[3]}/${totals[3]}', '天', WeekTimeColor),
                    const SizedBox(height: 12),
                    _buildStatLine('今日', '${remain[4]}/${totals[4]}', '小时', DayTimeColor),
                  ],
                ),
            ),
          ],
        ),
      )
    );
  }
}

class TimeRingsPainter extends CustomPainter {
  final List<double> remainRatios;
  final List<Color> ringColors; // 进度颜色

  TimeRingsPainter({
    required this.remainRatios,
    required this.ringColors,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final CirclePosition = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / RadiusRatio;

    // 从外向内绘制，最外层是第0个数据
    for (int i = 0; i < remainRatios.length; i++) {
      final radius = maxRadius - (i * (strokeWidth + gap));
      final remainRatio = remainRatios[i].clamp(0.0, 1.0);
      final color = ringColors[i];

      // 1. 绘制底色环 (已过去部分)
      final bgPaint = Paint()
        // 使用原色加入灰度，形成已过去段的“低饱和版本”
        ..color = _dimRingColor(color)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(CirclePosition, radius, bgPaint);

      // 2. 绘制剩余环 (高亮部分) 逆时针倒扣
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = -2 * math.pi * remainRatio;
      
      canvas.drawArc(
        Rect.fromCircle(center: CirclePosition, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,                  // useCenter: false (空心)
        progressPaint,
      );

      // 3. 在圆环开头(12点方向)绘制字母标记（M/W/D）
      final startAngle = -math.pi / 2;
      final labelRadius = radius - (strokeWidth / 2) - 4; // 放在环内侧一点
      final pos = Offset(
        CirclePosition.dx + labelRadius * math.cos(startAngle),
        CirclePosition.dy + labelRadius * math.sin(startAngle),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TimeRingsPainter oldDelegate) {
    return oldDelegate.remainRatios != remainRatios;
  }
}
Color _dimRingColor(Color base) {
  // 将原色与深灰做线性插值，得到“加灰度”的颜色
  return Color.lerp(base, const Color(0xFF2C2C2C), GrayDensity)!;
}
Widget _buildStatLine(String label, String value, String unit, Color color) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MText(
        label,
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.left,
      ),
      RichText(
        textAlign: TextAlign.left,
        text: TextSpan(
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: unit,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _VerticalRemainBar extends StatelessWidget {
  final String label;
  final int remainDays;
  final int totalDays;
  final double ratio;
  final Color color;

  const _VerticalRemainBar({
    Key? key,
    required this.label,
    required this.remainDays,
    required this.totalDays,
    required this.ratio,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double barWidth = 12;
    const double barHeight = 120;
    final double fillHeight = barHeight * ratio;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MText(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: _dimRingColor(color),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Container(
              width: barWidth,
              height: fillHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        MText(
          '$remainDays/$totalDays 天',
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ],
    );
  }
}

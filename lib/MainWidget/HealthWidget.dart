import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nowgame/Util/DebugWidget.dart';
import 'package:nowgame/MainWidget/ChartDetailDialog.dart';

class HealthCardWidget extends StatefulWidget {
  const HealthCardWidget({Key? key}) : super(key: key);

  @override
  State<HealthCardWidget> createState() => _HealthCardWidgetState();
}

class _HealthCardWidgetState extends State<HealthCardWidget> {
  late List<FlSpot> _dataPoints;
  final GlobalKey _chartKey = GlobalKey(); // 用于获取折线图位置

  @override
  void initState() {
    super.initState();
    _generateData();
  }

  void _generateData() {
    final random = Random();
    _dataPoints = List.generate(10, (index) {
      return FlSpot(index.toDouble(), 60 + random.nextDouble() * 38);
    });
  }

  void _showChartDetail() {
    // 获取折线图的全局位置和尺寸
    final RenderBox? box =
        _chartKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Offset position = box.localToGlobal(Offset.zero);
    final Size size = box.size;
    final Rect sourceRect =
        Rect.fromLTWH(position.dx, position.dy, size.width, size.height);

    ChartDetailDialog.show(
      context,
      dataPoints: _dataPoints,
      sourceRect: sourceRect,
      onDataChanged: (newData) {
        setState(() {
          _dataPoints = newData;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420, // 增加卡片高度，让折线图有更大的显示空间
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
              MText('Health', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          
          // 折线图区域 - 点击触发弹出层
          Expanded(
            child: GestureDetector(
              key: _chartKey, // 添加 GlobalKey 以获取位置
              behavior: HitTestBehavior.opaque,
              onTap: _showChartDetail,
              child: AbsorbPointer(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false), // 禁用图表触摸
                    minX: 0,
                    maxX: 9,
                    minY: 0,   // Y轴最小值固定为 0
                    maxY: 100, // Y轴最大值固定为 100
                    clipData: const FlClipData.all(), // 裁剪超出范围的数据
                    lineBarsData: [
                      LineChartBarData(
                        spots: _dataPoints, 
                        isCurved: true,
                        color: Colors.pinkAccent,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          // 设置填充的截止位置（阈值）
                          cutOffY: 0.0,
                          applyCutOffY: true,
                          // 三段式渐变填充（与放大后一致）
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.pinkAccent.withValues(alpha: 0.4), // 顶部最深色
                              Colors.pinkAccent.withValues(alpha: 0.2), // 顶部区域末尾
                              Colors.pinkAccent.withValues(alpha: 0.0), // 中间区域末尾（渐变到透明）
                              Colors.pinkAccent.withValues(alpha: 0.0), // 底部区域开始（保持透明）
                            ],
                            stops: const [0.0, 0.5, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
        MText(
          value,
          style: TextStyle(
            fontSize: isPrimary ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        MText(
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
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nowgame/MainWidget/HealthWidget.dart';
import 'package:nowgame/MainWidget/MainQuestWidget.dart';
import 'package:nowgame/MainWidget/MoneyAndInfluence.dart';
import 'dart:math';
import 'package:nowgame/MainWidget/TimeRingWidget.dart';
import 'package:nowgame/MainWidget/WisdomWidget.dart';

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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: const [
              // 1
              TimeRingsWidget(),
              SizedBox(height: 16),
              // 2 金钱和影响力
              MoneyAndInfluenceRow(),
              SizedBox(height: 16),
              // 3. 成长系统：智慧 (技能列表)
              WisdomSkillsWidget(),
              SizedBox(height: 16),
              // 4
              HealthCardWidget(),
              SizedBox(height: 16),
              // 5. 底部行动区：主线任务
              MainQuestListWidget(),
              SizedBox(height: 32),
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


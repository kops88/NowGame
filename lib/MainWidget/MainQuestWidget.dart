import 'package:flutter/material.dart';
import 'package:nowgame/Util/DebugWidget.dart';

class MainQuestListWidget extends StatelessWidget {
  const MainQuestListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: MText('Main Quests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                MText(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          MText(deadline, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
        ],
      ),
    );
  }
}
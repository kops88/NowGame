import 'package:flutter/material.dart';

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
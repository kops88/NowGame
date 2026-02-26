/*
 * @Author: v_lyyulliu v_lyyulliu@tencent.com
 * @Date: 2026-02-24 11:51:04
 * @LastEditors: v_lyyulliu v_lyyulliu@tencent.com
 * @LastEditTime: 2026-02-26 14:13:57
 * @FilePath: \NowGame\lib\Util\DebugWidget.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';

/// 包装 Text 组件，用于 debug 时显示占位符
class MText extends StatelessWidget {
  static const bool _debugMode = false; // 内部 debug 开关

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;

  const MText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      _debugMode ? '\$\$' : data,
      style: style,
      textAlign: textAlign,
    );
  }
}
import 'package:flutter/material.dart';

/// 包装 Text 组件，用于 debug 时显示占位符
class MText extends StatelessWidget {
  static const bool _debugMode = true; // 内部 debug 开关

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
/*
 * @Author: v_lyyulliu v_lyyulliu@tencent.com
 * @Date: 2026-02-24 12:18:06
 * @LastEditors: v_lyyulliu v_lyyulliu@tencent.com
 * @LastEditTime: 2026-02-24 15:48:39
 * @FilePath: \NowGame\lib\MainWidget\ChartDetailDialog.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nowgame/Model/DayHealthData.dart';
import 'package:nowgame/Service/HealthService.dart';

/// iOS 风格的图表详情弹出层 - Hero 风格展开/收起动画
class ChartDetailDialog extends StatefulWidget {
  final List<FlSpot> dataPoints;
  final Rect sourceRect; // 原始折线图的位置和大小
  final ValueChanged<List<FlSpot>>? onDataChanged; // 数据变更回调

  const ChartDetailDialog({
    super.key,
    required this.dataPoints,
    required this.sourceRect,
    this.onDataChanged,
  });

  /// 显示弹出层的静态方法
  static Future<void> show(
    BuildContext context, {
    required List<FlSpot> dataPoints,
    required Rect sourceRect,
    ValueChanged<List<FlSpot>>? onDataChanged,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ChartDetailDialog(
            dataPoints: dataPoints,
            sourceRect: sourceRect,
            onDataChanged: onDataChanged,
          );
        },
      ),
    );
  }

  @override
  State<ChartDetailDialog> createState() => _ChartDetailDialogState();
}

class _ChartDetailDialogState extends State<ChartDetailDialog>
    with SingleTickerProviderStateMixin {
  // 深色主题颜色
  static const Color _darkCardColor = Color(0xFF1C1C1E);
  static const Color _darkDividerColor = Color(0xFF3A3A3C);

  // 扣分项标记点颜色
  static const Color _visionColor = Color(0xFF4A148C); // 深紫色
  static const Color _neckColor = Color(0xFFE65100); // 深橙色
  static const Color _waistColor = Color(0xFF1B5E20); // 深绿色

  late AnimationController _controller;
  late Animation<double> _curvedAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _optionScaleAnimation;
  late Animation<double> _optionOpacityAnimation;
  late Animation<double> _chartOpacityAnimation; // 折线图透明度动画

  // 目标位置参数
  late Rect _targetRect;
  static const double _targetHorizontalMargin = 24.0;
  static const double _targetHeight = 300.0; // 放大后的高度（含padding），增加 25%
  static const double _optionWidth = 160.0; // 选项框宽度

  // 健康数据管理
  final HealthService _healthService = HealthService();
  late DayHealthData _todayData;
  late List<FlSpot> _currentDataPoints;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _currentDataPoints = List.from(widget.dataPoints);

    // 初始化数据
    _initData();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 350), // 打开动画时长
      reverseDuration: const Duration(milliseconds: 250), // 关闭动画更短
      vsync: this,
    );

    // 主动画曲线
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // 模糊动画
    _blurAnimation = Tween<double>(begin: 0, end: 10).animate(_curvedAnimation);

    // 选项框缩放动画（延迟开始）
    _optionScaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      reverseCurve: const Interval(0.3, 1.0, curve: Curves.easeInCubic),
    );

    // 选项框透明度动画 - 关闭时快速变透明
    _optionOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic), // 打开时：延迟显示
        reverseCurve: const Interval(0.6, 1.0, curve: Curves.easeIn), // 关闭时：在 1.0->0.6 区间内变透明（即动画前40%完成）
      ),
    );

    // 折线图透明度动画 - 关闭时逐渐变透明，回到原位时透明度为0
    _chartOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut), // 打开时：快速变为不透明
        reverseCurve: const Interval(0.0, 1.0, curve: Curves.easeIn), // 关闭时：全程逐渐变透明
      ),
    );

    // 启动展开动画
    _controller.forward();
  }

  /// 初始化数据（HealthService 已由 Bootstrap 初始化完成，直接读取）
  void _initData() {
    if (mounted) {
      setState(() {
        _todayData = _healthService.getDataForDate(DateTime.now());
        _isLoading = false;
        
        // 调试日志：显示今日数据状态
        debugPrint('📋 [Init] Today data: baseScore=${_todayData.baseScore}, '
            'vision=${_todayData.visionDeduction}, '
            'neck=${_todayData.neckDeduction}, '
            'waist=${_todayData.waistDeduction}');
        
        // 如果今日已有扣分记录，更新图表显示
        if (_todayData.baseScore != null || 
            _todayData.visionDeduction > 0 || 
            _todayData.neckDeduction > 0 || 
            _todayData.waistDeduction > 0) {
          _updateChartData();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateTargetRect();
  }

  void _calculateTargetRect() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // 目标位置：水平居中，垂直位于屏幕上方 1/4 处
    final targetWidth = screenWidth - _targetHorizontalMargin * 2;
    final targetTop = screenHeight * 0.15;

    _targetRect = Rect.fromLTWH(
      _targetHorizontalMargin,
      targetTop,
      targetWidth,
      _targetHeight,
    );
  }

  /// 关闭弹出层（执行收起动画）
  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  /// 显示基准分数输入对话框
  Future<void> _showBaseScoreDialog() async {
    if (_isLoading) return;
    
    // 获取当前显示的基准分数（可能是继承的昨天最终分数）
    final effectiveBase = _todayData.baseScore ?? _healthService.getYesterdayFinalScore();
    final TextEditingController textController = TextEditingController(
      text: effectiveBase?.toString() ?? '',
    );

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkCardColor,
        title: const Text(
          '请输入今日基准分数',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _RangeTextInputFormatter(0, 100),
          ],
          style: const TextStyle(color: Colors.white, fontSize: 24),
          decoration: InputDecoration(
            hintText: '0-100',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.pinkAccent),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(textController.text);
              if (value != null && value >= 0 && value <= 100) {
                Navigator.pop(context, value);
              }
            },
            child: const Text(
              '确定',
              style: TextStyle(color: Colors.pinkAccent),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _todayData = _todayData.copyWith(baseScore: result);
        _healthService.saveDataForDate(_todayData);
        _updateChartData();
      });
    }
  }

  /// 检查按钮是否可点击
  bool _canClickButton(String type) {
    if (_isLoading) return false;
    return _healthService.canClickButton(type, _todayData);
  }

  /// 处理扣分项点击（视力/颈/腰）
  void _handleDeduction(String type) {
    if (_isLoading) return;
    
    // 检查是否已点击过（每日限制一次）
    if (!_canClickButton(type)) {
      debugPrint('⚠️ [Deduction] Button "$type" already clicked today');
      return;
    }

    // 获取有效的基准分数（自动继承昨天的最终分数）
    int? effectiveBase = _todayData.baseScore ?? _healthService.getYesterdayFinalScore();
    
    // 如果没有任何可用的基准分数，默认使用100作为起始分
    effectiveBase ??= 100;

    // 如果今天没有设置基准分数，自动使用继承的基准分数
    if (_todayData.baseScore == null) {
      _todayData = _todayData.copyWith(baseScore: effectiveBase);
      debugPrint('📝 [Deduction] Auto-set baseScore to $effectiveBase');
    }

    final now = DateTime.now();
    setState(() {
      const int deduction = 5;
      debugPrint('🔴 [Deduction] type: $type, deduction: $deduction');
      switch (type) {
        case 'vision':
          _todayData = _todayData.copyWith(
            visionDeduction: _todayData.visionDeduction + deduction,
            visionClickTime: now,
          );
          break;
        case 'neck':
          _todayData = _todayData.copyWith(
            neckDeduction: _todayData.neckDeduction + deduction,
            neckClickTime: now,
          );
          break;
        case 'waist':
          _todayData = _todayData.copyWith(
            waistDeduction: _todayData.waistDeduction + deduction,
            waistClickTime: now,
          );
          break;
      }
      _healthService.saveDataForDate(_todayData);
      _updateChartData();
    });
  }

  /// 更新折线图数据（将今日数据更新到最后一个点）
  void _updateChartData() {
    if (_isLoading) return;
    
    // 获取有效的最终分数（优先使用昨天的最终分数）
    final effectiveBase = _todayData.baseScore ?? _healthService.getYesterdayFinalScore() ?? 100;
    if (_currentDataPoints.isNotEmpty) {
      final totalDeduction = _todayData.visionDeduction + 
          _todayData.neckDeduction + 
          _todayData.waistDeduction;
      final finalScore = (effectiveBase - totalDeduction).clamp(0, 100);
      
      // 调试日志
      debugPrint('📊 [ChartUpdate] baseScore: $effectiveBase, totalDeduction: $totalDeduction, finalScore: $finalScore');
      
      // 更新最后一个数据点为今日最终分数
      final lastIndex = _currentDataPoints.length - 1;
      _currentDataPoints[lastIndex] = FlSpot(
        _currentDataPoints[lastIndex].x,
        finalScore.toDouble(),
      );
      widget.onDataChanged?.call(_currentDataPoints);
    }
  }

  /// 构建扣分项标记点数据
  List<LineChartBarData> _buildDeductionMarkers() {
    final List<LineChartBarData> markers = [];
    if (_isLoading || _currentDataPoints.isEmpty) {
      return markers;
    }

    // 获取有效的基准分数（优先使用昨天的最终分数，默认100）
    final effectiveBase = _todayData.baseScore ?? _healthService.getYesterdayFinalScore() ?? 100;

    final todayX = _currentDataPoints.last.x;
    final baseY = effectiveBase.toDouble();

    // 视力标记点
    if (_todayData.visionDeduction > 0) {
      final visionY = (baseY - _todayData.visionDeduction).clamp(0.0, 100.0);
      markers.add(_createMarkerLine(todayX, visionY, _visionColor));
    }

    // 颈部标记点
    if (_todayData.neckDeduction > 0) {
      final neckY = (baseY - _todayData.visionDeduction - _todayData.neckDeduction)
          .clamp(0.0, 100.0);
      markers.add(_createMarkerLine(todayX, neckY, _neckColor));
    }

    // 腰部标记点
    if (_todayData.waistDeduction > 0) {
      final waistY = (baseY -
              _todayData.visionDeduction -
              _todayData.neckDeduction -
              _todayData.waistDeduction)
          .clamp(0.0, 100.0);
      markers.add(_createMarkerLine(todayX, waistY, _waistColor));
    }

    return markers;
  }

  /// 创建单个标记点的线条数据
  LineChartBarData _createMarkerLine(double x, double y, Color color) {
    return LineChartBarData(
      spots: [FlSpot(x, y)],
      isCurved: false,
      color: Colors.transparent,
      barWidth: 0,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 6,
            color: color,
            strokeWidth: 2,
            strokeColor: color.withValues(alpha: 0.5),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // 计算当前插值的位置和大小
          final currentRect = Rect.lerp(
            widget.sourceRect,
            _targetRect,
            _curvedAnimation.value,
          )!;

          // 计算选项框位置（折线图卡片下方，左对齐）
          final optionTop = currentRect.bottom + 16;
          final optionLeft = currentRect.left;

          return Stack(
            children: [
              // 背景模糊层（带原位置"洞"）
              _buildBlurredBackground(currentRect),

              // 折线图卡片（带透明度动画）
              Positioned(
                left: currentRect.left,
                top: currentRect.top,
                width: currentRect.width,
                height: currentRect.height,
                child: Opacity(
                  opacity: _chartOpacityAnimation.value,
                  child: _buildChartCard(),
                ),
              ),

              // 选项菜单卡片
              Positioned(
                left: optionLeft,
                top: optionTop,
                width: _optionWidth,
                child: Transform.scale(
                  scale: _optionScaleAnimation.value,
                  alignment: Alignment.topLeft,
                  child: Opacity(
                    opacity: _optionOpacityAnimation.value,
                    child: _buildOptionsCard(context),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建模糊背景（原位置保持清晰）
  Widget _buildBlurredBackground(Rect currentRect) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _dismiss,
        child: Stack(
          children: [
            // 模糊层（排除原始图表区域）
            ClipPath(
              clipper: _InvertedRectClipper(
                excludeRect: widget.sourceRect,
                animationValue: _curvedAnimation.value,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurAnimation.value,
                  sigmaY: _blurAnimation.value,
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.3 * _curvedAnimation.value),
                ),
              ),
            ),
            // 原始位置的遮罩（动画过程中逐渐显示模糊）
            Positioned.fill(
              child: Opacity(
                opacity: _curvedAnimation.value,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value,
                    sigmaY: _blurAnimation.value,
                  ),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建折线图卡片
  Widget _buildChartCard() {
    // 获取扣分标记点
    final deductionMarkers = _isLoading ? <LineChartBarData>[] : _buildDeductionMarkers();

    return GestureDetector(
      onTap: () {}, // 阻止点击穿透
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _darkCardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3 * _curvedAnimation.value),
              blurRadius: 20 * _curvedAnimation.value,
              offset: Offset(0, 10 * _curvedAnimation.value),
            ),
          ],
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: _currentDataPoints.isNotEmpty ? _currentDataPoints.last.x : 9,
            minY: 0,   // 修改为 0
            maxY: 100, // 固定为 100
            lineBarsData: [
              // 主折线
              LineChartBarData(
                spots: _currentDataPoints,
                isCurved: true,
                color: Colors.pinkAccent,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: _darkCardColor,
                      strokeWidth: 2,
                      strokeColor: Colors.pinkAccent,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  // 设置填充的截止位置（阈值）
                  cutOffY: 0.0,
                  applyCutOffY: true,
                  // 三段式渐变填充
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
              // 扣分项标记点
              ...deductionMarkers,
            ],
            lineTouchData: LineTouchData(enabled: false),
          ),
        ),
      ),
    );
  }

  /// 构建选项菜单卡片
  Widget _buildOptionsCard(BuildContext context) {
    // 检查各按钮是否可点击
    final canClickVision = _canClickButton('vision');
    final canClickNeck = _canClickButton('neck');
    final canClickWaist = _canClickButton('waist');
    
    // 获取有效的基准分数（显示用）
    final effectiveBase = _isLoading ? null : (_todayData.baseScore ?? _healthService.getYesterdayFinalScore());

    return GestureDetector(
      onTap: () {}, // 阻止点击穿透
      child: Container(
        decoration: BoxDecoration(
          color: _darkCardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OptionItem(
              icon: Icons.grade,
              label: '基准',
              subtitle: _isLoading 
                  ? '...'
                  : (_todayData.baseScore != null 
                      ? '${_todayData.baseScore}' 
                      : (effectiveBase != null ? '继承 $effectiveBase' : '未设置')),
              onTap: _showBaseScoreDialog,
            ),
            _buildDivider(),
            _OptionItem(
              icon: Icons.visibility,
              label: '视力',
              subtitle: _isLoading 
                  ? null 
                  : (_todayData.visionDeduction > 0 ? '-${_todayData.visionDeduction}' : null),
              iconColor: _visionColor,
              enabled: canClickVision,
              onTap: () => _handleDeduction('vision'),
            ),
            _buildDivider(),
            _OptionItem(
              icon: Icons.accessibility_new,
              label: '颈',
              subtitle: _isLoading 
                  ? null 
                  : (_todayData.neckDeduction > 0 ? '-${_todayData.neckDeduction}' : null),
              iconColor: _neckColor,
              enabled: canClickNeck,
              onTap: () => _handleDeduction('neck'),
            ),
            _buildDivider(),
            _OptionItem(
              icon: Icons.fitness_center,
              label: '腰',
              subtitle: _isLoading 
                  ? null 
                  : (_todayData.waistDeduction > 0 ? '-${_todayData.waistDeduction}' : null),
              iconColor: _waistColor,
              enabled: canClickWaist,
              onTap: () => _handleDeduction('waist'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: _darkDividerColor,
      indent: 16,
      endIndent: 16,
    );
  }
}

/// 选项按钮组件 - 带独立按压状态管理和禁用状态支持
class _OptionItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? subtitle; // 副标题（显示当前值）
  final Color? textColor;
  final Color? iconColor; // 图标颜色
  final bool isDestructive;
  final bool enabled; // 是否启用
  final VoidCallback onTap;

  const _OptionItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.textColor,
    this.iconColor,
    this.isDestructive = false,
    this.enabled = true,
    required this.onTap,
  });

  @override
  State<_OptionItem> createState() => _OptionItemState();
}

class _OptionItemState extends State<_OptionItem> {
  bool _isPressed = false;

  // 按压时的背景色
  static const Color _pressedBgColor = Color(0xFF2C2C2E);
  // 普通文字颜色
  static const Color _normalTextColor = Colors.white70;
  // 按压时文字颜色变亮
  static const Color _pressedTextColor = Colors.white;
  // 禁用状态颜色
  static final Color _disabledColor = Colors.grey[600]!;

  @override
  Widget build(BuildContext context) {
    // 禁用状态
    if (!widget.enabled) {
      return Opacity(
        opacity: 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(widget.icon, color: _disabledColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 15,
                      color: _disabledColor,
                    ),
                  ),
                ),
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: _disabledColor.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // 启用状态 - 带按压效果
    final Color baseColor = widget.textColor ?? _normalTextColor;
    final Color currentColor = _isPressed
        ? (widget.isDestructive ? Colors.red.shade300 : _pressedTextColor)
        : baseColor;
    final Color iconColor = widget.iconColor ?? currentColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) async {
        // 保持按压状态一小段时间，让用户看到按压效果
        await Future.delayed(const Duration(milliseconds: 80));
        if (mounted) {
          setState(() => _isPressed = false);
          widget.onTap();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _isPressed ? 0.97 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _isPressed ? _pressedBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(widget.icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 15,
                      color: currentColor,
                    ),
                  ),
                ),
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: currentColor.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 输入范围限制器
class _RangeTextInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _RangeTextInputFormatter(this.min, this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final value = int.tryParse(newValue.text);
    if (value == null) return oldValue;

    if (value < min || value > max) {
      return oldValue;
    }

    return newValue;
  }
}

/// 自定义裁剪器：排除指定矩形区域的反向裁剪
class _InvertedRectClipper extends CustomClipper<Path> {
  final Rect excludeRect;
  final double animationValue;

  _InvertedRectClipper({
    required this.excludeRect,
    required this.animationValue,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    // 添加整个屏幕区域
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 计算需要排除的区域（随动画逐渐缩小到无）
    if (animationValue < 1.0) {
      final shrinkFactor = 1.0 - animationValue;
      final excludeWidth = excludeRect.width * shrinkFactor;
      final excludeHeight = excludeRect.height * shrinkFactor;
      final excludeLeft =
          excludeRect.left + (excludeRect.width - excludeWidth) / 2;
      final excludeTop =
          excludeRect.top + (excludeRect.height - excludeHeight) / 2;

      final animatedExcludeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(excludeLeft, excludeTop, excludeWidth, excludeHeight),
        const Radius.circular(16),
      );

      path.addRRect(animatedExcludeRect);
    }

    // 使用 evenOdd 填充规则实现反向裁剪
    path.fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  bool shouldReclip(_InvertedRectClipper oldClipper) {
    return oldClipper.excludeRect != excludeRect ||
        oldClipper.animationValue != animationValue;
  }
}

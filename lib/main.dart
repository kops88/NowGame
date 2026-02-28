import 'package:flutter/material.dart';
import 'package:nowgame/Bootstrap.dart';
import 'package:nowgame/MainWidget/HealthWidget.dart';
import 'package:nowgame/MainWidget/MoneyAndInfluence.dart';
import 'package:nowgame/MainWidget/TimeRingWidget.dart';
import 'package:nowgame/MainWidget/WisdomWidget.dart';
import 'package:nowgame/MainWidget/TaskCard.dart';
import 'package:nowgame/Service/TaskService.dart';
import 'package:nowgame/ShopWidget/ShopPage.dart';
import 'package:nowgame/Util/DebugWidget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 应用启动前完成所有初始化：存储驱动、数据迁移、Service 注入
  final bootstrap = AppBootstrap();
  await bootstrap.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'xxxx',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),
      home: const AppShell(),
    );
  }
}

/// 应用外壳（底部导航栏 + 页面切换）
///
/// 定位：应用的顶层导航容器，管理 Tab 切换和生命周期监听。
/// 职责：
///   - 包含 BottomNavigationBar，管理 tab 索引
///   - Tab 0 = 主页（DashboardContent），Tab 1 = 商店（ShopPage）
///   - 切换 Tab 时触发 TaskService.commitProgress()（离开主页时保存任务进度）
///   - 监听应用生命周期（WidgetsBindingObserver），后台/退出时自动 commit
/// 不负责：具体页面内容（委托给各子页面）。
class AppShell extends StatefulWidget {
  const AppShell({Key? key}) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 退出时提交任务进度
    TaskService().commitProgress();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 应用生命周期变化回调
  ///
  /// 当应用进入后台（inactive/paused/hidden）或被销毁（detached）时，
  /// 自动提交任务进度到存储。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      TaskService().commitProgress();
    }
  }

  /// Tab 切换回调
  ///
  /// 伪代码思路：
  ///   如果从主页切走（_currentIndex == 0 且 newIndex != 0）-> commit 任务进度
  ///   -> 更新 _currentIndex -> setState 刷新 UI
  void _onTabChanged(int newIndex) {
    if (_currentIndex == 0 && newIndex != 0) {
      // 离开主页时提交任务进度
      TaskService().commitProgress();
    }
    setState(() => _currentIndex = newIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardContent(),
          ShopPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '主页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: '商店',
          ),
        ],
      ),
    );
  }
}

/// 主页内容（原 DashboardScreen 的 body 部分）
///
/// 定位：主页 Tab 的内容区域，包含时间环、金钱/影响力、主线任务、健康、任务卡片。
/// 职责：纯粹的内容展示容器，不再处理生命周期（移交给 AppShell）。
/// 不负责：导航管理、生命周期监听。
class DashboardContent extends StatelessWidget {
  const DashboardContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MText('主页', style: TextStyle(color: Colors.white)),
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
            // 3. 成长系统：主线任务（技能列表）
            MainQuestSkillsWidget(),
            SizedBox(height: 16),
            // 4
            HealthCardWidget(),
            SizedBox(height: 16),
            // 5. 任务卡片区域
            TaskCardList(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

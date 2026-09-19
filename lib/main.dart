import 'package:flutter/material.dart';

import 'repository.dart';
import 'screens/explore_screen.dart';
import 'screens/home_screen.dart';
import 'screens/info_screen.dart';
import 'screens/map_screen.dart';
import 'screens/timetable_screen.dart';
import 'widgets.dart';

void main() {
  runApp(const FestivalApp());
}

// テーマ字「月」にちなんだ夜空の紺と月の黄色
const _night = Color(0xFF1E2157);
const _moon = Color(0xFFF2C94C);

/// データを読み込み、MaterialApp 全体（詳細画面などの push 先も含む）に渡す。
class FestivalApp extends StatefulWidget {
  const FestivalApp({super.key});

  @override
  State<FestivalApp> createState() => _FestivalAppState();
}

class _FestivalAppState extends State<FestivalApp> {
  final _repo = FestivalRepository();
  LoadedFestival? _data;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repo.load();
      if (mounted) {
        setState(() {
          _data = data;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _retry() {
    setState(() => _error = null);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    ThemeData theme(Brightness b) {
      final scheme = ColorScheme.fromSeed(seedColor: _night, brightness: b).copyWith(
        primary: b == Brightness.light ? _night : const Color(0xFFBFC3FF),
        secondary: _moon,
        onSecondary: _night,
      );
      return ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: b == Brightness.light ? _night : null,
          foregroundColor: b == Brightness.light ? Colors.white : null,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 10.5)),
        ),
        tabBarTheme: b == Brightness.light
            ? const TabBarThemeData(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: _moon,
              )
            : null,
      );
    }

    return MaterialApp(
      title: '中京大学祭',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      // Navigator より上に置くことで、push した画面からもデータを参照できる
      builder: (context, child) => data == null
          ? child!
          : FestivalScope(data: data, reload: _load, child: child!),
      home: data != null ? const _Shell() : _LoadingView(failed: _error != null, onRetry: _retry),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final bool failed;
  final VoidCallback onRetry;

  const _LoadingView({required this.failed, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: !failed
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('データを読み込めませんでした'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: onRetry, child: const Text('再読み込み')),
                ],
              ),
      ),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onSelectTab: (i) => setState(() => _tab = i)),
      const TimetableScreen(),
      const ExploreScreen(),
      const MapScreen(),
      const InfoScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'ホーム'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: 'タイムテーブル'),
          NavigationDestination(icon: Icon(Icons.celebration_outlined), selectedIcon: Icon(Icons.celebration), label: '企画・ブース'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'マップ'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'その他'),
        ],
      ),
    );
  }
}

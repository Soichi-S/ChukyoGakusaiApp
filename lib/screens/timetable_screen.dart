import 'package:flutter/material.dart';

import '../models.dart';
import '../schedule_chart.dart';
import '../time_utils.dart';
import '../widgets.dart';
import 'project_detail_screen.dart';

/// 日付タブ × 「ステージ・イベント / 企画の営業時間」の切り替え。
/// パンフレットの「全体タイムテーブル」「ステージ企画タイムテーブル」をまとめたもの。
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  bool _showProjects = false;

  @override
  Widget build(BuildContext context) {
    final festival = FestivalScope.festivalOf(context);
    final days = festival.edition.days;
    final todayIndex = days.indexWhere((d) => d.date == jstDateString(jstNow()));

    return DefaultTabController(
      length: days.length,
      initialIndex: todayIndex < 0 ? 0 : todayIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('タイムテーブル'),
          bottom: TabBar(tabs: [for (final d in days) Tab(text: d.shortLabel)]),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('ステージ・大会')),
                  ButtonSegment(value: true, label: Text('企画の時間')),
                ],
                showSelectedIcon: false,
                selected: {_showProjects},
                  onSelectionChanged: (s) => setState(() => _showProjects = s.first),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final d in days)
                    _showProjects ? _ProjectHours(day: d) : _EventList(day: d),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  final FestivalDay day;

  const _EventList({required this.day});

  @override
  Widget build(BuildContext context) {
    final festival = FestivalScope.festivalOf(context);
    final events = festival.eventsOn(day.date);
    // 会場ごとにまとめる（ガレリアステージ・清明ホール・体育館…）
    final venueIds = <String>{for (final e in events) e.venueId};

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final id in venueIds) ...[
          SectionTitle(festival.venue(id)?.fullName ?? id),
          for (final e in events.where((e) => e.venueId == id)) EventTile(e),
        ],
      ],
    );
  }
}

class _ProjectHours extends StatelessWidget {
  final FestivalDay day;

  const _ProjectHours({required this.day});

  @override
  Widget build(BuildContext context) {
    final festival = FestivalScope.festivalOf(context);
    final open = festival.projects.where((p) => p.sessionOn(day.date) != null).toList()
      ..sort((a, b) => a.sessionOn(day.date)!.start.compareTo(b.sessionOn(day.date)!.start));
    void showDetail(Project p) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: p)),
        );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text('${day.label}　開場 ${day.open}〜${day.close}',
              style: Theme.of(context).textTheme.bodySmall),
        ),
        const SectionTitle('タイムテーブル図'),
        ScheduleChart(date: day.date, projects: open, onTap: showDetail),
        const SectionTitle('一覧'),
        for (final p in open)
          ListTile(
            title: Text(p.title),
            subtitle: Text('${p.sessionOn(day.date)!.label}\n${p.locationLabel}'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDetail(p),
          ),
      ],
    );
  }
}

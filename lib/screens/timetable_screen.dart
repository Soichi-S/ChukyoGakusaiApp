import 'package:flutter/material.dart';

import '../models.dart';
import '../schedule_chart.dart';
import '../time_utils.dart';
import '../widgets.dart';
import 'event_detail_screen.dart';
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
    final todayIndex = days.indexWhere(
      (d) => d.date == jstDateString(jstNow()),
    );

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
                  onSelectionChanged: (s) =>
                      setState(() => _showProjects = s.first),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final d in days)
                    _showProjects
                        ? _ProjectHours(
                            day: d,
                            onShowStage: () =>
                                setState(() => _showProjects = false),
                          )
                        : _EventList(day: d),
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
    // 会場ごとにまとめる。並び順は festival.json の venues の順（先頭がガレリアステージ）。
    // venues にない会場は最後にまわす。
    final order = [for (final v in festival.venues) v.id];
    int rank(String id) =>
        order.contains(id) ? order.indexOf(id) : order.length;
    final venueIds = <String>{for (final e in events) e.venueId}.toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final id in venueIds) ...[
          SectionTitle(festival.venue(id)?.fullName ?? id),
          ..._venueSection(
            context,
            day,
            events.where((e) => e.venueId == id).toList(),
          ),
        ],
      ],
    );
  }

  /// 会場ごとの「タイムテーブル図 → 各詳細」。
  /// その日その会場での開催が1件だけなら、図は出さない（ガレリアステージ以外はたいてい1件）。
  List<Widget> _venueSection(
    BuildContext context,
    FestivalDay day,
    List<FestivalEvent> events,
  ) {
    final shown = events.where((e) => !e.isCancelled).toList();
    return [
      if (shown.length > 1)
        ScheduleChart(
          date: day.date,
          items: [
            for (final e in shown)
              ChartItem.fromEvent(
                e,
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EventDetailScreen(event: e),
                  ),
                ),
              ),
          ],
        ),
      for (final e in events) EventTile(e),
    ];
  }
}

class _ProjectHours extends StatelessWidget {
  final FestivalDay day;
  final VoidCallback onShowStage;

  const _ProjectHours({required this.day, required this.onShowStage});

  @override
  Widget build(BuildContext context) {
    final festival = FestivalScope.festivalOf(context);
    final open =
        festival.projects.where((p) => p.sessionOn(day.date) != null).toList()
          ..sort(
            (a, b) => a
                .sessionOn(day.date)!
                .start
                .compareTo(b.sessionOn(day.date)!.start),
          );
    void showDetail(Project p) => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: p)));

    // パンフレットの「全体タイムテーブル」と同じ構成にする。
    // 中京フェスのような連続したステージ企画は、1件ずつではなくまとめて1行にする
    // （1件ずつの図は「ステージ・大会」側にある）。中止のイベントは描かない。
    final events = festival
        .eventsOn(day.date)
        .where((e) => !e.isCancelled)
        .toList();
    final items = <ChartItem>[
      for (final p in open)
        ChartItem.fromProject(p, p.sessionOn(day.date)!, () => showDetail(p)),
      for (final MapEntry(key: series, value: group) in _groupBySeries(
        events,
      ).entries)
        if (series == null)
          for (final e in group)
            ChartItem.fromEvent(
              e,
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EventDetailScreen(event: e)),
              ),
            )
        else
          ChartItem(
            title: series,
            start: group.first.start,
            end: group
                .map((e) => e.end ?? e.start)
                .reduce((a, b) => a.compareTo(b) >= 0 ? a : b),
            kind: 'event',
            onTap: onShowStage,
          ),
    ]..sort((a, b) => a.start.compareTo(b.start));

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            '${day.label}　開場 ${day.open}〜${day.close}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SectionTitle('タイムテーブル図'),
        ScheduleChart(date: day.date, items: items),
        const SectionTitle('企画の一覧'),
        for (final p in open)
          ListTile(
            title: Text(p.title),
            subtitle: Text(
              '${p.sessionOn(day.date)!.label}\n${p.locationLabel}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDetail(p),
          ),
      ],
    );
  }

  /// series（中京フェスなど）ごとにまとめる。series がないイベントは null のグループに入れ、
  /// 1件ずつ描く。並び順は開始時刻順を保つ。
  Map<String?, List<FestivalEvent>> _groupBySeries(List<FestivalEvent> events) {
    final grouped = <String?, List<FestivalEvent>>{};
    for (final e in events) {
      grouped.putIfAbsent(e.series, () => []).add(e);
    }
    return grouped;
  }
}

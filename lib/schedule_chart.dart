import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';
import 'time_utils.dart';

/// タイムテーブル図の1行。企画（終日）とイベント（時刻指定）の両方を表す。
class ChartItem {
  final String title;
  final String start;

  /// 終了時刻。未定（「16:00〜」など）の場合は null
  final String? end;

  /// 最終受付・ラストオーダー。以降は薄い色で描く
  final String? cutoff;

  /// 色分けの種類（projects の category、または 'event'）
  final String kind;
  final VoidCallback onTap;

  const ChartItem({
    required this.title,
    required this.start,
    required this.end,
    this.cutoff,
    required this.kind,
    required this.onTap,
  });

  ChartItem.fromProject(Project p, ProjectSession s, this.onTap)
    : title = p.title,
      start = s.start,
      end = s.end,
      cutoff = s.lastEntry ?? s.lastOrder,
      kind = p.category;

  ChartItem.fromEvent(FestivalEvent e, this.onTap)
    : title = e.title,
      start = e.start,
      end = e.end,
      cutoff = null,
      kind = 'event';
}

/// 1日分の開催時間を、横棒のタイムテーブル図で描く。
/// パンフレットの「全体タイムテーブル」に相当。
class ScheduleChart extends StatelessWidget {
  final String date;
  final List<ChartItem> items;

  const ScheduleChart({super.key, required this.date, required this.items});

  static const _labelWidth = 104.0;
  static const _rowHeight = 36.0;
  static const _minHourWidth = 30.0;

  static int _minutes(String hm) {
    final [h, m] = hm.split(':').map(int.parse).toList();
    return h * 60 + m;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();
    // 終了時刻が未定の行は 1 時間の長さとして描く
    int endOf(ChartItem i) =>
        i.end == null ? _minutes(i.start) + 60 : _minutes(i.end!);
    final firstHour =
        items.map((i) => _minutes(i.start)).reduce(math.min) ~/ 60;
    final lastHour = (items.map(endOf).reduce(math.max) + 59) ~/ 60;
    final hours = lastHour - firstHour;

    final now = jstNow();
    final nowMinutes = jstDateString(now) == date
        ? now.hour * 60 + now.minute
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final timelineWidth = math.max(
          constraints.maxWidth - _labelWidth - 16,
          hours * _minHourWidth,
        );
        final perMinute = timelineWidth / (hours * 60);
        double x(int minutes) => (minutes - firstHour * 60) * perMinute;

        Widget gridAndNow(double height) => Stack(
          children: [
            for (var h = 0; h <= hours; h++)
              Positioned(
                left: h * 60 * perMinute,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                ),
              ),
            if (nowMinutes != null &&
                nowMinutes >= firstHour * 60 &&
                nowMinutes <= lastHour * 60)
              Positioned(
                left: x(nowMinutes),
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: Colors.redAccent),
              ),
          ],
        );

        final header = Row(
          children: [
            const SizedBox(width: _labelWidth),
            SizedBox(
              width: timelineWidth,
              height: 20,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var h = 0; h <= hours; h++)
                    Positioned(
                      left: h * 60 * perMinute - 8,
                      child: Text(
                        '${firstHour + h}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );

        final rows = [
          for (final item in items)
            _row(context, item, endOf(item), timelineWidth, x, gridAndNow),
        ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              ...rows,
              const SizedBox(height: 8),
              _legend(context),
            ],
          ),
        );
      },
    );
  }

  Widget _row(
    BuildContext context,
    ChartItem item,
    int endMinutes,
    double timelineWidth,
    double Function(int) x,
    Widget Function(double) gridAndNow,
  ) {
    final color = _colorFor(context, item.kind);
    final start = _minutes(item.start);
    final end = endMinutes;
    final open = item.cutoff == null ? end : _minutes(item.cutoff!);
    final barWidth = x(end) - x(start);
    final timeLabel = item.end == null
        ? '${item.start}〜'
        : '${item.start}〜${item.end}';

    return InkWell(
      onTap: item.onTap,
      child: SizedBox(
        height: _rowHeight,
        child: Row(
          children: [
            SizedBox(
              width: _labelWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, height: 1.2),
                ),
              ),
            ),
            SizedBox(
              width: timelineWidth,
              child: Stack(
                children: [
                  Positioned.fill(child: gridAndNow(_rowHeight)),
                  // 受付中
                  Positioned(
                    left: x(start),
                    width: x(open) - x(start),
                    top: 6,
                    bottom: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.horizontal(
                          left: const Radius.circular(6),
                          right: Radius.circular(open == end ? 6 : 0),
                        ),
                      ),
                    ),
                  ),
                  // 最終受付・ラストオーダー後
                  if (open < end)
                    Positioned(
                      left: x(open),
                      width: x(end) - x(open),
                      top: 6,
                      bottom: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.35),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  if (barWidth > 84)
                    Positioned(
                      left: x(start) + 6,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color:
                                ThemeData.estimateBrightnessForColor(color) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(BuildContext context) {
    final color = _colorFor(context, 'classroom');
    // 図に出ている種類の凡例だけを表示する
    final hasProject = items.any((i) => i.kind != 'event');
    final hasEvent = items.any((i) => i.kind == 'event');
    final hasCutoff = items.any((i) => i.cutoff != null);
    Widget swatch(Color c) => Container(
      width: 16,
      height: 10,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(3),
      ),
    );
    const style = TextStyle(fontSize: 11);
    return Padding(
      padding: const EdgeInsets.only(left: _labelWidth),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (hasProject)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                swatch(color),
                const SizedBox(width: 4),
                Text(hasEvent ? '企画（受付中）' : '受付中', style: style),
              ],
            ),
          if (hasEvent && hasProject)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                swatch(_colorFor(context, 'event')),
                const SizedBox(width: 4),
                const Text('ステージ・大会', style: style),
              ],
            ),
          if (hasCutoff)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                swatch(color.withValues(alpha: 0.35)),
                const SizedBox(width: 4),
                const Text('最終受付・L.O.後', style: style),
              ],
            ),
          if (jstDateString(jstNow()) == date)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 2, height: 12, color: Colors.redAccent),
                const SizedBox(width: 4),
                const Text('現在時刻', style: style),
              ],
            ),
        ],
      ),
    );
  }

  static Color _colorFor(BuildContext context, String kind) => switch (kind) {
    'event' => Colors.deepOrange.shade400,
    'campus' => Colors.teal.shade600,
    'service' => Colors.blueGrey.shade500,
    _ => Theme.of(context).colorScheme.primary,
  };
}

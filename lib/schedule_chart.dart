import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';
import 'time_utils.dart';

/// 1日分の企画の開催時間を、横棒のタイムテーブル図で描く。
/// パンフレットの「全体タイムテーブル」に相当。
class ScheduleChart extends StatelessWidget {
  final String date;
  final List<Project> projects;
  final void Function(Project) onTap;

  const ScheduleChart({
    super.key,
    required this.date,
    required this.projects,
    required this.onTap,
  });

  static const _labelWidth = 104.0;
  static const _rowHeight = 36.0;
  static const _minHourWidth = 30.0;

  static int _minutes(String hm) {
    final [h, m] = hm.split(':').map(int.parse).toList();
    return h * 60 + m;
  }

  @override
  Widget build(BuildContext context) {
    final sessions = [for (final p in projects) p.sessionOn(date)!];
    if (sessions.isEmpty) return const SizedBox();
    final firstHour =
        sessions.map((s) => _minutes(s.start)).reduce(math.min) ~/ 60;
    final lastHour =
        (sessions.map((s) => _minutes(s.end)).reduce(math.max) + 59) ~/ 60;
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
          for (final (i, p) in projects.indexed)
            _row(context, p, sessions[i], timelineWidth, x, gridAndNow),
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
    Project p,
    ProjectSession s,
    double timelineWidth,
    double Function(int) x,
    Widget Function(double) gridAndNow,
  ) {
    final color = _colorFor(context, p.category);
    final start = _minutes(s.start);
    final end = _minutes(s.end);
    final cutoff = s.lastEntry ?? s.lastOrder;
    final open = cutoff == null ? end : _minutes(cutoff);
    final barWidth = x(end) - x(start);

    return InkWell(
      onTap: () => onTap(p),
      child: SizedBox(
        height: _rowHeight,
        child: Row(
          children: [
            SizedBox(
              width: _labelWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  p.title,
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
                          '${s.start}〜${s.end}',
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              swatch(color),
              const SizedBox(width: 4),
              const Text('受付中', style: style),
            ],
          ),
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

  static Color _colorFor(BuildContext context, String category) =>
      switch (category) {
        'campus' => Colors.teal.shade600,
        'service' => Colors.blueGrey.shade500,
        _ => Theme.of(context).colorScheme.primary,
      };
}

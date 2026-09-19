import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';
import 'repository.dart';
import 'screens/event_detail_screen.dart';
import 'time_utils.dart';

/// 読み込んだパンフレットデータを画面ツリー全体に渡す。
class FestivalScope extends InheritedWidget {
  final LoadedFestival data;
  final Future<void> Function() reload;

  const FestivalScope({
    super.key,
    required this.data,
    required this.reload,
    required super.child,
  });

  static FestivalScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FestivalScope>()!;

  static Festival festivalOf(BuildContext context) => of(context).data.festival;

  @override
  bool updateShouldNotify(FestivalScope old) => old.data != data;
}

/// data/ 内の画像パスを、取得元（同梱 or ネット）に合わせて表示する。
class FestivalImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? height;

  const FestivalImage(this.path, {super.key, this.fit = BoxFit.contain, this.height});

  @override
  Widget build(BuildContext context) {
    final data = FestivalScope.of(context).data;
    final url = data.imageUrl(path);
    Widget error(_, _, _) => SizedBox(
          height: height ?? 120,
          child: const Center(child: Icon(Icons.image_not_supported_outlined)),
        );
    return data.imagesFromNetwork
        ? Image.network(url, fit: fit, height: height, errorBuilder: error)
        : Image.asset(url, fit: fit, height: height, errorBuilder: error);
  }
}

Future<void> openUrl(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class Tag extends StatelessWidget {
  final String text;
  final Color? color;

  const Tag(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w600)),
    );
  }
}

enum EventTiming { past, live, upcoming }

EventTiming timingOf(FestivalEvent e, DateTime now) {
  final start = jst(e.date, e.start);
  final end = e.end == null ? start.add(const Duration(hours: 1)) : jst(e.date, e.end!);
  if (now.isBefore(start)) return EventTiming.upcoming;
  if (now.isBefore(end)) return EventTiming.live;
  return EventTiming.past;
}

/// タイムテーブル・ホームで使うイベント1行。
class EventTile extends StatelessWidget {
  final FestivalEvent event;
  final bool showDate;

  const EventTile(this.event, {super.key, this.showDate = false});

  @override
  Widget build(BuildContext context) {
    final festival = FestivalScope.festivalOf(context);
    final scheme = Theme.of(context).colorScheme;
    final timing = timingOf(event, jstNow());
    final venue = festival.venue(event.venueId);
    final muted = event.isCancelled || timing == EventTiming.past;
    final day = festival.edition.day(event.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => EventDetailScreen(event: event),
        )),
        child: Opacity(
          opacity: muted ? 0.5 : 1,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  color: timing == EventTiming.live && !event.isCancelled
                      ? scheme.secondary
                      : scheme.primary.withValues(alpha: 0.35),
                ),
                SizedBox(
                  width: 72,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        if (showDate && day != null)
                          Text(day.shortLabel, style: const TextStyle(fontSize: 11)),
                        Text(event.start, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        if (event.end != null)
                          Text('〜${event.end}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(spacing: 6, runSpacing: 4, children: [
                          if (event.isCancelled) Tag('中止', color: scheme.error),
                          if (!event.isCancelled && timing == EventTiming.live)
                            Tag('開催中', color: Colors.orange.shade800),
                          Tag(festival.categoryName(event.category)),
                        ]),
                        const SizedBox(height: 4),
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            decoration: event.isCancelled ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (venue != null)
                          Text(venue.fullName, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                      ],
                    ),
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

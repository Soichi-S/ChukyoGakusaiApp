import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets.dart';
import 'map_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final FestivalEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final festival = FestivalScope.festivalOf(context);
    final scheme = Theme.of(context).colorScheme;
    final venue = festival.venue(event.venueId);
    final day = festival.edition.day(event.date);
    final notice = festival.notice(event.noticeId);

    return Scaffold(
      appBar: AppBar(title: Text(festival.categoryName(event.category))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (notice != null)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notice.title, style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onErrorContainer)),
                    const SizedBox(height: 4),
                    Text(notice.body, style: TextStyle(color: scheme.onErrorContainer)),
                  ],
                ),
              ),
            ),
          if (event.series != null)
            Text(event.series!, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold)),
          Text(
            event.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: event.isCancelled ? TextDecoration.lineThrough : null,
                ),
          ),
          const SizedBox(height: 12),
          InfoRow(Icons.schedule, '${day?.label ?? event.date}　${event.timeLabel}'),
          if (event.doorsOpen != null) InfoRow(Icons.door_front_door_outlined, '開場 ${event.doorsOpen}'),
          if (venue != null) InfoRow(Icons.place_outlined, venue.fullName),
          Align(alignment: Alignment.centerLeft, child: GymDirectionsButton(venueId: event.venueId)),
          if (event.reservation != null) InfoRow(Icons.event_available, event.reservation!),
          if (event.ticketText != null) InfoRow(Icons.confirmation_number_outlined, event.ticketText!),
          if (event.merch != null)
            InfoRow(Icons.shopping_bag_outlined,
                'グッズ販売 ${event.merch!.start}〜${event.merch!.end}${festival.merchPlace == null ? '' : '\n${festival.merchPlace}'}'),
          if (event.image != null) ...[
            const SizedBox(height: 16),
            ClipRRect(borderRadius: BorderRadius.circular(12), child: FestivalImage(event.image!)),
          ],
          if (event.performers.isNotEmpty && event.performers.every((p) => p.comment == null)) ...[
            const SizedBox(height: 12),
            InfoRow(Icons.person_outline, '出演：${event.performers.map((p) => p.name).join('、')}'),
          ],
          if (event.description != null) ...[
            const SizedBox(height: 16),
            Text(event.description!, style: const TextStyle(height: 1.7)),
          ],
          if (event.performers.any((p) => p.comment != null)) ...[
            const SizedBox(height: 16),
            Text('出場者', style: Theme.of(context).textTheme.titleMedium),
            for (final p in event.performers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${p.no ?? ''}')),
                title: Text(p.name),
                subtitle: p.comment == null ? null : Text(p.comment!),
              ),
          ],
          if (event.sns.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final s in event.sns)
                  OutlinedButton.icon(
                    onPressed: () => openUrl(s.url.toString()),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text('${s.label} @${s.handle}'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../widgets.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  static const _icons = {
    'info': Icons.info_outline,
    'entrance': Icons.login,
    'exit': Icons.logout,
    'bicycle': Icons.pedal_bike,
    'smoking': Icons.smoking_rooms,
    'nursing': Icons.child_friendly,
  };

  @override
  Widget build(BuildContext context) {
    final festival = FestivalScope.festivalOf(context);
    final map = festival.campusMap;

    return Scaffold(
      appBar: AppBar(title: const Text('キャンパスマップ')),
      body: map == null
          ? const Center(child: Text('マップ情報がありません'))
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (map.image != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InteractiveViewer(maxScale: 5, child: FestivalImage(map.image!)),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('ピンチ操作で拡大できます', style: TextStyle(fontSize: 12)),
                ),
                if (map.access != null) ...[
                  const SectionTitle('アクセス'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InfoRow(Icons.train_outlined, map.access!),
                  ),
                ],
                const SectionTitle('施設'),
                for (final f in map.facilities)
                  ListTile(
                    leading: Icon(_icons[f.type] ?? Icons.place_outlined),
                    title: Text(f.name),
                    subtitle: Text(f.places.join('、')),
                  ),
                if (map.diningSpaces.isNotEmpty) ...[
                  const SectionTitle('学食スペース'),
                  for (final d in map.diningSpaces)
                    ListTile(
                      leading: const Icon(Icons.restaurant_outlined),
                      title: Text('${d.name}（${d.place}）'),
                      subtitle: Text([
                        for (final h in d.hours)
                          '${festival.edition.day(h.date)?.shortLabel ?? h.date} ${h.start}〜${h.end}',
                        ?d.note,
                      ].join('\n')),
                    ),
                ],
                if (map.gymDirections != null || map.gymDirectionsImage != null) ...[
                  const SectionTitle('体育館への行き方'),
                  if (map.gymDirections != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(map.gymDirections!),
                    ),
                  if (map.gymDirectionsImage != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: FestivalImage(map.gymDirectionsImage!, height: 260),
                    ),
                ],
              ],
            ),
    );
  }
}

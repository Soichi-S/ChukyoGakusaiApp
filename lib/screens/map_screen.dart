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
                  const _GymDirections(),
                ],
              ],
            ),
    );
  }
}

class _GymDirections extends StatelessWidget {
  const _GymDirections();

  @override
  Widget build(BuildContext context) {
    final map = FestivalScope.festivalOf(context).campusMap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (map?.gymDirections != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(map!.gymDirections!, style: const TextStyle(height: 1.6)),
          ),
        if (map?.gymDirectionsImage != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: InteractiveViewer(maxScale: 4, child: FestivalImage(map!.gymDirectionsImage!, height: 320)),
          ),
      ],
    );
  }
}

class GymDirectionsScreen extends StatelessWidget {
  const GymDirectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('体育館への行き方')),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        children: const [_GymDirections()],
      ),
    );
  }
}

/// 会場が体育館・グラウンドの企画の詳細画面に出す「体育館への行き方」ボタン。
/// 会場データの showGymDirections が true の時だけ表示する。
class GymDirectionsButton extends StatelessWidget {
  final String? venueId;

  const GymDirectionsButton({super.key, required this.venueId});

  @override
  Widget build(BuildContext context) {
    final festival = FestivalScope.festivalOf(context);
    final venue = venueId == null ? null : festival.venue(venueId!);
    final map = festival.campusMap;
    if (venue == null || !venue.showGymDirections) return const SizedBox();
    if (map?.gymDirections == null && map?.gymDirectionsImage == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GymDirectionsScreen()),
        ),
        icon: const Icon(Icons.directions_walk),
        label: const Text('体育館への行き方を見る'),
      ),
    );
  }
}

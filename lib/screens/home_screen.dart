import 'package:flutter/material.dart';

import '../models.dart';
import '../repository.dart';
import '../time_utils.dart';
import '../widgets.dart';
import 'info_screen.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int tab) onSelectTab;

  const HomeScreen({super.key, required this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    final scope = FestivalScope.of(context);
    final festival = scope.data.festival;
    final now = jstNow();
    final today = festival.edition.day(jstDateString(now));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: scope.reload,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Hero(edition: festival.edition)),
            if (scope.data.source == DataSource.cache)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: InfoRow(Icons.cloud_off, 'オフラインのため、前回取得した情報を表示しています'),
                ),
              ),
            if (festival.notices.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionTitle('お知らせ')),
              SliverList.list(
                children: [for (final n in festival.notices) _NoticeCard(n)],
              ),
            ],
            ..._stageSection(context, festival, today, now),
            const SliverToBoxAdapter(child: SectionTitle('メニュー')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.count(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _MenuButton(Icons.schedule, 'タイムテーブル', () => onSelectTab(1)),
                  _MenuButton(
                    Icons.celebration_outlined,
                    '企画',
                    () => onSelectTab(2),
                  ),
                  _MenuButton(
                    Icons.storefront_outlined,
                    'ブース',
                    () => onSelectTab(2),
                  ),
                  _MenuButton(Icons.map_outlined, 'マップ', () => onSelectTab(3)),
                  _MenuButton(
                    Icons.shopping_bag_outlined,
                    'グッズ',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GoodsScreen()),
                    ),
                  ),
                  _MenuButton(
                    Icons.rule,
                    'ご来場の注意',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RulesScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  /// 開催日は「開催中・この後のステージ」、それ以外は開催日程を出す。
  List<Widget> _stageSection(
    BuildContext context,
    Festival festival,
    FestivalDay? today,
    DateTime now,
  ) {
    if (today == null) {
      final first = festival.edition.days.first;
      // 日付の差で数える（時刻の端数で1日ずれないように）
      final daysLeft = jst(
        first.date,
        '00:00',
      ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
      final isBefore = now.isBefore(jst(first.date, first.open));
      // 開催前は初日のステージ・イベントを先に見せる（当日は上の分岐で「今日の〜」になる）
      final preview = isBefore
          ? festival
                .eventsOn(first.date)
                .where((e) => !e.isCancelled)
                .take(3)
                .toList()
          : <FestivalEvent>[];
      return [
        const SliverToBoxAdapter(child: SectionTitle('開催日程')),
        SliverList.list(
          children: [
            for (final d in festival.edition.days)
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(d.label),
                trailing: Text('${d.open}〜${d.close}'),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: isBefore
                  ? InfoRow(
                      Icons.hourglass_bottom,
                      daysLeft <= 0 ? '本日開幕です' : '開幕まであと$daysLeft日',
                    )
                  : const InfoRow(
                      Icons.check_circle_outline,
                      '今年の大学祭は終了しました。ご来場ありがとうございました。',
                    ),
            ),
          ],
        ),
        if (preview.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionTitle(
              '${_dateOnly(first.label)}のステージ・イベント',
              trailing: TextButton(
                onPressed: () => onSelectTab(1),
                child: const Text('すべて見る'),
              ),
            ),
          ),
          SliverList.list(children: [for (final e in preview) EventTile(e)]),
        ],
      ];
    }
    final events = festival
        .eventsOn(today.date)
        .where((e) => !e.isCancelled)
        .toList();
    final live = events
        .where((e) => timingOf(e, now) == EventTiming.live)
        .toList();
    final next = events
        .where((e) => timingOf(e, now) == EventTiming.upcoming)
        .take(3)
        .toList();
    return [
      SliverToBoxAdapter(
        child: SectionTitle(
          '今日のステージ・イベント',
          trailing: TextButton(
            onPressed: () => onSelectTab(1),
            child: const Text('すべて見る'),
          ),
        ),
      ),
      if (live.isEmpty && next.isEmpty)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('本日のステージ・イベントはすべて終了しました。'),
          ),
        ),
      SliverList.list(
        children: [
          for (final e in [...live, ...next]) EventTile(e),
        ],
      ),
    ];
  }

  /// 「11月1日(土)」→「11月1日」
  static String _dateOnly(String label) =>
      label.replaceAll(RegExp(r'\(.\)'), '');
}

class _Hero extends StatelessWidget {
  final Edition edition;

  const _Hero({required this.edition});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, const Color(0xFF3A3F7A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edition.campus,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      edition.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${edition.days.first.label} 〜 ${edition.days.last.label}',
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            edition.themeKanji,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'テーマ字「${edition.themeKanji}（${edition.themeReading}）」',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (edition.coverImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FestivalImage(
                    edition.coverImage!,
                    height: 170,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Notice notice;

  const _NoticeCard(this.notice);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          Icons.campaign_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(
          notice.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [Text(notice.body, style: const TextStyle(height: 1.6))],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuButton(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: scheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

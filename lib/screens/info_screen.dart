import 'package:flutter/material.dart';

import '../preview_banner.dart';
import '../repository.dart';
import '../widgets.dart';

/// 「その他」タブ：挨拶・注意事項・グッズ・協賛・大学祭について。
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = FestivalScope.of(context).data;
    final festival = data.festival;
    void push(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    return Scaffold(
      appBar: AppBar(title: const Text('その他')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.record_voice_over_outlined),
            title: const Text('ご挨拶'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => push(const GreetingsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.rule),
            title: const Text('ご来場に関してのご注意'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => push(const RulesScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text('グッズ販売'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => push(const GoodsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.handshake_outlined),
            title: const Text('協賛企業・広告'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => push(const SponsorsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('大学祭について・お問い合わせ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => push(const AboutScreen()),
          ),
          const Divider(),
          const PreviewClockButton(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'データ: ${festival.edition.name}（${switch (data.source) {
                DataSource.remote => 'オンライン',
                DataSource.cache => '保存済みデータ',
                DataSource.bundled => 'アプリ内データ',
              }}）\n更新: ${festival.updatedAt}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class GreetingsScreen extends StatelessWidget {
  const GreetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final festival = FestivalScope.festivalOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('ご挨拶')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final g in festival.greetings)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.role, style: Theme.of(context).textTheme.bodySmall),
                    Text(g.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const Divider(height: 24),
                    Text(g.body, style: const TextStyle(height: 1.8)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  static const _icons = {
    'no_alcohol': Icons.no_drinks_outlined,
    'no_smoking': Icons.smoke_free,
    'no_parking': Icons.no_crash_outlined,
    'no_littering': Icons.delete_outline,
    'camera': Icons.photo_camera_outlined,
    'help': Icons.support_agent,
  };

  @override
  Widget build(BuildContext context) {
    final festival = FestivalScope.festivalOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('ご来場に関してのご注意')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: festival.rules.length,
        separatorBuilder: (_, _) => const Divider(indent: 72),
        itemBuilder: (context, i) {
          final r = festival.rules[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              child: Icon(_icons[r.icon] ?? Icons.info_outline, color: Theme.of(context).colorScheme.error),
            ),
            title: Text(r.text, style: const TextStyle(height: 1.5)),
          );
        },
      ),
    );
  }
}

class GoodsScreen extends StatelessWidget {
  const GoodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final festival = FestivalScope.festivalOf(context);
    final goods = festival.goods;
    return Scaffold(
      appBar: AppBar(title: const Text('グッズ販売')),
      body: goods == null
          ? const Center(child: Text('グッズ情報はありません'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                InfoRow(
                  Icons.schedule,
                  goods.hours
                      .map((h) => '${festival.edition.day(h.date)?.label ?? h.date} ${h.start}〜${h.end}')
                      .join('\n'),
                ),
                const SizedBox(height: 12),
                for (final item in goods.items)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.image != null)
                            SizedBox(width: 110, child: FestivalImage(item.image!)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 6),
                                for (final p in item.prices) Text('${p.label} ${p.yen}円'),
                                const SizedBox(height: 6),
                                InfoRow(Icons.place_outlined, item.place),
                                if (item.note != null)
                                  Text(item.note!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class SponsorsScreen extends StatelessWidget {
  const SponsorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sponsors = FestivalScope.festivalOf(context).sponsors;
    return Scaffold(
      appBar: AppBar(title: const Text('協賛企業・広告')),
      body: sponsors == null
          ? const Center(child: Text('協賛情報はありません'))
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const SectionTitle('広告掲載企業'),
                for (final ad in sponsors.ads)
                  ListTile(
                    title: Text(ad.name),
                    subtitle: ad.coupon == null ? null : Text('🎫 ${ad.coupon}'),
                    trailing: ad.url == null ? null : const Icon(Icons.open_in_new, size: 18),
                    onTap: ad.url == null ? null : () => openUrl(ad.url!),
                  ),
                const SectionTitle('ご寄付いただきました企業様（敬称略）'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(sponsors.donors.join('\n'), style: const TextStyle(height: 1.8)),
                ),
              ],
            ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _contactLabels = {
    'address': ('連絡先', Icons.home_work_outlined),
    'email': ('メール', Icons.mail_outline),
    'website': ('ホームページ', Icons.language),
    'instagram': ('Instagram', Icons.photo_camera_outlined),
    'x': ('X', Icons.alternate_email),
  };

  @override
  Widget build(BuildContext context) {
    final about = FestivalScope.festivalOf(context).about;
    return Scaffold(
      appBar: AppBar(title: const Text('大学祭について')),
      body: about == null
          ? const SizedBox()
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(about.publisher,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (about.afterword != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(about.afterword!, style: const TextStyle(height: 1.8)),
                  ),
                const SectionTitle('お問い合わせ・公式SNS'),
                for (final MapEntry(:key, :value) in about.contact.entries)
                  ListTile(
                    leading: Icon(_contactLabels[key]?.$2 ?? Icons.link),
                    title: Text(_contactLabels[key]?.$1 ?? key),
                    subtitle: Text(value),
                    onTap: switch (key) {
                      'email' => () => openUrl('mailto:$value'),
                      'address' => null,
                      _ => () => openUrl(value),
                    },
                  ),
              ],
            ),
    );
  }
}

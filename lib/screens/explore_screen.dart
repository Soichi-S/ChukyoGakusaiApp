import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets.dart';
import 'project_detail_screen.dart';

/// 「企画」「ブース」の2タブ。
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('企画・ブース'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '企画'),
              Tab(text: 'ブース'),
            ],
          ),
        ),
        body: const TabBarView(children: [_ProjectList(), _BoothList()]),
      ),
    );
  }
}

class _ProjectList extends StatelessWidget {
  const _ProjectList();

  @override
  Widget build(BuildContext context) {
    final festival = FestivalScope.festivalOf(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final c in festival.projectCategories) ...[
          SectionTitle(c.name),
          for (final p in festival.projects.where((p) => p.category == c.id))
            _ProjectCard(p),
        ],
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;

  const _ProjectCard(this.project);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          project.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.locationLabel),
            if (project.highlights.isNotEmpty)
              Text(
                project.highlights.join('・'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(project: project),
          ),
        ),
      ),
    );
  }
}

class _BoothList extends StatefulWidget {
  const _BoothList();

  @override
  State<_BoothList> createState() => _BoothListState();
}

// 検索窓と絞り込みは一覧の上に固定し、入力内容は controller で保持する。
// （一覧の中に置くと、スクロールで画面外に出た時に破棄されて入力が消える）
class _BoothListState extends State<_BoothList>
    with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  String? _areaId;

  @override
  bool get wantKeepAlive => true; // 企画タブと行き来しても検索状態を残す

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final festival = FestivalScope.festivalOf(context);
    final area = festival.boothAreas.where((a) => a.id == _areaId).firstOrNull;
    final booths = festival.booths
        .where(
          (b) =>
              (_areaId == null || b.areaId == _areaId) &&
              b.matches(_search.text),
        )
        .toList();
    final hours = festival.projects
        .where((p) => p.id == 'pj-booths')
        .firstOrNull;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: '食べ物・団体名で探す（例：たこ焼き）',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'クリア',
                      onPressed: () => setState(_search.clear),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('すべて'),
                selected: _areaId == null,
                onSelected: (_) => setState(() => _areaId = null),
              ),
              for (final a in festival.boothAreas)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                    label: Text(a.name),
                    selected: _areaId == a.id,
                    onSelected: (_) => setState(() => _areaId = a.id),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (hours != null &&
                  (_areaId == null || _areaId == 'central-plaza'))
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: InfoRow(
                    Icons.schedule,
                    '模擬店の営業時間\n${hours.schedule.map((s) => '${festival.edition.day(s.date)?.shortLabel} ${s.label}').join('\n')}',
                  ),
                ),
              if (area?.map != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InteractiveViewer(
                      maxScale: 4,
                      child: FestivalImage(area!.map!),
                    ),
                  ),
                ),
              if (booths.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('該当するブースがありません')),
                ),
              for (final b in booths)
                _BoothTile(
                  b,
                  areaName: festival.boothAreas
                      .firstWhere((a) => a.id == b.areaId)
                      .name,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BoothTile extends StatelessWidget {
  final Booth booth;
  final String areaName;

  const _BoothTile(this.booth, {required this.areaName});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNumber = int.tryParse(booth.no) != null;
    return ListTile(
      leading: Container(
        width: 52,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isNumber
              ? '#${booth.no}'
              : (booth.no.length > 5 ? booth.no.substring(0, 3) : booth.no),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scheme.onPrimaryContainer,
            fontSize: 13,
          ),
        ),
      ),
      title: Text(
        booth.shop,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(booth.items),
          const SizedBox(height: 2),
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Tag(booth.typeLabel),
              Text(
                '${booth.group}・$areaName${booth.floor == null ? '' : ' ${booth.floor}'}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

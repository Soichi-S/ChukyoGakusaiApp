import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final festival = FestivalScope.festivalOf(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('企画')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(project.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 4, children: [
            if (project.reservation != null) Tag(project.reservation!, color: scheme.error),
            if (project.fukubiki) Tag('ふくびき券対象', color: Colors.orange.shade800),
            if (project.price != null) Tag(project.price!),
          ]),
          const SizedBox(height: 12),
          InfoRow(Icons.place_outlined, project.locationLabel),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('開催日時', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  for (final s in project.schedule)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 76,
                            child: Text(festival.edition.day(s.date)?.shortLabel ?? s.date),
                          ),
                          Expanded(child: Text(s.label)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (project.highlights.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final h in project.highlights) Chip(label: Text(h))],
            ),
          ],
          if (project.description != null) ...[
            const SizedBox(height: 12),
            Text(project.description!, style: const TextStyle(height: 1.7)),
          ],
          if (project.targets.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('ふくびき券がもらえる企画', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            for (final id in project.targets)
              if (festival.titleOf(id) case final title?) InfoRow(Icons.check_circle_outline, title),
          ],
        ],
      ),
    );
  }
}

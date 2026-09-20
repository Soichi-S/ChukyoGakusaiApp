import 'package:chukyo_fes/models.dart';
import 'package:chukyo_fes/repository.dart';
import 'package:chukyo_fes/screens/timetable_screen.dart';
import 'package:chukyo_fes/time_utils.dart';
import 'package:chukyo_fes/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_festival.dart';

void main() {
  final festival = Festival.fromJson(testFestivalJson);

  setUp(() => previewClock.value = null);
  tearDown(() => previewClock.value = null);

  group('イベントの進行状況', () {
    final basketball = festival.events.firstWhere((e) => e.id == 'ev-1101-basketball');

    test('開始前・開催中・終了後を時刻で判定する', () {
      expect(timingOf(basketball, jst('2025-11-01', '12:00')), EventTiming.upcoming);
      expect(timingOf(basketball, jst('2025-11-01', '14:00')), EventTiming.live);
      expect(timingOf(basketball, jst('2025-11-01', '16:00')), EventTiming.past);
    });

    test('中止のイベントは cancelled として扱う', () {
      final beat = festival.events.firstWhere((e) => e.id == 'ev-1102-beat');
      expect(beat.isCancelled, isTrue);
    });
  });

  group('タイムテーブル画面', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FestivalScope(
            data: LoadedFestival(festival, DataSource.bundled, 'data/2025/'),
            reload: () async {},
            child: const TimetableScreen(),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('開催日はその日のタブが開く', (tester) async {
      previewClock.value = jst('2025-11-03', '11:00');
      await pump(tester);

      final controller = DefaultTabController.of(
        tester.element(find.byType(TabBarView)),
      );
      expect(controller.index, 2); // 11/3 は3日目
      expect(find.text('DOPERS'), findsWidgets);
    });

    testWidgets('開催日以外は初日のタブが開く', (tester) async {
      previewClock.value = jst('2025-10-25', '12:00');
      await pump(tester);

      final controller = DefaultTabController.of(
        tester.element(find.byType(TabBarView)),
      );
      expect(controller.index, 0);
    });

    testWidgets('ステージ・大会は会場ごとに分かれ、ガレリアステージが先頭', (tester) async {
      previewClock.value = jst('2025-11-01', '14:20');
      await pump(tester);

      // 会場名はカードの中にも出るため、見出し（SectionTitle）だけを対象にする
      Finder heading(String name) => find.descendant(
            of: find.byType(SectionTitle),
            matching: find.text(name),
          );
      expect(heading('0号館 ガレリアステージ'), findsOneWidget);
      expect(heading('体育館'), findsOneWidget);
      expect(
        tester.getTopLeft(heading('0号館 ガレリアステージ')).dy,
        lessThan(tester.getTopLeft(heading('体育館')).dy),
      );
    });
  });
}

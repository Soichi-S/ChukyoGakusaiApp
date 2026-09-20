import 'package:chukyo_fes/models.dart';
import 'package:chukyo_fes/repository.dart';
import 'package:chukyo_fes/screens/home_screen.dart';
import 'package:chukyo_fes/time_utils.dart';
import 'package:chukyo_fes/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_festival.dart';

/// ホーム画面は、開催前・開催中・開催後で見出しが切り替わる。
/// 年度のデータを差し替えても崩れないよう、ここで固定しておく。
void main() {
  final festival = Festival.fromJson(testFestivalJson);

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FestivalScope(
          data: LoadedFestival(festival, DataSource.bundled, 'data/2025/'),
          reload: () async {},
          child: HomeScreen(onSelectTab: (_) {}),
        ),
      ),
    );
    await tester.pump();
  }

  setUp(() => previewClock.value = null);
  tearDown(() => previewClock.value = null);

  testWidgets('開催前は開幕までの日数と初日のステージを出す', (tester) async {
    previewClock.value = jst('2025-10-25', '12:00');
    await pumpHome(tester);

    expect(find.text('開幕まであと7日'), findsOneWidget);
    expect(find.text('11月1日のステージ・イベント'), findsOneWidget);
    expect(find.text('中京大学文化会書道部'), findsOneWidget);
    expect(find.text('今日のステージ・イベント'), findsNothing);
  });

  testWidgets('開催日は今日のステージを出し、開催中の印を付ける', (tester) async {
    previewClock.value = jst('2025-11-01', '14:20');
    await pumpHome(tester);

    expect(find.text('今日のステージ・イベント'), findsOneWidget);
    expect(find.text('開催中'), findsWidgets);
    // 終了済み（12:10〜12:40）は「この後」に出さない
    expect(find.text('中京大学文化会書道部'), findsNothing);
    expect(find.text('開催日程'), findsNothing);
  });

  testWidgets('最終日の終了後は本日分が終わった旨を出す', (tester) async {
    previewClock.value = jst('2025-11-03', '17:30');
    await pumpHome(tester);

    expect(find.text('今日のステージ・イベント'), findsOneWidget);
    expect(find.text('本日のステージ・イベントはすべて終了しました。'), findsOneWidget);
  });

  testWidgets('開催後は終了した旨を出し、初日のステージは出さない', (tester) async {
    previewClock.value = jst('2025-11-10', '12:00');
    await pumpHome(tester);

    expect(find.text('今年の大学祭は終了しました。ご来場ありがとうございました。'), findsOneWidget);
    expect(find.textContaining('のステージ・イベント'), findsNothing);
  });
}

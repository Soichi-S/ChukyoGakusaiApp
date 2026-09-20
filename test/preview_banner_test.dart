import 'package:chukyo_fes/preview_banner.dart';
import 'package:chukyo_fes/time_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 確認用の日時切り替え。ストア配布版では timeOverrideAllowed が false になり、
/// 帯もボタンも出なくなる（テストはデバッグ実行なので true）。
void main() {
  setUp(() => previewClock.value = null);
  tearDown(() => previewClock.value = null);

  testWidgets('日時を指定していないときは帯を出さない', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PreviewBanner()));
    expect(find.textContaining('確認用'), findsNothing);
  });

  testWidgets('指定中は帯に日時を出し、解除で実際の日時に戻る', (tester) async {
    previewClock.value = jst('2025-11-02', '13:55');
    await tester.pumpWidget(const MaterialApp(home: PreviewBanner()));

    expect(find.text('確認用：2025/11/02 13:55 として表示中'), findsOneWidget);

    await tester.tap(find.text('解除'));
    await tester.pump();

    expect(previewClock.value, isNull);
    expect(find.textContaining('確認用'), findsNothing);
  });

  testWidgets('「変更」で日付と時刻を選ぶと表示に反映される', (tester) async {
    previewClock.value = jst('2025-11-02', '13:55');
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PreviewBanner())));

    await tester.tap(find.text('変更'));
    await tester.pumpAndSettle();
    expect(find.text('確認用の日付を選ぶ'), findsOneWidget);

    await tester.tap(find.text('1')); // 11月1日
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('確認用の時刻を選ぶ'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(previewClock.value, jst('2025-11-01', '13:55'));
    expect(find.text('確認用：2025/11/01 13:55 として表示中'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';

import 'time_utils.dart';

/// 確認用に日時を固定しているときだけ出る帯。
/// 日付と時刻を選び直せて、「解除」で実際の日時に戻る。
/// ストア配布の本番ビルドでは timeOverrideAllowed が false のため、そもそも出ない。
class PreviewBanner extends StatelessWidget {
  const PreviewBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!timeOverrideAllowed) return const SizedBox.shrink();
    return ValueListenableBuilder<DateTime?>(
      valueListenable: previewClock,
      builder: (context, clock, _) {
        if (clock == null) return const SizedBox.shrink();
        return Material(
          color: Colors.orange.shade100,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
              child: Row(
                children: [
                  Icon(Icons.science_outlined, size: 18, color: Colors.orange.shade900),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '確認用：${formatJstForDisplay(clock)} として表示中',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pick(context, clock),
                    child: const Text('変更', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () => setPreviewClock(null),
                    child: const Text('解除', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pick(BuildContext context, DateTime current) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.utc(current.year - 2),
      lastDate: DateTime.utc(current.year + 2),
      helpText: '確認用の日付を選ぶ',
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: '確認用の時刻を選ぶ',
    );
    if (time == null) return;
    // 日本時間の壁時計として扱うため UTC の DateTime に入れる
    setPreviewClock(
      DateTime.utc(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}

/// 確認用ビルドで、日時が未設定のときに切り替えを始めるためのボタン。
/// 「その他」画面の最下部に置く。
class PreviewClockButton extends StatelessWidget {
  const PreviewClockButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!timeOverrideAllowed) return const SizedBox.shrink();
    return ValueListenableBuilder<DateTime?>(
      valueListenable: previewClock,
      builder: (context, clock, _) {
        if (clock != null) return const SizedBox.shrink();
        return ListTile(
          leading: const Icon(Icons.science_outlined),
          title: const Text('確認用：日時を指定して表示する'),
          subtitle: const Text('開催前・開催中・開催後の画面を確かめられます'),
          onTap: () => setPreviewClock(jstNow()),
        );
      },
    );
  }
}

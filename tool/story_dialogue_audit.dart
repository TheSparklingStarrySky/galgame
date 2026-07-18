// ignore_for_file: avoid_print

import 'package:galgame/story/story.dart';

const _speechVerbs = <String>[
  '说',
  '问',
  '回答',
  '反问',
  '提醒',
  '要求',
  '提议',
  '承认',
  '解释',
  '补充',
  '坚持',
  '拒绝',
  '争论',
];

void main() {
  for (final chapter in ['ch1_', 'ch2_', 'ch3_', 'ch4_', 'ch5_']) {
    final beats = storyBeats.values
        .where((beat) => beat.id.startsWith(chapter))
        .toList(growable: false);
    var narrationChars = 0;
    var dialogueChars = 0;
    final suspicious = <String>[];

    for (final beat in beats) {
      final paragraphCount = beat.text.split('\n').length;
      if (beat.passageSpeakers.isNotEmpty &&
          beat.passageSpeakers.length != paragraphCount) {
        print(
          '${beat.id}: paragraphCount=$paragraphCount, '
          'speakerCount=${beat.passageSpeakers.length}',
        );
        continue;
      }
      for (final passage in beat.passages) {
        if (passage.speaker == Speaker.narration) {
          narrationChars += passage.text.length;
          final summarizesSpeech = _speechVerbs.any(passage.text.contains);
          final hasDirectQuote = passage.text.contains('“');
          if (summarizesSpeech &&
              !hasDirectQuote &&
              passage.text.length >= 48) {
            suspicious.add('${beat.id}: ${_preview(passage.text)}');
          }
        } else {
          dialogueChars += passage.text.length;
        }
      }
    }

    final total = narrationChars + dialogueChars;
    final dialoguePercent = total == 0 ? 0 : dialogueChars * 100 / total;
    print(
      '$chapter ${beats.length} beats | direct character passages '
      '${dialoguePercent.toStringAsFixed(1)}% | suspicious '
      '${suspicious.length}',
    );
    for (final line in suspicious) {
      print('  $line');
    }
  }
}

String _preview(String value) {
  final oneLine = value.replaceAll('\n', ' ');
  if (oneLine.length <= 72) return oneLine;
  return '${oneLine.substring(0, 72)}...';
}

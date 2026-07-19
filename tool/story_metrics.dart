// ignore_for_file: avoid_print

import 'package:galgame/story/story.dart';

const _draftEndingIds = {
  'pact_end',
  'pact_end_result',
  'xingyao_end',
  'xingyao_end_result',
  'sumi_end',
  'sumi_end_result',
  'lincheng_end',
  'lincheng_end_result',
};

int _han(String value) =>
    RegExp(r'[\u3400-\u4DBF\u4E00-\u9FFF]').allMatches(value).length;

int _visible(String value) => value.replaceAll(RegExp(r'\s'), '').runes.length;

String _choiceText(StoryBeat beat) =>
    beat.choices.map((choice) => '${choice.label}${choice.caption}').join();

List<String> _outgoing(StoryBeat beat) {
  if (beat.id == 'deduction_gate') {
    return const ['bad_end', 'shadow_end', 'ch2_case_conclusion'];
  }
  if (beat.id == 'ch3_delegation_gate') {
    return const ['ch3_delegate_hanqi'];
  }
  if (beat.id == 'ch4_case03_deduction') {
    return const ['ch4_case03_resolved'];
  }
  if (beat.id == 'ch5_case04_deduction') {
    return const ['ch5_case04_resolved'];
  }
  if (beat.id == 'ch6_case05_deduction') {
    return const ['ch6_case05_resolved'];
  }
  if (beat.id == 'ch7_case06_deduction') {
    return const ['ch7_case06_resolved'];
  }
  if (beat.choices.isNotEmpty) {
    return beat.choices.map((choice) => choice.next).toSet().toList();
  }
  return {
    if (beat.next case final next?) next,
    ...beat.nextByFlag.values,
  }.toList(growable: false);
}

({int visible, int nodes, List<String> ids}) _pathMetrics(List<String> ids) {
  final beats = ids.map((id) => storyBeats[id]!).toList();
  final text = beats.map((beat) => beat.text + _choiceText(beat)).join();
  return (visible: _visible(text), nodes: ids.length, ids: ids);
}

void _printGroup(String name, Iterable<StoryBeat> source) {
  final beats = source.toList(growable: false);
  final body = beats.map((beat) => beat.text).join();
  final choices = beats.map(_choiceText).join();
  final labels = beats.map((beat) => beat.label).join();
  final passages = beats.fold<int>(
    0,
    (total, beat) => total + beat.passages.length,
  );
  print(
    '$name: nodes=${beats.length}, passages=$passages, '
    'bodyVisible=${_visible(body)}, bodyHan=${_han(body)}, '
    'choicesVisible=${_visible(choices)}, labelsVisible=${_visible(labels)}, '
    'totalVisible=${_visible(body + choices + labels)}',
  );
}

void main() {
  final chapterOne = storyBeats.values.where(
    (beat) =>
        !beat.id.startsWith('ch2_') &&
        !beat.id.startsWith('ch3_') &&
        !beat.id.startsWith('ch4_') &&
        !beat.id.startsWith('ch5_') &&
        !beat.id.startsWith('ch6_') &&
        !beat.id.startsWith('ch7_') &&
        !_draftEndingIds.contains(beat.id),
  );
  final chapterTwo = storyBeats.values.where(
    (beat) => beat.id.startsWith('ch2_'),
  );
  final chapterThree = storyBeats.values.where(
    (beat) => beat.id.startsWith('ch3_'),
  );
  final chapterFour = storyBeats.values.where(
    (beat) => beat.id.startsWith('ch4_'),
  );
  final chapterFive = storyBeats.values.where(
    (beat) => beat.id.startsWith('ch5_'),
  );
  final chapterSix = storyBeats.values.where(
    (beat) => beat.id.startsWith('ch6_'),
  );
  final chapterSeven = storyBeats.values.where(
    (beat) => beat.id.startsWith('ch7_'),
  );
  final draftEndings = storyBeats.values.where(
    (beat) => _draftEndingIds.contains(beat.id),
  );

  _printGroup('chapter1', chapterOne);
  _printGroup('chapter2', chapterTwo);
  _printGroup('chapter3', chapterThree);
  _printGroup('chapter4', chapterFour);
  _printGroup('chapter5', chapterFive);
  _printGroup('chapter6', chapterSix);
  _printGroup('chapter7', chapterSeven);
  _printGroup('draftEndings', draftEndings);
  _printGroup('allStoryData', storyBeats.values);

  List<List<String>> collectPaths(String start, {String? stopAt}) {
    final paths = <List<String>>[];
    void walk(String id, List<String> prefix) {
      if (paths.length >= 20000) return;
      final path = [...prefix, id];
      if (prefix.contains(id)) {
        paths.add(path);
        return;
      }
      if (id == stopAt) {
        paths.add(path);
        return;
      }
      final next = _outgoing(storyBeats[id]!);
      if (next.isEmpty) {
        paths.add(path);
        return;
      }
      for (final target in next) {
        walk(target, path);
      }
    }

    walk(start, const []);
    return paths;
  }

  final chapterTwoPaths = collectPaths(
    'ch2_chapter_title',
    stopAt: 'ch2_end',
  ).map(_pathMetrics).toList()..sort((a, b) => a.visible.compareTo(b.visible));
  print(
    'chapter2Playthrough: paths=${chapterTwoPaths.length}, '
    'visible=${chapterTwoPaths.first.visible}-${chapterTwoPaths.last.visible}, '
    'nodes=${chapterTwoPaths.first.nodes}-${chapterTwoPaths.last.nodes}',
  );
  final chapterThreePaths = collectPaths(
    'ch3_chapter_title',
    stopAt: 'ch3_end',
  ).map(_pathMetrics).toList()..sort((a, b) => a.visible.compareTo(b.visible));
  print(
    'chapter3Playthrough: paths=${chapterThreePaths.length}, '
    'visible=${chapterThreePaths.first.visible}-${chapterThreePaths.last.visible}, '
    'nodes=${chapterThreePaths.first.nodes}-${chapterThreePaths.last.nodes}',
  );
  final chapterFourPaths = collectPaths(
    'ch4_daybreak',
    stopAt: 'ch4_end',
  ).map(_pathMetrics).toList()..sort((a, b) => a.visible.compareTo(b.visible));
  print(
    'chapter4StandardPlaythrough: paths=${chapterFourPaths.length}, '
    'visible=${chapterFourPaths.first.visible}-${chapterFourPaths.last.visible}, '
    'nodes=${chapterFourPaths.first.nodes}-${chapterFourPaths.last.nodes}',
  );
  final chapterFourAuditPaths = collectPaths(
    'ch4_audit_projection',
    stopAt: 'ch4_end',
  ).map(_pathMetrics).toList()..sort((a, b) => a.visible.compareTo(b.visible));
  print(
    'chapter4AuditFromProjection: paths=${chapterFourAuditPaths.length}, '
    'visible=${chapterFourAuditPaths.first.visible}-'
    '${chapterFourAuditPaths.last.visible}, '
    'nodes=${chapterFourAuditPaths.first.nodes}-${chapterFourAuditPaths.last.nodes}',
  );
  final chapterFivePaths = collectPaths(
    'ch5_midnight',
    stopAt: 'ch5_end',
  ).map(_pathMetrics).toList()..sort((a, b) => a.visible.compareTo(b.visible));
  print(
    'chapter5Playthrough: paths=${chapterFivePaths.length}, '
    'visible=${chapterFivePaths.first.visible}-${chapterFivePaths.last.visible}, '
    'nodes=${chapterFivePaths.first.nodes}-${chapterFivePaths.last.nodes}',
  );
  final chapterSixPaths = collectPaths(
    'ch6_vote_opening',
    stopAt: 'ch6_end',
  ).map(_pathMetrics).toList()..sort((a, b) => a.visible.compareTo(b.visible));
  print(
    'chapter6Playthrough: paths=${chapterSixPaths.length}, '
    'visible=${chapterSixPaths.first.visible}-${chapterSixPaths.last.visible}, '
    'nodes=${chapterSixPaths.first.nodes}-${chapterSixPaths.last.nodes}',
  );
  final chapterSevenPaths = collectPaths(
    'ch7_day_six_open',
    stopAt: 'ch7_end',
  ).map(_pathMetrics).toList()..sort((a, b) => a.visible.compareTo(b.visible));
  print(
    'chapter7Playthrough: paths=${chapterSevenPaths.length}, '
    'visible=${chapterSevenPaths.first.visible}-${chapterSevenPaths.last.visible}, '
    'nodes=${chapterSevenPaths.first.nodes}-${chapterSevenPaths.last.nodes}',
  );
}

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
  if (beat.choices.isNotEmpty) {
    return beat.choices.map((choice) => choice.next).toSet().toList();
  }
  return beat.next == null ? const [] : [beat.next!];
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
    (beat) => !beat.id.startsWith('ch2_') && !_draftEndingIds.contains(beat.id),
  );
  final chapterTwo = storyBeats.values.where(
    (beat) => beat.id.startsWith('ch2_'),
  );
  final draftEndings = storyBeats.values.where(
    (beat) => _draftEndingIds.contains(beat.id),
  );

  _printGroup('chapter1', chapterOne);
  _printGroup('chapter2', chapterTwo);
  _printGroup('draftEndings', draftEndings);
  _printGroup('allStoryData', storyBeats.values);

  final paths = <List<String>>[];
  void walk(String id, List<String> prefix) {
    final path = [...prefix, id];
    final next = _outgoing(storyBeats[id]!);
    if (next.isEmpty) {
      paths.add(path);
      return;
    }
    for (final target in next) {
      walk(target, path);
    }
  }

  walk('game_start', const []);
  final chapterTwoPaths =
      paths
          .map(_pathMetrics)
          .where((path) => path.ids.contains('ch2_end'))
          .toList()
        ..sort((a, b) => a.visible.compareTo(b.visible));
  print(
    'chapter2Playthrough: paths=${chapterTwoPaths.length}, '
    'visible=${chapterTwoPaths.first.visible}-${chapterTwoPaths.last.visible}, '
    'nodes=${chapterTwoPaths.first.nodes}-${chapterTwoPaths.last.nodes}',
  );
}

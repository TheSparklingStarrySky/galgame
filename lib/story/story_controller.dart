import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'story.dart';

class SaveSnapshot {
  const SaveSnapshot({
    required this.currentId,
    required this.savedAt,
    required this.xingyaoTrust,
    required this.sumiTrust,
    required this.linchengTrust,
    required this.logic,
    required this.cooperation,
    required this.flags,
    required this.foundClues,
    required this.inventoryItems,
    required this.investigationActions,
    required this.investigationClues,
    required this.historyIds,
    this.markedSector,
  });

  final String currentId;
  final DateTime savedAt;
  final int xingyaoTrust;
  final int sumiTrust;
  final int linchengTrust;
  final int logic;
  final int cooperation;
  final Set<String> flags;
  final Set<String> foundClues;
  final Set<String> inventoryItems;
  final Set<String> investigationActions;
  final Set<String> investigationClues;
  final List<String> historyIds;
  final String? markedSector;

  String get nodeLabel => storyBeats[currentId]?.label ?? currentId;

  Map<String, dynamic> toJson() => {
    'currentId': currentId,
    'savedAt': savedAt.toIso8601String(),
    'xingyaoTrust': xingyaoTrust,
    'sumiTrust': sumiTrust,
    'linchengTrust': linchengTrust,
    'logic': logic,
    'cooperation': cooperation,
    'flags': flags.toList(),
    'foundClues': foundClues.toList(),
    'inventoryItems': inventoryItems.toList(),
    'investigationActions': investigationActions.toList(),
    'investigationClues': investigationClues.toList(),
    'historyIds': historyIds,
    'markedSector': markedSector,
  };

  static SaveSnapshot? fromJson(Map<String, dynamic> json) {
    final id = json['currentId'] as String?;
    if (id == null || !storyBeats.containsKey(id)) return null;
    return SaveSnapshot(
      currentId: id,
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
      xingyaoTrust: json['xingyaoTrust'] as int? ?? 0,
      sumiTrust: json['sumiTrust'] as int? ?? 0,
      linchengTrust: json['linchengTrust'] as int? ?? 0,
      logic: json['logic'] as int? ?? 0,
      cooperation: json['cooperation'] as int? ?? 0,
      flags: (json['flags'] as List<dynamic>? ?? []).cast<String>().toSet(),
      foundClues: (json['foundClues'] as List<dynamic>? ?? [])
          .cast<String>()
          .toSet(),
      inventoryItems: (json['inventoryItems'] as List<dynamic>? ?? [])
          .cast<String>()
          .toSet(),
      investigationActions:
          (json['investigationActions'] as List<dynamic>? ?? [])
              .cast<String>()
              .toSet(),
      investigationClues: (json['investigationClues'] as List<dynamic>? ?? [])
          .cast<String>()
          .toSet(),
      historyIds: (json['historyIds'] as List<dynamic>? ?? []).cast<String>(),
      markedSector: json['markedSector'] as String?,
    );
  }
}

class StoryController extends ChangeNotifier {
  StoryController._(this._preferences);

  static const slotCount = 8;
  static const gameDurationMinutes = 7 * 24 * 60;
  static const _autoSaveKey = 'zero_protocol_auto_v2';
  static const _slotPrefix = 'zero_protocol_slot_v2_';
  static const _collectionKey = 'zero_protocol_collection_v2';
  static const _settingsKey = 'zero_protocol_settings_v2';
  static const _checkpointKey = 'zero_protocol_checkpoints_v2';

  final SharedPreferences _preferences;

  StoryPhase phase = StoryPhase.title;
  String currentId = 'game_start';
  int xingyaoTrust = 0;
  int sumiTrust = 0;
  int linchengTrust = 0;
  int logic = 0;
  int cooperation = 0;
  double textSpeed = 0.65;
  double autoDelay = 1.8;
  bool reduceMotion = false;
  bool skipUnread = false;
  bool autoPlay = false;
  bool skipMode = false;
  bool hasAutoSave = false;
  String? markedSector;

  final Set<String> flags = {};
  final Set<String> foundClues = {};
  final Set<String> inventoryItems = {};
  final Set<String> investigationActions = {};
  final Set<String> investigationClues = {};
  final Set<String> seenNodes = {};
  final Set<String> readNodes = {};
  final Set<String> unlockedCgs = {};
  final Set<String> unlockedEndings = {};
  final List<StoryBeat> history = [];
  final Map<String, SaveSnapshot> checkpoints = {};
  final List<SaveSnapshot?> saveSlots = List.filled(slotCount, null);

  static Future<StoryController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final controller = StoryController._(preferences);
    controller._restorePersistentData();
    return controller;
  }

  StoryBeat get current => storyBeats[currentId]!;

  SceneKey get scene =>
      phase == StoryPhase.title ? SceneKey.dormitory : current.scene;

  List<StoryChoice> get availableChoices => current.choices
      .where(
        (choice) =>
            choice.requiresFlag == null || flags.contains(choice.requiresFlag),
      )
      .toList(growable: false);

  bool get canSkipCurrent => skipUnread || readNodes.contains(currentId);

  int get progressPercent {
    final index = routeNodes.lastIndexWhere(
      (node) => seenNodes.contains(node.id),
    );
    if (index < 0) return 0;
    return ((index / (routeNodes.length - 1)) * 100).round().clamp(0, 100);
  }

  int get seenRouteNodeCount =>
      routeNodes.where((node) => seenNodes.contains(node.id)).length;

  String get remainingTime {
    var minutesElapsed = (history.length - 1).clamp(0, history.length) * 3;
    for (var index = history.length - 1; index >= 0; index--) {
      final anchor = history[index].timelineMinute;
      if (anchor == null) continue;
      minutesElapsed = anchor + (history.length - 1 - index) * 3;
      break;
    }
    minutesElapsed = minutesElapsed.clamp(0, gameDurationMinutes - 60);
    final remaining = gameDurationMinutes - minutesElapsed;
    final hours = remaining ~/ 60;
    final minutes = remaining % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:00';
  }

  void startNew() {
    currentId = 'game_start';
    xingyaoTrust = 0;
    sumiTrust = 0;
    linchengTrust = 0;
    logic = 0;
    cooperation = 0;
    markedSector = null;
    flags.clear();
    foundClues.clear();
    inventoryItems.clear();
    investigationActions.clear();
    investigationClues.clear();
    history.clear();
    autoPlay = false;
    skipMode = false;
    _enterCurrent();
  }

  void resume() {
    final snapshot = _decodeSnapshot(_preferences.getString(_autoSaveKey));
    if (snapshot == null) {
      startNew();
      return;
    }
    _restoreSnapshot(snapshot);
    notifyListeners();
  }

  void returnToTitle() {
    phase = StoryPhase.title;
    autoPlay = false;
    skipMode = false;
    notifyListeners();
  }

  Future<void> saveToSlot(int index) async {
    if (index < 0 || index >= slotCount || phase == StoryPhase.title) return;
    final snapshot = _createSnapshot();
    saveSlots[index] = snapshot;
    await _preferences.setString(
      '$_slotPrefix$index',
      jsonEncode(snapshot.toJson()),
    );
    notifyListeners();
  }

  void loadSlot(int index) {
    if (index < 0 || index >= slotCount) return;
    final snapshot = saveSlots[index];
    if (snapshot == null) return;
    _restoreSnapshot(snapshot);
    _saveAuto();
    notifyListeners();
  }

  Future<void> deleteSlot(int index) async {
    if (index < 0 || index >= slotCount) return;
    saveSlots[index] = null;
    await _preferences.remove('$_slotPrefix$index');
    notifyListeners();
  }

  void jumpToNode(String id) {
    final snapshot = checkpoints[id];
    if (snapshot == null || !seenNodes.contains(id)) return;
    _restoreSnapshot(snapshot);
    autoPlay = false;
    skipMode = false;
    _saveAuto();
    notifyListeners();
  }

  void advance() {
    if (phase != StoryPhase.dialogue || current.choices.isNotEmpty) return;
    final next = current.next;
    if (next == null) return;
    _markCurrentRead();
    currentId = next;
    _enterCurrent();
  }

  void choose(StoryChoice choice) {
    if (!availableChoices.contains(choice)) return;
    _markCurrentRead();
    final effect = choice.effect;
    xingyaoTrust += effect.xingyao;
    sumiTrust += effect.sumi;
    linchengTrust += effect.lincheng;
    logic += effect.logic;
    cooperation += effect.cooperation;
    if (effect.flag case final flag?) flags.add(flag);

    if (currentId == 'response_choice') {
      if (choice.next == 'chase_signal' && flags.contains('route_xingyao')) {
        flags.add('bond_xingyao');
      }
      if (choice.next == 'help_sumi' && flags.contains('route_sumi')) {
        flags.add('bond_sumi');
      }
      if (choice.next == 'help_lincheng' && flags.contains('route_lincheng')) {
        flags.add('bond_lincheng');
      }
      if (choice.next == 'help_sumi' && markedSector == 'medical') {
        cooperation += 1;
        flags.add('planned_medical_route');
      }
      if (choice.next == 'chase_signal' && markedSector == 'storage') {
        logic += 1;
        flags.add('planned_storage_route');
      }
      if (choice.next == 'help_lincheng' && markedSector == 'archive') {
        logic += 1;
        flags.add('planned_archive_route');
      }
    }

    currentId = choice.next;
    _enterCurrent();
  }

  void completeInvestigation(Set<String> clues) {
    foundClues.addAll(clues);
    logic += clues.length;
    _markCurrentRead();
    currentId = current.next!;
    _enterCurrent();
  }

  void collectInvestigationItem(String itemId) {
    if (!inventoryItems.add(itemId)) return;
    _saveAuto();
    notifyListeners();
  }

  void recordInvestigationAction(
    String actionId, {
    String? grantsItem,
    String? verifiesClue,
    Iterable<String> consumesItems = const [],
  }) {
    if (!investigationActions.add(actionId)) return;
    inventoryItems.removeAll(consumesItems);
    if (grantsItem != null) inventoryItems.add(grantsItem);
    if (verifiesClue != null) investigationClues.add(verifiesClue);
    _saveAuto();
    notifyListeners();
  }

  void completeTuning() {
    flags.add('relay_log');
    logic += 1;
    _markCurrentRead();
    currentId = current.next!;
    _enterCurrent();
  }

  void submitDeduction(String hypothesis) {
    _markCurrentRead();
    if (hypothesis == 'suicide') {
      currentId = 'bad_end';
    } else if (hypothesis == 'repeater' && cooperation >= 2) {
      flags.add('case01_solved');
      currentId = 'ch2_case_conclusion';
    } else {
      currentId = 'shadow_end';
    }
    _enterCurrent();
  }

  void setMarkedSector(String? sector) {
    markedSector = sector;
    _saveAuto();
    notifyListeners();
  }

  void setAutoPlay(bool value) {
    autoPlay = value;
    if (value) skipMode = false;
    notifyListeners();
  }

  void setSkipMode(bool value) {
    if (value && !canSkipCurrent) return;
    skipMode = value;
    if (value) autoPlay = false;
    notifyListeners();
  }

  void setTextSpeed(double value) {
    textSpeed = value;
    _saveSettings();
    notifyListeners();
  }

  void setAutoDelay(double value) {
    autoDelay = value;
    _saveSettings();
    notifyListeners();
  }

  void setReduceMotion(bool value) {
    reduceMotion = value;
    _saveSettings();
    notifyListeners();
  }

  void setSkipUnread(bool value) {
    skipUnread = value;
    _saveSettings();
    notifyListeners();
  }

  void _enterCurrent() {
    phase = current.phase;
    seenNodes.add(currentId);
    if (current.cgId case final cg?) unlockedCgs.add(cg);
    if (current.endingId case final ending?) unlockedEndings.add(ending);
    _recordCurrent();
    final snapshot = _createSnapshot();
    checkpoints[currentId] = snapshot;
    hasAutoSave = true;
    _savePersistentProgress();
    _saveAuto();
    notifyListeners();
  }

  void _markCurrentRead() {
    readNodes.add(currentId);
    _saveCollections();
  }

  void _recordCurrent() {
    if (current.text.isEmpty) return;
    if (history.isNotEmpty && history.last.id == current.id) return;
    history.add(current);
    if (history.length > 120) history.removeAt(0);
  }

  SaveSnapshot _createSnapshot() => SaveSnapshot(
    currentId: currentId,
    savedAt: DateTime.now(),
    xingyaoTrust: xingyaoTrust,
    sumiTrust: sumiTrust,
    linchengTrust: linchengTrust,
    logic: logic,
    cooperation: cooperation,
    flags: Set.of(flags),
    foundClues: Set.of(foundClues),
    inventoryItems: Set.of(inventoryItems),
    investigationActions: Set.of(investigationActions),
    investigationClues: Set.of(investigationClues),
    historyIds: history.map((beat) => beat.id).toList(),
    markedSector: markedSector,
  );

  void _restoreSnapshot(SaveSnapshot snapshot) {
    currentId = snapshot.currentId;
    xingyaoTrust = snapshot.xingyaoTrust;
    sumiTrust = snapshot.sumiTrust;
    linchengTrust = snapshot.linchengTrust;
    logic = snapshot.logic;
    cooperation = snapshot.cooperation;
    markedSector = snapshot.markedSector;
    flags
      ..clear()
      ..addAll(snapshot.flags);
    foundClues
      ..clear()
      ..addAll(snapshot.foundClues);
    inventoryItems
      ..clear()
      ..addAll(snapshot.inventoryItems);
    investigationActions
      ..clear()
      ..addAll(snapshot.investigationActions);
    investigationClues
      ..clear()
      ..addAll(snapshot.investigationClues);
    history
      ..clear()
      ..addAll(
        snapshot.historyIds.map((id) => storyBeats[id]).whereType<StoryBeat>(),
      );
    phase = current.phase;
    seenNodes.add(currentId);
  }

  SaveSnapshot? _decodeSnapshot(String? raw) {
    if (raw == null) return null;
    try {
      return SaveSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  void _restorePersistentData() {
    final settingsRaw = _preferences.getString(_settingsKey);
    if (settingsRaw != null) {
      try {
        final settings = jsonDecode(settingsRaw) as Map<String, dynamic>;
        textSpeed = (settings['textSpeed'] as num?)?.toDouble() ?? 0.65;
        autoDelay = (settings['autoDelay'] as num?)?.toDouble() ?? 1.8;
        reduceMotion = settings['reduceMotion'] as bool? ?? false;
        skipUnread = settings['skipUnread'] as bool? ?? false;
      } on FormatException {
        _preferences.remove(_settingsKey);
      }
    }

    final collectionRaw = _preferences.getString(_collectionKey);
    if (collectionRaw != null) {
      try {
        final data = jsonDecode(collectionRaw) as Map<String, dynamic>;
        seenNodes.addAll(
          (data['seenNodes'] as List<dynamic>? ?? []).cast<String>(),
        );
        readNodes.addAll(
          (data['readNodes'] as List<dynamic>? ?? []).cast<String>(),
        );
        unlockedCgs.addAll(
          (data['unlockedCgs'] as List<dynamic>? ?? []).cast<String>(),
        );
        unlockedEndings.addAll(
          (data['unlockedEndings'] as List<dynamic>? ?? []).cast<String>(),
        );
      } on FormatException {
        _preferences.remove(_collectionKey);
      }
    }

    final checkpointRaw = _preferences.getString(_checkpointKey);
    if (checkpointRaw != null) {
      try {
        final data = jsonDecode(checkpointRaw) as Map<String, dynamic>;
        for (final entry in data.entries) {
          final value = SaveSnapshot.fromJson(
            entry.value as Map<String, dynamic>,
          );
          if (value != null) checkpoints[entry.key] = value;
        }
      } on FormatException {
        _preferences.remove(_checkpointKey);
      }
    }

    for (var index = 0; index < slotCount; index++) {
      saveSlots[index] = _decodeSnapshot(
        _preferences.getString('$_slotPrefix$index'),
      );
    }
    hasAutoSave = _decodeSnapshot(_preferences.getString(_autoSaveKey)) != null;
  }

  void _saveAuto() {
    if (phase == StoryPhase.title) return;
    _preferences.setString(
      _autoSaveKey,
      jsonEncode(_createSnapshot().toJson()),
    );
    hasAutoSave = true;
  }

  void _savePersistentProgress() {
    _saveCollections();
    _preferences.setString(
      _checkpointKey,
      jsonEncode(
        checkpoints.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
  }

  void _saveCollections() {
    _preferences.setString(
      _collectionKey,
      jsonEncode({
        'seenNodes': seenNodes.toList(),
        'readNodes': readNodes.toList(),
        'unlockedCgs': unlockedCgs.toList(),
        'unlockedEndings': unlockedEndings.toList(),
      }),
    );
  }

  void _saveSettings() {
    _preferences.setString(
      _settingsKey,
      jsonEncode({
        'textSpeed': textSpeed,
        'autoDelay': autoDelay,
        'reduceMotion': reduceMotion,
        'skipUnread': skipUnread,
      }),
    );
  }
}

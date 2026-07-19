import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'story.dart';

class HighRiskItemRecord {
  const HighRiskItemRecord({
    required this.id,
    required this.state,
    this.holderId,
    this.updatedAtMinute,
  });

  final String id;
  final HighRiskItemState state;
  final String? holderId;
  final int? updatedAtMinute;

  HighRiskItemRecord copyWith({
    HighRiskItemState? state,
    String? holderId,
    bool clearHolder = false,
    int? updatedAtMinute,
  }) => HighRiskItemRecord(
    id: id,
    state: state ?? this.state,
    holderId: clearHolder ? null : holderId ?? this.holderId,
    updatedAtMinute: updatedAtMinute ?? this.updatedAtMinute,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'state': state.name,
    'holderId': holderId,
    'updatedAtMinute': updatedAtMinute,
  };

  static HighRiskItemRecord? fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null || !highRiskItemDefinitions.any((item) => item.id == id)) {
      return null;
    }
    final stateName = json['state'] as String?;
    final state = HighRiskItemState.values
        .where((value) => value.name == stateName)
        .firstOrNull;
    return HighRiskItemRecord(
      id: id,
      state: state ?? HighRiskItemState.sealed,
      holderId: json['holderId'] as String?,
      updatedAtMinute: json['updatedAtMinute'] as int?,
    );
  }
}

class ParticipantDeathRecord {
  const ParticipantDeathRecord({
    required this.participantId,
    required this.cause,
    required this.timelineMinute,
    required this.storyNodeId,
    this.responsibleParticipantIds = const {},
    this.sourceItemId,
  });

  final String participantId;
  final String cause;
  final int timelineMinute;
  final String storyNodeId;
  final Set<String> responsibleParticipantIds;
  final String? sourceItemId;

  Map<String, dynamic> toJson() => {
    'participantId': participantId,
    'cause': cause,
    'timelineMinute': timelineMinute,
    'storyNodeId': storyNodeId,
    'responsibleParticipantIds': responsibleParticipantIds.toList(),
    'sourceItemId': sourceItemId,
  };

  static ParticipantDeathRecord? fromJson(Map<String, dynamic> json) {
    final participantId = json['participantId'] as String?;
    final cause = json['cause'] as String?;
    final storyNodeId = json['storyNodeId'] as String?;
    if (participantId == null || cause == null || storyNodeId == null) {
      return null;
    }
    return ParticipantDeathRecord(
      participantId: participantId,
      cause: cause,
      timelineMinute: json['timelineMinute'] as int? ?? 0,
      storyNodeId: storyNodeId,
      responsibleParticipantIds:
          (json['responsibleParticipantIds'] as List<dynamic>? ?? [])
              .cast<String>()
              .toSet(),
      sourceItemId: json['sourceItemId'] as String?,
    );
  }
}

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
    required this.runMode,
    required this.highRiskItems,
    required this.livingParticipantIds,
    required this.deathRecords,
    this.markedSector,
    this.delegationPermission,
    this.delegationTrustee,
    this.delegationWitness,
    this.thumbnailBase64,
    this.thumbnailAsset,
    this.thumbnailText,
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
  final StoryRunMode runMode;
  final Map<String, HighRiskItemRecord> highRiskItems;
  final Set<String> livingParticipantIds;
  final List<ParticipantDeathRecord> deathRecords;
  final String? markedSector;
  final String? delegationPermission;
  final String? delegationTrustee;
  final String? delegationWitness;
  final String? thumbnailBase64;
  final String? thumbnailAsset;
  final String? thumbnailText;

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
    'runMode': runMode.name,
    'highRiskItems': highRiskItems.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'livingParticipantIds': livingParticipantIds.toList(),
    'deathRecords': deathRecords.map((record) => record.toJson()).toList(),
    'markedSector': markedSector,
    'delegationPermission': delegationPermission,
    'delegationTrustee': delegationTrustee,
    'delegationWitness': delegationWitness,
    'thumbnailBase64': thumbnailBase64,
    'thumbnailAsset': thumbnailAsset,
    'thumbnailText': thumbnailText,
  };

  static SaveSnapshot? fromJson(Map<String, dynamic> json) {
    final id = json['currentId'] as String?;
    if (id == null || !storyBeats.containsKey(id)) return null;
    final historyIds = (json['historyIds'] as List<dynamic>? ?? [])
        .cast<String>();
    final livingParticipantIds = json['livingParticipantIds'] == null
        ? Set<String>.of(initialLivingParticipantIds)
        : (json['livingParticipantIds'] as List<dynamic>)
              .cast<String>()
              .toSet();
    if (json['livingParticipantIds'] == null) {
      if (historyIds.contains('death_confirmed')) {
        livingParticipantIds.remove('05');
      }
      if (historyIds.contains('first_alarm')) livingParticipantIds.remove('10');
    }
    final highRiskItems = <String, HighRiskItemRecord>{
      for (final item in highRiskItemDefinitions)
        item.id: HighRiskItemRecord(
          id: item.id,
          state: HighRiskItemState.sealed,
        ),
    };
    final highRiskJson = json['highRiskItems'];
    if (highRiskJson is Map<String, dynamic>) {
      for (final value in highRiskJson.values) {
        if (value is! Map<String, dynamic>) continue;
        final record = HighRiskItemRecord.fromJson(value);
        if (record != null) highRiskItems[record.id] = record;
      }
    }
    final runModeName = json['runMode'] as String?;
    final runMode = StoryRunMode.values
        .where((value) => value.name == runModeName)
        .firstOrNull;
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
      historyIds: historyIds,
      runMode: runMode ?? StoryRunMode.standard,
      highRiskItems: highRiskItems,
      livingParticipantIds: livingParticipantIds,
      deathRecords: (json['deathRecords'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ParticipantDeathRecord.fromJson)
          .whereType<ParticipantDeathRecord>()
          .toList(),
      markedSector: json['markedSector'] as String?,
      delegationPermission: json['delegationPermission'] as String?,
      delegationTrustee: json['delegationTrustee'] as String?,
      delegationWitness: json['delegationWitness'] as String?,
      thumbnailBase64: json['thumbnailBase64'] as String?,
      thumbnailAsset: json['thumbnailAsset'] as String?,
      thumbnailText: json['thumbnailText'] as String?,
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
  Future<String?> Function()? _saveThumbnailCapture;
  String? _saveThumbnailAsset;
  String? _saveThumbnailText;

  StoryPhase phase = StoryPhase.title;
  String currentId = 'game_start';
  int xingyaoTrust = 0;
  int sumiTrust = 0;
  int linchengTrust = 0;
  int logic = 0;
  int cooperation = 0;
  double textSpeed = 0.65;
  double autoDelay = 1.8;
  double bgmVolume = 0.65;
  double ambienceVolume = 0.32;
  double sfxVolume = 0.78;
  bool reduceMotion = false;
  bool skipUnread = false;
  bool autoPlay = false;
  bool skipMode = false;
  bool hasAutoSave = false;
  bool auditModeUnlocked = false;
  StoryRunMode runMode = StoryRunMode.standard;
  String? markedSector;
  String? delegationPermission;
  String? delegationTrustee;
  String? delegationWitness;

  final Set<String> flags = {};
  final Set<String> foundClues = {};
  final Set<String> inventoryItems = {};
  final Set<String> investigationActions = {};
  final Set<String> investigationClues = {};
  final Set<String> seenNodes = {};
  final Set<String> readNodes = {};
  final Set<String> unlockedCgs = {};
  final Set<String> unlockedEndings = {};
  final Set<String> livingParticipantIds = Set.of(initialLivingParticipantIds);
  final Map<String, HighRiskItemRecord> highRiskItems = {
    for (final item in highRiskItemDefinitions)
      item.id: HighRiskItemRecord(id: item.id, state: HighRiskItemState.sealed),
  };
  final List<ParticipantDeathRecord> deathRecords = [];
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

  Iterable<HighRiskItemRecord> get visibleHighRiskItems => highRiskItems.values
      .where((record) => record.state != HighRiskItemState.sealed);

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

  void startNew({StoryRunMode mode = StoryRunMode.standard}) {
    runMode = mode == StoryRunMode.audit && auditModeUnlocked
        ? StoryRunMode.audit
        : StoryRunMode.standard;
    currentId = 'game_start';
    xingyaoTrust = 0;
    sumiTrust = 0;
    linchengTrust = 0;
    logic = 0;
    cooperation = 0;
    markedSector = null;
    delegationPermission = null;
    delegationTrustee = null;
    delegationWitness = null;
    flags.clear();
    foundClues.clear();
    inventoryItems.clear();
    investigationActions.clear();
    investigationClues.clear();
    livingParticipantIds
      ..clear()
      ..addAll(initialLivingParticipantIds);
    deathRecords.clear();
    _resetHighRiskItems();
    history.clear();
    _saveThumbnailAsset = null;
    _saveThumbnailText = null;
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

  void markCgViewed(String id) {
    if (cgById(id) == null || !unlockedCgs.add(id)) return;
    _saveCollections();
  }

  Future<void> saveToSlot(int index) async {
    if (index < 0 || index >= slotCount || phase == StoryPhase.title) return;
    String? thumbnailBase64;
    try {
      thumbnailBase64 = await _saveThumbnailCapture?.call();
    } catch (_) {
      thumbnailBase64 = null;
    }
    final snapshot = _createSnapshot(
      thumbnailBase64: thumbnailBase64,
      thumbnailAsset: _saveThumbnailAsset ?? sceneImageAsset(scene),
      thumbnailText:
          _saveThumbnailText ??
          (current.passages.isEmpty
              ? current.label
              : current.passages.first.text),
    );
    saveSlots[index] = snapshot;
    await _preferences.setString(
      '$_slotPrefix$index',
      jsonEncode(snapshot.toJson()),
    );
    notifyListeners();
  }

  void attachSaveThumbnailCapture(Future<String?> Function() capture) {
    _saveThumbnailCapture = capture;
  }

  void detachSaveThumbnailCapture() {
    _saveThumbnailCapture = null;
  }

  void setSaveThumbnailFallback({required String asset, required String text}) {
    _saveThumbnailAsset = asset;
    _saveThumbnailText = text;
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

  bool jumpToNode(String id) {
    final snapshot = checkpoints[id];
    if (snapshot == null || !seenNodes.contains(id)) return false;
    _restoreSnapshot(snapshot);
    autoPlay = false;
    skipMode = false;
    _saveAuto();
    notifyListeners();
    return true;
  }

  void advance() {
    if (phase != StoryPhase.dialogue || current.choices.isNotEmpty) return;
    final next = _resolvedNext(current);
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
    if (effect.highRiskItemId case final itemId?) {
      final holderId = effect.highRiskHolderId;
      if (holderId != null) _holdHighRiskItem(itemId, holderId);
    }

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

  void completeDelegation({
    required String permission,
    required String trustee,
    required String witness,
  }) {
    if (phase != StoryPhase.delegation) return;
    const permissions = {'read', 'door', 'clause', 'full'};
    const trustees = {'hanqi', 'tangyi', 'chenmo'};
    const witnesses = {'xingyao', 'sumi', 'yelan'};
    if (!permissions.contains(permission) ||
        !trustees.contains(trustee) ||
        !witnesses.contains(witness)) {
      return;
    }

    delegationPermission = permission;
    delegationTrustee = trustee;
    delegationWitness = witness;
    flags
      ..add('ch3_permission_$permission')
      ..add('ch3_trustee_$trustee')
      ..add('ch3_witness_$witness');
    if (permission == 'read') cooperation += 1;
    if (permission == 'door') logic += 1;
    if (permission == 'full') {
      logic += 1;
      cooperation -= 1;
    }

    _markCurrentRead();
    currentId = switch (trustee) {
      'hanqi' => 'ch3_delegate_hanqi',
      'tangyi' => 'ch3_delegate_tangyi',
      _ => 'ch3_delegate_chenmo',
    };
    _enterCurrent();
  }

  void collectInvestigationItem(String itemId) {
    if (!inventoryItems.add(itemId)) return;
    _saveAuto();
    notifyListeners();
  }

  void recordPuzzleProgress(
    String progressFlag, {
    String? grantsItem,
    Iterable<String> consumesItems = const [],
  }) {
    if (phase != StoryPhase.puzzle || !flags.add(progressFlag)) return;
    inventoryItems.removeAll(consumesItems);
    if (grantsItem != null) inventoryItems.add(grantsItem);
    _saveAuto();
    notifyListeners();
  }

  void completePuzzle(String solution) {
    if (phase != StoryPhase.puzzle) return;
    final valid = switch (currentId) {
      'ch3_transfer_access_puzzle' =>
        solution == 'access_0916' &&
            flags.contains('ch3_access_card_swiped') &&
            inventoryItems.contains('shift_note'),
      'ch3_balance_puzzle' => solution == 'triangle_cross_ring_dot_square',
      'ch3_slide_puzzle' => solution == 'circuit_complete',
      'ch3_audit_manifest_puzzle' =>
        solution == 'slot_lease_interval' &&
            runMode == StoryRunMode.audit &&
            flags.containsAll({
              'audit_index_fragment',
              'case01_solved',
              'case02_solved',
              'puzzle_ch3_slide_puzzle_solved',
            }),
      _ => false,
    };
    if (!valid || current.next == null) return;

    flags.add('puzzle_${current.id}_solved');
    logic += 1;
    _markCurrentRead();
    currentId = current.next!;
    _enterCurrent();
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
    if (currentId == 'ch6_case05_deduction') {
      if (hypothesis == 'delegation_branch_replay') {
        flags.add('case05_solved');
        logic += 2;
        currentId = 'ch6_case05_resolved';
      } else if (hypothesis == 'coordinated_ballots') {
        currentId = 'ch6_case05_coordination_error';
      } else {
        currentId = 'ch6_case05_location_error';
      }
      _enterCurrent();
      return;
    }
    if (currentId == 'ch5_case04_deduction') {
      if (hypothesis == 'maintenance_slot') {
        flags.add('case04_solved');
        logic += 2;
        currentId = 'ch5_case04_resolved';
      } else if (hypothesis == 'hidden_person') {
        currentId = 'ch5_case04_person_error';
      } else {
        currentId = 'ch5_case04_deleted_error';
      }
      _enterCurrent();
      return;
    }
    if (currentId == 'ch4_case03_deduction') {
      if (hypothesis == 'directed_resonance') {
        flags.add('case03_solved');
        logic += 2;
        currentId = 'ch4_case03_resolved';
      } else if (hypothesis == 'sedative_poisoning') {
        currentId = 'ch4_case03_sedative_error';
      } else {
        currentId = 'ch4_case03_contamination_error';
      }
      _enterCurrent();
      return;
    }
    if (currentId == 'ch3_case02_deduction') {
      if (hypothesis == 'lease_replay') {
        flags.add('case02_solved');
        logic += 2;
        currentId = 'ch3_case02_resolved';
      } else if (hypothesis == 'owner_action') {
        currentId = 'ch3_case02_owner_error';
      } else {
        currentId = 'ch3_case02_trustee_error';
      }
      _enterCurrent();
      return;
    }
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

  void setBgmVolume(double value) {
    bgmVolume = value.clamp(0.0, 1.0).toDouble();
    _saveSettings();
    notifyListeners();
  }

  void setAmbienceVolume(double value) {
    ambienceVolume = value.clamp(0.0, 1.0).toDouble();
    _saveSettings();
    notifyListeners();
  }

  void setSfxVolume(double value) {
    sfxVolume = value.clamp(0.0, 1.0).toDouble();
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

  void completeFullRunEnding(String endingId) {
    if (!fullRunEndingIds.contains(endingId)) return;
    unlockedEndings.add(endingId);
    auditModeUnlocked = true;
    _saveCollections();
    notifyListeners();
  }

  bool takeHighRiskItem(String id, String holderId) {
    final record = highRiskItems[id];
    if (record == null ||
        (record.state != HighRiskItemState.indexed &&
            record.state != HighRiskItemState.missing)) {
      return false;
    }
    _holdHighRiskItem(id, holderId);
    _saveAuto();
    notifyListeners();
    return true;
  }

  bool markHighRiskItemMissing(String id) {
    final record = highRiskItems[id];
    if (record == null || record.state == HighRiskItemState.used) return false;
    highRiskItems[id] = record.copyWith(
      state: HighRiskItemState.missing,
      clearHolder: true,
      updatedAtMinute: _elapsedMinutes,
    );
    _saveAuto();
    notifyListeners();
    return true;
  }

  bool resealHighRiskItem(String id) {
    final record = highRiskItems[id];
    if (record == null || record.state != HighRiskItemState.held) return false;
    highRiskItems[id] = record.copyWith(
      state: HighRiskItemState.indexed,
      clearHolder: true,
      updatedAtMinute: _elapsedMinutes,
    );
    _saveAuto();
    notifyListeners();
    return true;
  }

  bool useHighRiskItem(String id) {
    final record = highRiskItems[id];
    if (record == null || record.state != HighRiskItemState.held) return false;
    highRiskItems[id] = record.copyWith(
      state: HighRiskItemState.used,
      clearHolder: true,
      updatedAtMinute: _elapsedMinutes,
    );
    _saveAuto();
    notifyListeners();
    return true;
  }

  bool recordParticipantDeath({
    required String participantId,
    required String cause,
    Iterable<String> responsibleParticipantIds = const [],
    String? sourceItemId,
    int? timelineMinute,
    String? storyNodeId,
  }) {
    if (deathRecords.any((record) => record.participantId == participantId)) {
      return false;
    }
    livingParticipantIds.remove(participantId);
    deathRecords.add(
      ParticipantDeathRecord(
        participantId: participantId,
        cause: cause,
        timelineMinute: timelineMinute ?? _elapsedMinutes,
        storyNodeId: storyNodeId ?? currentId,
        responsibleParticipantIds: responsibleParticipantIds.toSet(),
        sourceItemId: sourceItemId,
      ),
    );
    if (sourceItemId != null) {
      final record = highRiskItems[sourceItemId];
      if (record != null && record.state != HighRiskItemState.used) {
        highRiskItems[sourceItemId] = record.copyWith(
          state: HighRiskItemState.used,
          clearHolder: true,
          updatedAtMinute: timelineMinute ?? _elapsedMinutes,
        );
      }
    }
    _saveAuto();
    notifyListeners();
    return true;
  }

  void _enterCurrent() {
    phase = current.phase;
    seenNodes.add(currentId);
    flags.addAll(current.flagsOnEnter);
    _indexHighRiskItems(current.highRiskItemsOnEnter);
    _markHighRiskItemsMissing(current.highRiskItemsMissingOnEnter);
    _resealHighRiskItems(current.highRiskItemsResealedOnEnter);
    for (final event in current.deathEvents) {
      _recordDeathEvent(event);
    }
    if (current.endingId case final ending?) {
      unlockedEndings.add(ending);
      if (fullRunEndingIds.contains(ending)) auditModeUnlocked = true;
    }
    _recordCurrent();
    final snapshot = _createSnapshot();
    checkpoints[currentId] = snapshot;
    hasAutoSave = true;
    _savePersistentProgress();
    _saveAuto();
    notifyListeners();
  }

  String? _resolvedNext(StoryBeat beat) {
    final auditNext = beat.auditNext;
    if (runMode == StoryRunMode.audit &&
        auditNext != null &&
        flags.containsAll(beat.auditRequiredFlags)) {
      return auditNext;
    }
    for (final entry in beat.nextByFlag.entries) {
      if (flags.contains(entry.key)) return entry.value;
    }
    return beat.next;
  }

  int get _elapsedMinutes {
    for (var index = history.length - 1; index >= 0; index--) {
      final anchor = history[index].timelineMinute;
      if (anchor != null) return anchor + (history.length - 1 - index) * 3;
    }
    return (history.length - 1).clamp(0, history.length) * 3;
  }

  void _resetHighRiskItems() {
    highRiskItems
      ..clear()
      ..addEntries(
        highRiskItemDefinitions.map(
          (item) => MapEntry(
            item.id,
            HighRiskItemRecord(id: item.id, state: HighRiskItemState.sealed),
          ),
        ),
      );
  }

  void _indexHighRiskItems(Iterable<String> ids) {
    for (final id in ids) {
      final record = highRiskItems[id];
      if (record == null || record.state != HighRiskItemState.sealed) continue;
      highRiskItems[id] = record.copyWith(
        state: HighRiskItemState.indexed,
        updatedAtMinute: _elapsedMinutes,
      );
    }
  }

  void _holdHighRiskItem(String id, String holderId) {
    final record = highRiskItems[id];
    if (record == null ||
        (record.state != HighRiskItemState.indexed &&
            record.state != HighRiskItemState.missing)) {
      return;
    }
    highRiskItems[id] = record.copyWith(
      state: HighRiskItemState.held,
      holderId: holderId,
      updatedAtMinute: _elapsedMinutes,
    );
  }

  void _markHighRiskItemsMissing(Iterable<String> ids) {
    for (final id in ids) {
      final record = highRiskItems[id];
      if (record == null || record.state == HighRiskItemState.used) continue;
      highRiskItems[id] = record.copyWith(
        state: HighRiskItemState.missing,
        clearHolder: true,
        updatedAtMinute: _elapsedMinutes,
      );
    }
  }

  void _resealHighRiskItems(Iterable<String> ids) {
    for (final id in ids) {
      final record = highRiskItems[id];
      if (record == null || record.state == HighRiskItemState.used) continue;
      highRiskItems[id] = record.copyWith(
        state: HighRiskItemState.indexed,
        clearHolder: true,
        updatedAtMinute: _elapsedMinutes,
      );
    }
  }

  void _recordDeathEvent(StoryDeathEvent event) {
    if (deathRecords.any(
      (record) => record.participantId == event.participantId,
    )) {
      return;
    }
    livingParticipantIds.remove(event.participantId);
    deathRecords.add(
      ParticipantDeathRecord(
        participantId: event.participantId,
        cause: event.cause,
        timelineMinute: event.timelineMinute,
        storyNodeId: currentId,
        responsibleParticipantIds: event.responsibleParticipantIds.toSet(),
        sourceItemId: event.sourceItemId,
      ),
    );
    if (event.sourceItemId case final sourceItemId?) {
      final record = highRiskItems[sourceItemId];
      if (record != null && record.state != HighRiskItemState.used) {
        highRiskItems[sourceItemId] = record.copyWith(
          state: HighRiskItemState.used,
          clearHolder: true,
          updatedAtMinute: event.timelineMinute,
        );
      }
    }
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

  SaveSnapshot _createSnapshot({
    String? thumbnailBase64,
    String? thumbnailAsset,
    String? thumbnailText,
  }) => SaveSnapshot(
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
    runMode: runMode,
    highRiskItems: Map.of(highRiskItems),
    livingParticipantIds: Set.of(livingParticipantIds),
    deathRecords: List.of(deathRecords),
    markedSector: markedSector,
    delegationPermission: delegationPermission,
    delegationTrustee: delegationTrustee,
    delegationWitness: delegationWitness,
    thumbnailBase64: thumbnailBase64,
    thumbnailAsset: thumbnailAsset,
    thumbnailText: thumbnailText,
  );

  void _restoreSnapshot(SaveSnapshot snapshot) {
    currentId = snapshot.currentId;
    runMode = snapshot.runMode;
    xingyaoTrust = snapshot.xingyaoTrust;
    sumiTrust = snapshot.sumiTrust;
    linchengTrust = snapshot.linchengTrust;
    logic = snapshot.logic;
    cooperation = snapshot.cooperation;
    markedSector = snapshot.markedSector;
    delegationPermission = snapshot.delegationPermission;
    delegationTrustee = snapshot.delegationTrustee;
    delegationWitness = snapshot.delegationWitness;
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
    highRiskItems
      ..clear()
      ..addAll(snapshot.highRiskItems);
    livingParticipantIds
      ..clear()
      ..addAll(snapshot.livingParticipantIds);
    deathRecords
      ..clear()
      ..addAll(snapshot.deathRecords);
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
        bgmVolume = ((settings['bgmVolume'] as num?)?.toDouble() ?? 0.65)
            .clamp(0.0, 1.0)
            .toDouble();
        ambienceVolume =
            ((settings['ambienceVolume'] as num?)?.toDouble() ?? 0.32)
                .clamp(0.0, 1.0)
                .toDouble();
        sfxVolume = ((settings['sfxVolume'] as num?)?.toDouble() ?? 0.78)
            .clamp(0.0, 1.0)
            .toDouble();
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
        auditModeUnlocked =
            data['auditModeUnlocked'] as bool? ??
            fullRunEndingIds.any(unlockedEndings.contains);
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
        'auditModeUnlocked': auditModeUnlocked,
      }),
    );
  }

  void _saveSettings() {
    _preferences.setString(
      _settingsKey,
      jsonEncode({
        'textSpeed': textSpeed,
        'autoDelay': autoDelay,
        'bgmVolume': bgmVolume,
        'ambienceVolume': ambienceVolume,
        'sfxVolume': sfxVolume,
        'reduceMotion': reduceMotion,
        'skipUnread': skipUnread,
      }),
    );
  }
}

import '../story/story.dart';

enum GameBgm {
  titleProtocol,
  awakeningRoom,
  assemblyDistrust,
  ruleExecution,
  aftermathVoid,
  investigationPulse,
  deductionChain,
  countdownCrisis,
  endingAfterlight,
}

extension GameBgmAsset on GameBgm {
  String get asset =>
      'audio/bgm/${switch (this) {
        GameBgm.titleProtocol => 'title_protocol',
        GameBgm.awakeningRoom => 'awakening_room',
        GameBgm.assemblyDistrust => 'assembly_distrust',
        GameBgm.ruleExecution => 'rule_execution',
        GameBgm.aftermathVoid => 'aftermath_void',
        GameBgm.investigationPulse => 'investigation_pulse',
        GameBgm.deductionChain => 'deduction_chain',
        GameBgm.countdownCrisis => 'countdown_crisis',
        GameBgm.endingAfterlight => 'ending_afterlight',
      }}.mp3';
}

enum GameAmbience { fluorescentHum, ventilation, corridorRoomtone }

extension GameAmbienceAsset on GameAmbience {
  String get asset =>
      'audio/sfx/${switch (this) {
        GameAmbience.fluorescentHum => 'amb_fluorescent_hum',
        GameAmbience.ventilation => 'amb_ventilation',
        GameAmbience.corridorRoomtone => 'amb_corridor_roomtone',
      }}.mp3';
}

enum GameSfx {
  uiConfirm,
  uiCancel,
  pdaOpen,
  pdaClose,
  saveComplete,
  loadComplete,
  choiceReveal,
  clueAcquired,
  combineSuccess,
  combineFail,
  terminalBoot,
  pdaNotification,
  administratorChannelOn,
  collarWarning,
  collarLock,
  collarDetonation,
  facilityAlarm,
  accessGranted,
  accessDenied,
  metalDoorOpen,
  metalDoorLock,
  wrenchImpact,
  bodyFall,
  shutterMotor,
  shutterJam,
  jackSlip,
  directedTone,
  itemPickup,
  keyUnlockBox,
  boxOpen,
  keypadPress,
  balanceWeight,
  stoneTileSlide,
  circuitPowerOn,
}

extension GameSfxAsset on GameSfx {
  String get id => switch (this) {
    GameSfx.uiConfirm => 'ui_confirm',
    GameSfx.uiCancel => 'ui_cancel',
    GameSfx.pdaOpen => 'pda_open',
    GameSfx.pdaClose => 'pda_close',
    GameSfx.saveComplete => 'save_complete',
    GameSfx.loadComplete => 'load_complete',
    GameSfx.choiceReveal => 'choice_reveal',
    GameSfx.clueAcquired => 'clue_acquired',
    GameSfx.combineSuccess => 'combine_success',
    GameSfx.combineFail => 'combine_fail',
    GameSfx.terminalBoot => 'terminal_boot',
    GameSfx.pdaNotification => 'pda_notification',
    GameSfx.administratorChannelOn => 'administrator_channel_on',
    GameSfx.collarWarning => 'collar_warning',
    GameSfx.collarLock => 'collar_lock',
    GameSfx.collarDetonation => 'collar_detonation',
    GameSfx.facilityAlarm => 'facility_alarm',
    GameSfx.accessGranted => 'access_granted',
    GameSfx.accessDenied => 'access_denied',
    GameSfx.metalDoorOpen => 'metal_door_open',
    GameSfx.metalDoorLock => 'metal_door_lock',
    GameSfx.wrenchImpact => 'wrench_impact',
    GameSfx.bodyFall => 'body_fall',
    GameSfx.shutterMotor => 'shutter_motor',
    GameSfx.shutterJam => 'shutter_jam',
    GameSfx.jackSlip => 'jack_slip',
    GameSfx.directedTone => 'directed_tone',
    GameSfx.itemPickup => 'item_pickup',
    GameSfx.keyUnlockBox => 'key_unlock_box',
    GameSfx.boxOpen => 'box_open',
    GameSfx.keypadPress => 'keypad_press',
    GameSfx.balanceWeight => 'balance_weight',
    GameSfx.stoneTileSlide => 'stone_tile_slide',
    GameSfx.circuitPowerOn => 'circuit_power_on',
  };

  String get asset => 'audio/sfx/$id.mp3';

  Duration? get maximumPlayback => switch (this) {
    GameSfx.choiceReveal => const Duration(milliseconds: 2200),
    GameSfx.terminalBoot => const Duration(seconds: 4),
    GameSfx.collarWarning => const Duration(seconds: 6),
    GameSfx.collarLock => const Duration(milliseconds: 1400),
    GameSfx.facilityAlarm => const Duration(seconds: 7),
    GameSfx.bodyFall => const Duration(milliseconds: 2200),
    GameSfx.shutterMotor => const Duration(seconds: 5),
    GameSfx.directedTone => const Duration(seconds: 3),
    GameSfx.balanceWeight => const Duration(milliseconds: 2200),
    GameSfx.circuitPowerOn => const Duration(seconds: 4),
    _ => null,
  };
}

class StoryAudioCue {
  const StoryAudioCue({required this.bgm, this.ambience});

  final GameBgm bgm;
  final GameAmbience? ambience;
}

StoryAudioCue resolveStoryAudioCue({
  required StoryPhase phase,
  required SceneKey scene,
  required String nodeId,
}) {
  if (phase == StoryPhase.title) {
    return const StoryAudioCue(bgm: GameBgm.titleProtocol);
  }

  final bgm = switch (phase) {
    StoryPhase.ending => GameBgm.endingAfterlight,
    StoryPhase.deduction => GameBgm.deductionChain,
    StoryPhase.investigation ||
    StoryPhase.puzzle ||
    StoryPhase.tuning => GameBgm.investigationPulse,
    _ => _dialogueBgm(nodeId, scene),
  };
  return StoryAudioCue(bgm: bgm, ambience: _ambienceFor(scene));
}

GameBgm _dialogueBgm(String nodeId, SceneKey scene) {
  if (_positiveEndingNodes.contains(nodeId)) return GameBgm.endingAfterlight;
  if (_ruleNodes.contains(nodeId)) return GameBgm.ruleExecution;
  if (_aftermathTokens.any(nodeId.contains)) return GameBgm.aftermathVoid;
  if (_crisisTokens.any(nodeId.contains)) return GameBgm.countdownCrisis;
  return switch (scene) {
    SceneKey.dormitory => GameBgm.awakeningRoom,
    SceneKey.assemblyHall => GameBgm.assemblyDistrust,
    SceneKey.controlRoom ||
    SceneKey.storageRoom ||
    SceneKey.transferRoom ||
    SceneKey.medicalIsolation ||
    SceneKey.securityRoom ||
    SceneKey.maintenanceRoom => GameBgm.investigationPulse,
    SceneKey.oldGym => GameBgm.countdownCrisis,
    SceneKey.corridor ||
    SceneKey.archiveCorridor ||
    SceneKey.infirmary => GameBgm.assemblyDistrust,
  };
}

GameAmbience _ambienceFor(SceneKey scene) => switch (scene) {
  SceneKey.corridor ||
  SceneKey.archiveCorridor ||
  SceneKey.securityRoom => GameAmbience.corridorRoomtone,
  SceneKey.oldGym ||
  SceneKey.storageRoom ||
  SceneKey.transferRoom ||
  SceneKey.maintenanceRoom => GameAmbience.ventilation,
  _ => GameAmbience.fluorescentHum,
};

const _positiveEndingNodes = {
  'pact_end',
  'xingyao_end',
  'sumi_end',
  'lincheng_end',
};

const _ruleNodes = {
  'screen_boot',
  'disbelief',
  'questions_overlap',
  'administrator_refusal',
  'wu_challenge',
  'sumi_blocks_wu',
  'final_warning',
  'crowd_intervention',
  'wu_defiance',
  'host_resumes',
  'rule_one',
  'distance_demo',
  'rule_two',
  'rule_three',
  'personal_clause',
};

const _aftermathTokens = {
  'collar_detonation',
  'explosion_silence',
  'death_confirmed',
  'after_death',
  'aftershock',
  'body_discovery',
  'bad_end',
  'shadow_end',
  'seal_silence',
};

const _crisisTokens = {
  'alarm',
  'countdown',
  'shutter',
  'rescue',
  'final_seconds',
  'rush_corridor',
  'seal_notice',
  'track_jam',
  'collapses',
  'stun',
  'door_trigger',
};

GameSfx? storyNodeSfx(String nodeId) => switch (nodeId) {
  'door_release' => GameSfx.metalDoorOpen,
  'screen_boot' => GameSfx.terminalBoot,
  'final_warning' => GameSfx.collarWarning,
  'collar_detonation' => GameSfx.collarDetonation,
  'host_resumes' => GameSfx.administratorChannelOn,
  'first_alarm' => GameSfx.facilityAlarm,
  'ch2_map_update' ||
  'ch3_update_chime' ||
  'ch4_high_risk_announcement' => GameSfx.pdaNotification,
  'ch2_shutter_drop' || 'ch2_release_start' => GameSfx.shutterMotor,
  'ch2_final_seconds' || 'ch4_seal_countdown' => GameSfx.collarWarning,
  'ch2_seal_complete' ||
  'ch3_second_seal' ||
  'ch4_audit_seal' ||
  'ch4_standard_seal_notice' => GameSfx.metalDoorLock,
  'ch3_b03_alarm' => GameSfx.facilityAlarm,
  'ch3_evacuation_track_jam' => GameSfx.shutterJam,
  'ch3_shutter_split' => GameSfx.shutterMotor,
  'ch4_tone_returns' ||
  'ch4_corridor_echo' ||
  'ch4_xingyao_collapses' => GameSfx.directedTone,
  'ch4_two_key_opening' => GameSfx.metalDoorOpen,
  'ch4_alliance_door_trigger' => GameSfx.metalDoorLock,
  'ch4_strong_death_confirmed' ||
  'ch4_alliance_death' ||
  'ch4_majority_death_rescue' ||
  'ch4_majority_death_delay' => GameSfx.collarDetonation,
  _ => null,
};

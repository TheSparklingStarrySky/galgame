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
  nightFacility,
  bondXingyao,
  bondSumi,
  bondLincheng,
  betrayalHunt,
  auditRevelation,
  rescueAction,
  controlCoreProtocol,
  synchronizedShutdown,
  fourSeatAftermath,
  finalTestimony,
}

extension GameBgmAsset on GameBgm {
  String get asset => switch (this) {
    GameBgm.titleProtocol => 'audio/bgm/title_protocol.mp3',
    GameBgm.awakeningRoom => 'audio/bgm/awakening_room.mp3',
    GameBgm.assemblyDistrust => 'audio/bgm/assembly_distrust.mp3',
    GameBgm.ruleExecution => 'audio/bgm/rule_execution.mp3',
    GameBgm.aftermathVoid => 'audio/bgm/aftermath_void.mp3',
    GameBgm.investigationPulse => 'audio/bgm/investigation_pulse.mp3',
    GameBgm.deductionChain => 'audio/bgm/deduction_chain.mp3',
    GameBgm.countdownCrisis => 'audio/bgm/countdown_crisis.mp3',
    GameBgm.endingAfterlight => 'audio/bgm/ending_afterlight.mp3',
    GameBgm.nightFacility => 'audio/bgm/night_facility.m4a',
    GameBgm.bondXingyao => 'audio/bgm/bond_xingyao.m4a',
    GameBgm.bondSumi => 'audio/bgm/bond_sumi.m4a',
    GameBgm.bondLincheng => 'audio/bgm/bond_lincheng.m4a',
    GameBgm.betrayalHunt => 'audio/bgm/betrayal_hunt.m4a',
    GameBgm.auditRevelation => 'audio/bgm/audit_revelation.m4a',
    GameBgm.rescueAction => 'audio/bgm/rescue_action.m4a',
    GameBgm.controlCoreProtocol => 'audio/bgm/control_core_protocol.m4a',
    GameBgm.synchronizedShutdown => 'audio/bgm/synchronized_shutdown.m4a',
    GameBgm.fourSeatAftermath => 'audio/bgm/four_seat_aftermath.m4a',
    GameBgm.finalTestimony => 'audio/bgm/final_testimony.m4a',
  };

  bool get loop => this != GameBgm.endingAfterlight;
}

enum GameAmbience {
  fluorescentHum,
  ventilation,
  corridorRoomtone,
  assemblyPa,
  infirmaryEquipment,
  storageRefrigeration,
  urbanExterior,
  riversideEvening,
}

extension GameAmbienceAsset on GameAmbience {
  String get asset =>
      'audio/sfx/${switch (this) {
        GameAmbience.fluorescentHum => 'amb_fluorescent_hum',
        GameAmbience.ventilation => 'amb_ventilation',
        GameAmbience.corridorRoomtone => 'amb_corridor_roomtone',
        GameAmbience.assemblyPa => 'amb_assembly_pa',
        GameAmbience.infirmaryEquipment => 'amb_infirmary_equipment',
        GameAmbience.storageRefrigeration => 'amb_storage_refrigeration',
        GameAmbience.urbanExterior => 'amb_urban_exterior',
        GameAmbience.riversideEvening => 'amb_riverside_evening',
      }}.${switch (this) {
        GameAmbience.assemblyPa || GameAmbience.infirmaryEquipment || GameAmbience.storageRefrigeration || GameAmbience.urbanExterior || GameAmbience.riversideEvening => 'm4a',
        _ => 'mp3',
      }}';
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
  routeJump,
  administratorChannelOff,
  surveillanceServo,
  footstepsConcrete,
  ropeTension,
  medicalMonitor,
  uvLamp,
  measuringTape,
  archivePage,
  microfilmScanner,
  archiveShelfMotor,
  archiveShelfImpact,
  acidSplash,
  emergencyShower,
  gasRelease,
  archiveSeal,
  checksumVerified,
  pneumaticNailer,
  electricalArc,
  pressureBypass,
  evidenceGlassBreak,
  syncLockPulse,
  testimonySubmit,
  collarRelease,
  rescueWallBreach,
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
    GameSfx.routeJump => 'route_jump',
    GameSfx.administratorChannelOff => 'administrator_channel_off',
    GameSfx.surveillanceServo => 'surveillance_servo',
    GameSfx.footstepsConcrete => 'footsteps_concrete',
    GameSfx.ropeTension => 'rope_tension',
    GameSfx.medicalMonitor => 'medical_monitor',
    GameSfx.uvLamp => 'uv_lamp',
    GameSfx.measuringTape => 'measuring_tape',
    GameSfx.archivePage => 'archive_page',
    GameSfx.microfilmScanner => 'microfilm_scanner',
    GameSfx.archiveShelfMotor => 'archive_shelf_motor',
    GameSfx.archiveShelfImpact => 'archive_shelf_impact',
    GameSfx.acidSplash => 'acid_splash',
    GameSfx.emergencyShower => 'emergency_shower',
    GameSfx.gasRelease => 'gas_release',
    GameSfx.archiveSeal => 'archive_seal',
    GameSfx.checksumVerified => 'checksum_verified',
    GameSfx.pneumaticNailer => 'pneumatic_nailer',
    GameSfx.electricalArc => 'electrical_arc',
    GameSfx.pressureBypass => 'pressure_bypass',
    GameSfx.evidenceGlassBreak => 'evidence_glass_break',
    GameSfx.syncLockPulse => 'sync_lock_pulse',
    GameSfx.testimonySubmit => 'testimony_submit',
    GameSfx.collarRelease => 'collar_release',
    GameSfx.rescueWallBreach => 'rescue_wall_breach',
  };

  String get asset =>
      'audio/sfx/$id.${_originalSfx.contains(this) ? 'm4a' : 'mp3'}';

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
    GameSfx.archiveShelfMotor => const Duration(seconds: 5),
    GameSfx.archiveShelfImpact => const Duration(milliseconds: 2400),
    GameSfx.emergencyShower => const Duration(milliseconds: 5200),
    GameSfx.gasRelease => const Duration(milliseconds: 6200),
    GameSfx.archiveSeal => const Duration(seconds: 6),
    GameSfx.electricalArc => const Duration(milliseconds: 2200),
    GameSfx.pressureBypass => const Duration(milliseconds: 4800),
    GameSfx.syncLockPulse => const Duration(milliseconds: 2400),
    GameSfx.testimonySubmit => const Duration(milliseconds: 2200),
    GameSfx.collarRelease => const Duration(milliseconds: 3200),
    GameSfx.rescueWallBreach => const Duration(milliseconds: 5200),
    _ => null,
  };
}

const _originalSfx = {
  GameSfx.routeJump,
  GameSfx.administratorChannelOff,
  GameSfx.surveillanceServo,
  GameSfx.footstepsConcrete,
  GameSfx.ropeTension,
  GameSfx.medicalMonitor,
  GameSfx.uvLamp,
  GameSfx.measuringTape,
  GameSfx.archivePage,
  GameSfx.microfilmScanner,
  GameSfx.archiveShelfMotor,
  GameSfx.archiveShelfImpact,
  GameSfx.acidSplash,
  GameSfx.emergencyShower,
  GameSfx.gasRelease,
  GameSfx.archiveSeal,
  GameSfx.checksumVerified,
  GameSfx.pneumaticNailer,
  GameSfx.electricalArc,
  GameSfx.pressureBypass,
  GameSfx.evidenceGlassBreak,
  GameSfx.syncLockPulse,
  GameSfx.testimonySubmit,
  GameSfx.collarRelease,
  GameSfx.rescueWallBreach,
};

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
    StoryPhase.deduction =>
      nodeId.startsWith('ch7_case06')
          ? GameBgm.controlCoreProtocol
          : GameBgm.deductionChain,
    StoryPhase.investigation || StoryPhase.tuning =>
      nodeId.startsWith('ch7_core_')
          ? GameBgm.controlCoreProtocol
          : GameBgm.investigationPulse,
    StoryPhase.puzzle =>
      nodeId == 'ch7_sync_puzzle'
          ? GameBgm.synchronizedShutdown
          : GameBgm.investigationPulse,
    StoryPhase.testimony => GameBgm.finalTestimony,
    _ => _dialogueBgm(nodeId, scene),
  };
  return StoryAudioCue(bgm: bgm, ambience: _ambienceFor(scene));
}

GameBgm _dialogueBgm(String nodeId, SceneKey scene) {
  if (_positiveEndingNodes.contains(nodeId)) return GameBgm.endingAfterlight;
  if (nodeId.startsWith('ch8_audit_director_reveal_')) {
    return GameBgm.auditRevelation;
  }
  if (nodeId.startsWith('ch8_xingyao_epilogue_') ||
      nodeId == 'ch8_xingyao_signal_trigger') {
    return GameBgm.bondXingyao;
  }
  if (nodeId.startsWith('ch8_sumi_epilogue_') ||
      nodeId == 'ch8_sumi_leave_of_absence') {
    return GameBgm.bondSumi;
  }
  if (nodeId.startsWith('ch8_lincheng_epilogue_') ||
      nodeId == 'ch8_lincheng_exam_day') {
    return GameBgm.bondLincheng;
  }
  if (nodeId.startsWith('ch8_public_epilogue_') ||
      nodeId == 'ch8_public_ordinary_lives' ||
      nodeId.startsWith('ch8_audit_debrief_') ||
      nodeId.startsWith('ch8_audit_exit_') ||
      nodeId.startsWith('ch8_audit_unlock_')) {
    return GameBgm.endingAfterlight;
  }
  if (nodeId.startsWith('ch8_four_seats_') ||
      nodeId.startsWith('ch8_custodian_') ||
      nodeId.startsWith('ch8_no_witness_') ||
      nodeId.startsWith('ch8_standard_')) {
    return GameBgm.fourSeatAftermath;
  }
  if (nodeId.startsWith('ch8_')) return GameBgm.finalTestimony;
  if (_xingyaoBondNodes.contains(nodeId)) return GameBgm.bondXingyao;
  if (_sumiBondNodes.contains(nodeId)) return GameBgm.bondSumi;
  if (_linchengBondNodes.contains(nodeId)) return GameBgm.bondLincheng;
  if (_fourSeatAftermathTokens.any(nodeId.contains)) {
    return GameBgm.fourSeatAftermath;
  }
  if (_shutdownTokens.any(nodeId.contains)) {
    return GameBgm.synchronizedShutdown;
  }
  if (_controlCoreTokens.any(nodeId.contains)) {
    return GameBgm.controlCoreProtocol;
  }
  if (_rescueNodes.contains(nodeId)) return GameBgm.rescueAction;
  if (_betrayalTokens.any(nodeId.contains)) return GameBgm.betrayalHunt;
  if (_auditTokens.any(nodeId.contains)) return GameBgm.auditRevelation;
  if (_ruleNodes.contains(nodeId)) return GameBgm.ruleExecution;
  if (_aftermathTokens.any(nodeId.contains)) return GameBgm.aftermathVoid;
  if (_crisisTokens.any(nodeId.contains)) return GameBgm.countdownCrisis;
  if (nodeId.startsWith('ch7_')) return GameBgm.nightFacility;
  if (nodeId.startsWith('ch6_')) return GameBgm.nightFacility;
  if (nodeId.startsWith('ch5_')) return GameBgm.nightFacility;
  return switch (scene) {
    SceneKey.dormitory => GameBgm.awakeningRoom,
    SceneKey.assemblyHall => GameBgm.assemblyDistrust,
    SceneKey.controlRoom ||
    SceneKey.storageRoom ||
    SceneKey.transferRoom ||
    SceneKey.archiveRoom ||
    SceneKey.medicalIsolation ||
    SceneKey.securityRoom ||
    SceneKey.maintenanceRoom ||
    SceneKey.controlCore ||
    SceneKey.northRelay ||
    SceneKey.evidencePort ||
    SceneKey.medicalAirlock => GameBgm.investigationPulse,
    SceneKey.testimonyHall ||
    SceneKey.testimonyBooth => GameBgm.auditRevelation,
    SceneKey.debriefRoom ||
    SceneKey.hearingRoom ||
    SceneKey.memorialWall ||
    SceneKey.broadcastTower ||
    SceneKey.schoolClassroom ||
    SceneKey.metroStation ||
    SceneKey.riversideEvening => GameBgm.endingAfterlight,
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
  SceneKey.transferRoom ||
  SceneKey.archiveRoom ||
  SceneKey.maintenanceRoom ||
  SceneKey.controlCore ||
  SceneKey.northRelay ||
  SceneKey.evidencePort => GameAmbience.ventilation,
  SceneKey.storageRoom => GameAmbience.storageRefrigeration,
  SceneKey.infirmary ||
  SceneKey.medicalIsolation ||
  SceneKey.medicalAirlock => GameAmbience.infirmaryEquipment,
  SceneKey.testimonyHall || SceneKey.testimonyBooth => GameAmbience.ventilation,
  SceneKey.debriefRoom => GameAmbience.infirmaryEquipment,
  SceneKey.memorialWall ||
  SceneKey.broadcastTower => GameAmbience.urbanExterior,
  SceneKey.riversideEvening => GameAmbience.riversideEvening,
  SceneKey.metroStation => GameAmbience.corridorRoomtone,
  SceneKey.assemblyHall => GameAmbience.assemblyPa,
  _ => GameAmbience.fluorescentHum,
};

const _xingyaoBondNodes = {
  'ch5_xingyao_bond',
  'ch5_xingyao_answer',
  'ch5_xingyao_near',
};

const _sumiBondNodes = {'ch5_sumi_bond', 'ch5_sumi_answer', 'ch5_sumi_near'};

const _linchengBondNodes = {
  'ch5_lincheng_bond',
  'ch5_lincheng_answer',
  'ch5_lincheng_near',
};

const _rescueNodes = {
  'ch2_release_start',
  'ch2_rescue_roles',
  'ch2_final_seconds',
  'ch2_rescue_complete',
};

const _betrayalTokens = {
  'ch5_hanqi_revenge',
  'ch5_alliance_silence',
  'ch5_alliance_acid',
  'ch5_alliance_chenmo',
  'ch5_alliance_yelan',
  'ch5_alliance_locked',
  'ch5_majority_silence',
  'ch5_majority_server',
  'ch5_majority_cooling',
  'ch5_majority_chenmo',
  'ch6_revenge_',
  'ch6_silence_',
  'ch6_force_',
  'ch7_tangyi_hunt_',
  'ch7_chenmo_hunt_',
  'ch7_hanqi_hunt_',
  'ch7_lincheng_death_',
  'ch7_xingyao_death_',
  'ch7_sumi_death_',
};

const _auditTokens = {
  'ch5_case04',
  'ch5_archive_first_view',
  'ch5_investigation_debrief',
  'ch5_roster_fact',
  'ch5_photo_fact',
  'ch5_access_fact',
  'ch5_server_fact',
  'ch5_audit_',
  'ch5_zero_archive',
  'ch6_case05',
  'ch6_investigation',
  'ch6_ballot_fact',
  'ch6_delegation_fact',
  'ch6_location_fact',
  'ch6_weapon_fact',
  'ch6_audit_',
  'ch7_core_',
  'ch7_ledger_fact',
  'ch7_topology_fact',
  'ch7_input_bus_fact',
  'ch7_weapon_fact',
  'ch7_case06',
  'ch7_audit_',
  'ch7_sync_',
};

const _controlCoreTokens = {
  'ch7_core_',
  'ch7_ledger_fact',
  'ch7_topology_fact',
  'ch7_input_bus_fact',
  'ch7_weapon_fact',
  'ch7_case06',
  'ch7_responsibility_after_',
};

const _shutdownTokens = {
  'ch7_sync_',
  'ch7_audit_sync_',
  'ch7_audit_maintenance_',
  'ch7_audit_archive_',
  'ch7_audit_north_',
  'ch7_audit_window_',
  'ch7_audit_shutdown_',
};

const _fourSeatAftermathTokens = {
  'ch7_standard_four_',
  'ch7_four_',
  'ch7_standard_relationship_',
  'ch7_standard_xingyao_',
  'ch7_standard_sumi_',
  'ch7_standard_lincheng_',
  'ch7_standard_public_',
  'ch7_standard_end',
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
  'ch5_unlock_bell' || 'ch5_door_override_notice' => GameSfx.pdaNotification,
  'ch5_archive_first_view' => GameSfx.metalDoorOpen,
  'ch5_archive_smell' => GameSfx.archivePage,
  'ch5_archive_investigation' => GameSfx.microfilmScanner,
  'ch5_case04_resolved' ||
  'ch5_audit_slot12_challenge' => GameSfx.checksumVerified,
  'ch5_hanqi_override_reveal' => GameSfx.archiveShelfMotor,
  'ch5_hanqi_revenge_death' => GameSfx.archiveShelfImpact,
  'ch5_alliance_yelan_intervenes' => GameSfx.acidSplash,
  'ch5_alliance_locked_shower' => GameSfx.emergencyShower,
  'ch5_alliance_silence_death' => GameSfx.bodyFall,
  'ch5_majority_cooling_alarm' => GameSfx.facilityAlarm,
  'ch5_majority_silence_death' => GameSfx.gasRelease,
  'ch5_e04_sealed' => GameSfx.archiveSeal,
  'ch6_vote_opening' || 'ch6_duplicate_ballot' => GameSfx.pdaNotification,
  'ch6_vote_investigation' => GameSfx.archivePage,
  'ch6_case05_resolved' => GameSfx.checksumVerified,
  'ch6_revenge_death' ||
  'ch6_silence_death' ||
  'ch6_force_death' => GameSfx.bodyFall,
  'ch6_audit_attempt' => GameSfx.accessGranted,
  'ch6_audit_seal' => GameSfx.metalDoorLock,
  'ch7_core_entry' => GameSfx.metalDoorOpen,
  'ch7_core_investigation' => GameSfx.microfilmScanner,
  'ch7_case06_resolved' => GameSfx.checksumVerified,
  'ch7_responsibility_after_3' => GameSfx.facilityAlarm,
  'ch7_tangyi_hunt_7' => GameSfx.pneumaticNailer,
  'ch7_chenmo_hunt_8' => GameSfx.electricalArc,
  'ch7_hanqi_hunt_6' => GameSfx.evidenceGlassBreak,
  'ch7_hanqi_hunt_7' => GameSfx.bodyFall,
  'ch7_sumi_risk_1' => GameSfx.pressureBypass,
  'ch7_lincheng_death_tangyi' ||
  'ch7_lincheng_death_chenmo' ||
  'ch7_lincheng_death_hanqi' => GameSfx.metalDoorLock,
  'ch7_xingyao_death_tangyi' ||
  'ch7_xingyao_death_chenmo' ||
  'ch7_xingyao_death_hanqi' => GameSfx.directedTone,
  'ch7_sumi_death_tangyi' ||
  'ch7_sumi_death_chenmo' ||
  'ch7_sumi_death_hanqi' => GameSfx.gasRelease,
  'ch7_audit_sync_1' => GameSfx.syncLockPulse,
  'ch7_audit_shutdown_1' => GameSfx.administratorChannelOff,
  'ch8_audit_testimony_resolved' => GameSfx.testimonySubmit,
  'ch8_audit_director_reveal_1' => GameSfx.checksumVerified,
  'ch8_four_seats_verdict_1' => GameSfx.testimonySubmit,
  'ch8_custodian_verdict_1' => GameSfx.testimonySubmit,
  'ch8_no_witness_verdict_1' => GameSfx.testimonySubmit,
  'ch8_audit_unlock_1' => GameSfx.collarRelease,
  'ch8_custodian_debrief_1' => GameSfx.collarRelease,
  'ch8_no_witness_rescue_1' => GameSfx.rescueWallBreach,
  'ch8_four_seats_exit_1' => GameSfx.collarRelease,
  _ => null,
};

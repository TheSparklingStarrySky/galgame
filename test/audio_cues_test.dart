import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galgame/audio/audio_cues.dart';
import 'package:galgame/audio/game_audio_controller.dart';
import 'package:galgame/story/story.dart';
import 'package:galgame/story/story_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('剧情阶段与关键节点解析到稳定的音乐主题', () {
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.title,
        scene: SceneKey.dormitory,
        nodeId: 'game_start',
      ).bgm,
      GameBgm.titleProtocol,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.dialogue,
        scene: SceneKey.assemblyHall,
        nodeId: 'rule_one',
      ).bgm,
      GameBgm.ruleExecution,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.dialogue,
        scene: SceneKey.assemblyHall,
        nodeId: 'collar_detonation',
      ).bgm,
      GameBgm.aftermathVoid,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.deduction,
        scene: SceneKey.controlRoom,
        nodeId: 'deduction_gate',
      ).bgm,
      GameBgm.deductionChain,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.investigation,
        scene: SceneKey.oldGym,
        nodeId: 'ch2_gym_investigation',
      ).bgm,
      GameBgm.investigationPulse,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.dialogue,
        scene: SceneKey.archiveRoom,
        nodeId: 'ch5_xingyao_near',
      ).bgm,
      GameBgm.bondXingyao,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.dialogue,
        scene: SceneKey.archiveRoom,
        nodeId: 'ch5_alliance_yelan_intervenes',
      ).bgm,
      GameBgm.betrayalHunt,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.dialogue,
        scene: SceneKey.archiveRoom,
        nodeId: 'ch5_audit_find_override',
      ).bgm,
      GameBgm.auditRevelation,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.deduction,
        scene: SceneKey.controlCore,
        nodeId: 'ch7_case06_deduction',
      ).bgm,
      GameBgm.controlCoreProtocol,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.puzzle,
        scene: SceneKey.controlCore,
        nodeId: 'ch7_sync_puzzle',
      ).bgm,
      GameBgm.synchronizedShutdown,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.dialogue,
        scene: SceneKey.controlCore,
        nodeId: 'ch7_standard_four_1',
      ).bgm,
      GameBgm.fourSeatAftermath,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.testimony,
        scene: SceneKey.testimonyBooth,
        nodeId: 'ch8_audit_testimony',
      ).bgm,
      GameBgm.finalTestimony,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.dialogue,
        scene: SceneKey.debriefRoom,
        nodeId: 'ch8_xingyao_epilogue_4',
      ).bgm,
      GameBgm.bondXingyao,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.dialogue,
        scene: SceneKey.assemblyHall,
        nodeId: 'ch8_audit_director_reveal_1',
      ).bgm,
      GameBgm.auditRevelation,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.dialogue,
        scene: SceneKey.metroStation,
        nodeId: 'ch8_xingyao_signal_trigger',
      ).bgm,
      GameBgm.bondXingyao,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.dialogue,
        scene: SceneKey.schoolClassroom,
        nodeId: 'ch8_lincheng_exam_day',
      ).bgm,
      GameBgm.bondLincheng,
    );
  });

  test('室内区域使用对应环境底噪', () {
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.dialogue,
        scene: SceneKey.corridor,
        nodeId: 'corridor_encounter',
      ).ambience,
      GameAmbience.corridorRoomtone,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.dialogue,
        scene: SceneKey.storageRoom,
        nodeId: 'supply_room',
      ).ambience,
      GameAmbience.storageRefrigeration,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.dialogue,
        scene: SceneKey.infirmary,
        nodeId: 'sumi_infirmary',
      ).ambience,
      GameAmbience.infirmaryEquipment,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.dialogue,
        scene: SceneKey.memorialWall,
        nodeId: 'ch8_public_epilogue_3',
      ).ambience,
      GameAmbience.urbanExterior,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.dialogue,
        scene: SceneKey.riversideEvening,
        nodeId: 'ch8_lincheng_epilogue_5',
      ).ambience,
      GameAmbience.riversideEvening,
    );
  });

  test('关键事件绑定对应一次性音效', () {
    expect(storyNodeSfx('screen_boot'), GameSfx.terminalBoot);
    expect(storyNodeSfx('collar_detonation'), GameSfx.collarDetonation);
    expect(storyNodeSfx('ch2_shutter_drop'), GameSfx.shutterMotor);
    expect(storyNodeSfx('ch3_b03_alarm'), GameSfx.facilityAlarm);
    expect(storyNodeSfx('ch4_tone_returns'), GameSfx.directedTone);
    expect(
      storyNodeSfx('ch5_hanqi_override_reveal'),
      GameSfx.archiveShelfMotor,
    );
    expect(storyNodeSfx('ch5_alliance_yelan_intervenes'), GameSfx.acidSplash);
    expect(storyNodeSfx('ch5_majority_silence_death'), GameSfx.gasRelease);
    expect(storyNodeSfx('ch5_e04_sealed'), GameSfx.archiveSeal);
    expect(storyNodeSfx('ch7_tangyi_hunt_7'), GameSfx.pneumaticNailer);
    expect(storyNodeSfx('ch7_chenmo_hunt_8'), GameSfx.electricalArc);
    expect(storyNodeSfx('ch7_hanqi_hunt_6'), GameSfx.evidenceGlassBreak);
    expect(storyNodeSfx('ch7_sumi_risk_1'), GameSfx.pressureBypass);
    expect(storyNodeSfx('ch7_audit_sync_1'), GameSfx.syncLockPulse);
    expect(
      storyNodeSfx('ch8_audit_testimony_resolved'),
      GameSfx.testimonySubmit,
    );
    expect(
      storyNodeSfx('ch8_audit_director_reveal_1'),
      GameSfx.checksumVerified,
    );
    expect(storyNodeSfx('ch8_audit_unlock_1'), GameSfx.collarRelease);
    expect(storyNodeSfx('ch8_custodian_debrief_1'), GameSfx.collarRelease);
    expect(storyNodeSfx('ch8_no_witness_rescue_1'), GameSfx.rescueWallBreach);
  });

  test('运行时音频枚举均指向实际资源', () {
    for (final bgm in GameBgm.values) {
      expect(
        File('assets/${bgm.asset}').existsSync(),
        isTrue,
        reason: bgm.name,
      );
    }
    for (final ambience in GameAmbience.values) {
      expect(
        File('assets/${ambience.asset}').existsSync(),
        isTrue,
        reason: ambience.name,
      );
    }
    for (final sfx in GameSfx.values) {
      expect(
        File('assets/${sfx.asset}').existsSync(),
        isTrue,
        reason: sfx.name,
      );
    }
    expect(GameBgm.endingAfterlight.loop, isFalse);
    expect(GameBgm.auditRevelation.loop, isTrue);
  });

  test('音效与环境音不会抢占正在播放的 BGM', () {
    expect(
      GameAudioController.bgmAudioContext.android.audioFocus,
      AndroidAudioFocus.gain,
    );
    expect(
      GameAudioController.layeredAudioContext.android.audioFocus,
      AndroidAudioFocus.none,
    );
    expect(
      GameAudioController.layeredAudioContext.iOS.category,
      AVAudioSessionCategory.playback,
    );
  });

  test('音量设置会限制范围并持久化', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = await StoryController.load();
    controller
      ..setBgmVolume(1.4)
      ..setAmbienceVolume(-0.2)
      ..setSfxVolume(0.42);

    final restored = await StoryController.load();
    expect(restored.bgmVolume, 1);
    expect(restored.ambienceVolume, 0);
    expect(restored.sfxVolume, 0.42);
  });
}

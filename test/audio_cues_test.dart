import 'package:flutter_test/flutter_test.dart';
import 'package:galgame/audio/audio_cues.dart';
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
      GameAmbience.ventilation,
    );
    expect(
      resolveStoryAudioCue(
        phase: StoryPhase.dialogue,
        scene: SceneKey.infirmary,
        nodeId: 'sumi_infirmary',
      ).ambience,
      GameAmbience.fluorescentHum,
    );
  });

  test('关键事件绑定对应一次性音效', () {
    expect(storyNodeSfx('screen_boot'), GameSfx.terminalBoot);
    expect(storyNodeSfx('collar_detonation'), GameSfx.collarDetonation);
    expect(storyNodeSfx('ch2_shutter_drop'), GameSfx.shutterMotor);
    expect(storyNodeSfx('ch3_b03_alarm'), GameSfx.facilityAlarm);
    expect(storyNodeSfx('ch4_tone_returns'), GameSfx.directedTone);
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

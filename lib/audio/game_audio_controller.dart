import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../story/story_controller.dart';
import 'audio_cues.dart';

class GameAudioController {
  GameAudioController({bool enabled = true})
    : _enabled = enabled,
      _bgmPlayer = enabled ? AudioPlayer() : null,
      _ambiencePlayer = enabled ? AudioPlayer() : null,
      _sfxPlayers = enabled
          ? List.generate(4, (_) => AudioPlayer(), growable: false)
          : const [] {
    _armed = enabled && !kIsWeb;
  }

  final bool _enabled;
  final AudioPlayer? _bgmPlayer;
  final AudioPlayer? _ambiencePlayer;
  final List<AudioPlayer> _sfxPlayers;
  final List<Timer?> _sfxStopTimers = List<Timer?>.filled(4, null);

  StoryAudioCue? _desiredCue;
  GameBgm? _requestedBgm;
  GameBgm? _currentBgm;
  GameAmbience? _requestedAmbience;
  GameAmbience? _currentAmbience;
  String? _lastNodeId;
  int _nextSfxPlayer = 0;
  double _bgmVolume = 0.65;
  double _ambienceVolume = 0.32;
  double _sfxVolume = 0.78;
  bool _armed = false;
  bool _suspended = false;
  bool _disposed = false;
  bool _switchingBgm = false;
  bool _switchingAmbience = false;

  void sync(StoryController controller) {
    if (!_enabled || _disposed) return;
    _updateVolumes(controller);
    final cue = resolveStoryAudioCue(
      phase: controller.phase,
      scene: controller.scene,
      nodeId: controller.currentId,
    );
    _desiredCue = cue;

    final previousNode = _lastNodeId;
    _lastNodeId = controller.currentId;
    if (_armed &&
        !_suspended &&
        previousNode != null &&
        previousNode != controller.currentId) {
      final sfx = storyNodeSfx(controller.currentId);
      if (sfx != null) playSfx(sfx);
    }

    if (!_armed || _suspended) return;
    _requestBgm(cue.bgm);
    _requestAmbience(cue.ambience);
  }

  void handleUserGesture() {
    if (!_enabled || _disposed || _armed) return;
    _armed = true;
    final cue = _desiredCue;
    if (cue == null || _suspended) return;
    _requestBgm(cue.bgm);
    _requestAmbience(cue.ambience);
  }

  void suspend() {
    if (!_enabled || _disposed || _suspended) return;
    _suspended = true;
    unawaited(
      _guard(() async {
        await Future.wait([
          if (_bgmPlayer != null) _bgmPlayer.pause(),
          if (_ambiencePlayer != null) _ambiencePlayer.pause(),
        ]);
      }),
    );
  }

  void resume() {
    if (!_enabled || _disposed || !_suspended) return;
    _suspended = false;
    final cue = _desiredCue;
    if (!_armed || cue == null) return;
    unawaited(_resumeLoops(cue));
  }

  void playSfx(GameSfx sfx) {
    if (!_enabled || _disposed || !_armed || _suspended) return;
    final slot = _nextSfxPlayer;
    _nextSfxPlayer = (_nextSfxPlayer + 1) % _sfxPlayers.length;
    final player = _sfxPlayers[slot];
    _sfxStopTimers[slot]?.cancel();
    unawaited(
      _guard(() async {
        await player.stop();
        await player.setReleaseMode(ReleaseMode.stop);
        await player.play(AssetSource(sfx.asset), volume: _sfxVolume);
        if (sfx.maximumPlayback case final duration?) {
          _sfxStopTimers[slot] = Timer(duration, () {
            if (!_disposed) unawaited(_guard(player.stop));
          });
        }
      }),
    );
  }

  void _updateVolumes(StoryController controller) {
    final bgmChanged = _bgmVolume != controller.bgmVolume;
    final ambienceChanged = _ambienceVolume != controller.ambienceVolume;
    final sfxChanged = _sfxVolume != controller.sfxVolume;
    _bgmVolume = controller.bgmVolume;
    _ambienceVolume = controller.ambienceVolume;
    _sfxVolume = controller.sfxVolume;
    if (bgmChanged && _currentBgm != null) {
      unawaited(_guard(() => _bgmPlayer!.setVolume(_bgmVolume)));
    }
    if (ambienceChanged && _currentAmbience != null) {
      unawaited(_guard(() => _ambiencePlayer!.setVolume(_ambienceVolume)));
    }
    if (sfxChanged) {
      for (final player in _sfxPlayers) {
        if (player.state == PlayerState.playing) {
          unawaited(_guard(() => player.setVolume(_sfxVolume)));
        }
      }
    }
  }

  void _requestBgm(GameBgm bgm) {
    if (_requestedBgm == bgm && _currentBgm == bgm) return;
    _requestedBgm = bgm;
    if (!_switchingBgm) unawaited(_drainBgmRequests());
  }

  Future<void> _drainBgmRequests() async {
    if (_switchingBgm) return;
    _switchingBgm = true;
    final player = _bgmPlayer!;
    while (!_disposed && !_suspended) {
      final target = _requestedBgm;
      if (target == null || target == _currentBgm) break;
      final succeeded = await _guard(() async {
        if (_currentBgm != null) {
          await _fade(
            player,
            from: player.volume,
            to: 0,
            duration: const Duration(milliseconds: 240),
          );
        }
        if (_disposed || _suspended) return;
        await player.stop();
        _currentBgm = null;
        if (_disposed || _suspended || target != _requestedBgm) return;
        await player.setReleaseMode(
          target.loop ? ReleaseMode.loop : ReleaseMode.stop,
        );
        if (_disposed || _suspended || target != _requestedBgm) return;
        await player.play(AssetSource(target.asset), volume: 0);
        _currentBgm = target;
        if (_suspended) {
          await player.pause();
          return;
        }
        if (target != _requestedBgm) return;
        await _fade(
          player,
          from: 0,
          to: _bgmVolume,
          duration: const Duration(milliseconds: 620),
        );
      });
      if (!succeeded) {
        if (_requestedBgm == target) _requestedBgm = null;
        break;
      }
    }
    _switchingBgm = false;
    if (!_disposed &&
        !_suspended &&
        _requestedBgm != null &&
        _requestedBgm != _currentBgm) {
      unawaited(_drainBgmRequests());
    }
  }

  void _requestAmbience(GameAmbience? ambience) {
    if (_requestedAmbience == ambience && _currentAmbience == ambience) return;
    _requestedAmbience = ambience;
    if (!_switchingAmbience) unawaited(_drainAmbienceRequests());
  }

  Future<void> _drainAmbienceRequests() async {
    if (_switchingAmbience) return;
    _switchingAmbience = true;
    final player = _ambiencePlayer!;
    while (!_disposed && !_suspended) {
      final target = _requestedAmbience;
      if (target == _currentAmbience) break;
      final succeeded = await _guard(() async {
        await player.stop();
        _currentAmbience = null;
        if (_disposed || _suspended || target != _requestedAmbience) return;
        if (target == null) return;
        await player.setReleaseMode(ReleaseMode.loop);
        if (_disposed || _suspended || target != _requestedAmbience) return;
        await player.play(AssetSource(target.asset), volume: _ambienceVolume);
        _currentAmbience = target;
        if (_suspended) await player.pause();
      });
      if (!succeeded) {
        if (_requestedAmbience == target) _requestedAmbience = null;
        break;
      }
    }
    _switchingAmbience = false;
    if (!_disposed && !_suspended && _requestedAmbience != _currentAmbience) {
      unawaited(_drainAmbienceRequests());
    }
  }

  Future<void> _resumeLoops(StoryAudioCue cue) async {
    final bgm = _bgmPlayer!;
    final ambience = _ambiencePlayer!;
    await _guard(() async {
      if (_currentBgm == cue.bgm && bgm.state == PlayerState.paused) {
        await bgm.resume();
      } else {
        _requestedBgm = null;
        _requestBgm(cue.bgm);
      }
      if (_currentAmbience == cue.ambience &&
          ambience.state == PlayerState.paused) {
        await ambience.resume();
      } else {
        _requestedAmbience = null;
        _requestAmbience(cue.ambience);
      }
    });
  }

  Future<void> _fade(
    AudioPlayer player, {
    required double from,
    required double to,
    required Duration duration,
  }) async {
    const steps = 10;
    final delay = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    for (var step = 1; step <= steps; step++) {
      if (_disposed || _suspended) return;
      final value = from + (to - from) * (step / steps);
      await player.setVolume(value.clamp(0.0, 1.0).toDouble());
      await Future<void>.delayed(delay);
    }
  }

  Future<bool> _guard(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } on Object catch (error, stackTrace) {
      debugPrint('Audio playback unavailable: $error\n$stackTrace');
      return false;
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final timer in _sfxStopTimers) {
      timer?.cancel();
    }
    if (!_enabled) return;
    await Future.wait([
      _bgmPlayer!.dispose(),
      _ambiencePlayer!.dispose(),
      ..._sfxPlayers.map((player) => player.dispose()),
    ]);
  }
}

class GameAudioScope extends InheritedWidget {
  const GameAudioScope({super.key, required this.audio, required super.child});

  final GameAudioController audio;

  static GameAudioController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameAudioScope>()?.audio;

  @override
  bool updateShouldNotify(GameAudioScope oldWidget) => audio != oldWidget.audio;
}

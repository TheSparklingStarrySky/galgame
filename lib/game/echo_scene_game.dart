import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../story/story.dart';

class EchoSceneGame extends FlameGame {
  final ValueNotifier<bool> sceneReady = ValueNotifier(false);
  final ValueNotifier<String?> sceneLoadError = ValueNotifier(null);
  SpriteComponent? _backdrop;
  late final _Atmosphere _atmosphere;
  SceneKey _scene = SceneKey.dormitory;
  SceneKey _requestedScene = SceneKey.dormitory;
  bool _loaded = false;
  int _loadRequest = 0;

  @override
  Color backgroundColor() => const Color(0xFF080B0C);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _atmosphere = _Atmosphere(this)..priority = 10;
    add(_atmosphere);
    await _loadScene(_requestedScene);
    _loaded = true;
    if (_backdrop == null && sceneLoadError.value == null) {
      await _loadScene(_requestedScene);
    }
    sceneReady.value = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layoutBackdrop();
  }

  Future<void> setScene(SceneKey scene) async {
    _requestedScene = scene;
    if (!_loaded) return;
    if (_backdrop != null && _scene == scene && sceneLoadError.value == null) {
      return;
    }
    await _loadScene(scene);
  }

  Future<void> retryScene() async {
    if (!_loaded) return;
    await _loadScene(_requestedScene);
  }

  Future<void> _loadScene(SceneKey scene) async {
    final request = ++_loadRequest;
    try {
      final sprite = await loadSprite(_assetFor(scene));
      if (request != _loadRequest || scene != _requestedScene) return;

      final backdrop = _backdrop;
      if (backdrop == null) {
        _backdrop = SpriteComponent(
          sprite: sprite,
          anchor: Anchor.center,
          priority: -10,
        );
        add(_backdrop!);
      } else {
        backdrop.sprite = sprite;
      }
      _scene = scene;
      _atmosphere.scene = scene;
      sceneLoadError.value = null;
      _layoutBackdrop();
    } catch (_) {
      if (request == _loadRequest && scene == _requestedScene) {
        sceneLoadError.value = '场景资源加载失败，请确认游戏服务仍在运行。';
      }
    }
  }

  void setTuning({required bool active, double frequency = 7.2}) {
    if (!_loaded) return;
    _atmosphere
      ..tuning = active
      ..frequency = frequency;
  }

  void setReducedMotion(bool value) {
    if (!_loaded) return;
    _atmosphere.reducedMotion = value;
  }

  String _assetFor(SceneKey scene) => switch (scene) {
    SceneKey.dormitory => 'scenes/dormitory_room.png',
    SceneKey.corridor => 'scenes/facility_corridor.png',
    SceneKey.assemblyHall => 'scenes/assembly_hall.png',
    SceneKey.controlRoom => 'scenes/control_room.png',
    SceneKey.oldGym => 'scenes/old_gym.png',
    SceneKey.infirmary => 'scenes/infirmary.png',
    SceneKey.storageRoom => 'scenes/storage_room.png',
    SceneKey.transferRoom => 'scenes/transfer_room.png',
    SceneKey.archiveCorridor => 'scenes/archive_corridor.png',
    SceneKey.archiveRoom => 'scenes/archive_room.png',
    SceneKey.medicalIsolation => 'scenes/medical_isolation.png',
    SceneKey.securityRoom => 'scenes/security_room.png',
    SceneKey.maintenanceRoom => 'scenes/maintenance_room.png',
    SceneKey.controlCore => 'scenes/control_core.png',
    SceneKey.northRelay => 'scenes/north_relay.png',
    SceneKey.evidencePort => 'scenes/evidence_port.png',
    SceneKey.medicalAirlock => 'scenes/medical_airlock.png',
    SceneKey.testimonyHall => 'scenes/testimony_hall.png',
    SceneKey.testimonyBooth => 'scenes/testimony_booth.png',
    SceneKey.debriefRoom => 'scenes/debrief_room.png',
    SceneKey.hearingRoom => 'scenes/hearing_room.png',
    SceneKey.memorialWall => 'scenes/memorial_wall.png',
    SceneKey.broadcastTower => 'scenes/broadcast_tower.png',
    SceneKey.schoolClassroom => 'scenes/school_classroom.png',
    SceneKey.metroStation => 'scenes/metro_station.png',
    SceneKey.riversideEvening => 'scenes/riverside_evening.png',
  };

  void _layoutBackdrop() {
    final backdrop = _backdrop;
    final source = backdrop?.sprite?.srcSize;
    if (backdrop == null || source == null || size.x <= 0 || size.y <= 0) {
      return;
    }
    final scale = math.max(size.x / source.x, size.y / source.y);
    backdrop
      ..position = size / 2
      ..size = source * scale;
  }
}

class _Atmosphere extends Component {
  _Atmosphere(this.host);

  final EchoSceneGame host;
  SceneKey scene = SceneKey.dormitory;
  bool tuning = false;
  bool reducedMotion = false;
  double frequency = 7.2;
  double _time = 0;

  @override
  void update(double dt) {
    if (reducedMotion) return;
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final gameSize = host.size;
    if (gameSize.x <= 0 || gameSize.y <= 0) return;

    final flicker = reducedMotion
        ? 0.0
        : (math.sin(_time * 7.3) + math.sin(_time * 2.1)) * 0.006;
    final shade = Paint()
      ..shader = Gradient.linear(Offset.zero, Offset(gameSize.x, gameSize.y), [
        Color.fromRGBO(0, 0, 0, 0.08 + flicker),
        Color.fromRGBO(0, 0, 0, 0.48 + flicker),
      ]);
    canvas.drawRect(Offset.zero & Size(gameSize.x, gameSize.y), shade);

    if (scene == SceneKey.controlRoom) {
      final scanlinePaint = Paint()..color = const Color(0x0800B89C);
      for (double y = 0; y < gameSize.y; y += 6) {
        canvas.drawRect(Rect.fromLTWH(0, y, gameSize.x, 1), scanlinePaint);
      }
    }

    if (tuning) _drawSignal(canvas, gameSize);
  }

  void _drawSignal(Canvas canvas, Vector2 gameSize) {
    final centerY = gameSize.y * 0.32;
    final amplitude = 24 + (frequency - 7.2).abs() * 24;
    final path = Path()..moveTo(0, centerY);
    for (double x = 0; x <= gameSize.x; x += 5) {
      final clean = math.sin(x * 0.034 + _time * 3.2) * 14;
      final noise = math.sin(x * 0.11 - _time * 5) * amplitude * 0.35;
      final lock = (1 - ((frequency - 7.2).abs() / 0.8)).clamp(0.0, 1.0);
      path.lineTo(x, centerY + clean * lock + noise * (1 - lock));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xAA8FD8C8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}

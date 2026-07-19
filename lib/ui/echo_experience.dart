import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../audio/audio_cues.dart';
import '../audio/game_audio_controller.dart';
import '../game/echo_scene_game.dart';
import '../story/story.dart';
import '../story/story_controller.dart';
import 'system_panels.dart';

class EchoExperience extends StatefulWidget {
  const EchoExperience({
    super.key,
    required this.controller,
    this.audioEnabled = true,
  });

  final StoryController controller;
  final bool audioEnabled;

  @override
  State<EchoExperience> createState() => _EchoExperienceState();
}

class _EchoExperienceState extends State<EchoExperience>
    with WidgetsBindingObserver {
  late final EchoSceneGame _game;
  late final GameAudioController _audio;
  final GlobalKey _saveCaptureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _game = EchoSceneGame();
    _audio = GameAudioController(enabled: widget.audioEnabled);
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_syncGame);
    widget.controller.attachSaveThumbnailCapture(_captureSaveThumbnail);
    _syncGame();
  }

  @override
  void didUpdateWidget(covariant EchoExperience oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller
      ..removeListener(_syncGame)
      ..detachSaveThumbnailCapture();
    widget.controller
      ..addListener(_syncGame)
      ..attachSaveThumbnailCapture(_captureSaveThumbnail);
    _syncGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_syncGame);
    widget.controller.detachSaveThumbnailCapture();
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _audio.resume();
      case AppLifecycleState.inactive ||
          AppLifecycleState.paused ||
          AppLifecycleState.detached ||
          AppLifecycleState.hidden:
        _audio.suspend();
    }
  }

  Future<String?> _captureSaveThumbnail() async {
    if (kIsWeb) return null;
    final boundary = _saveCaptureKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary || boundary.size.isEmpty) {
      return null;
    }
    if (boundary.debugNeedsPaint) {
      await WidgetsBinding.instance.endOfFrame;
    }
    final pixelRatio = (320 / boundary.size.width).clamp(0.15, 0.75);
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) return null;
    return base64Encode(bytes.buffer.asUint8List());
  }

  void _syncGame() {
    _game.setScene(widget.controller.scene);
    _game.setReducedMotion(widget.controller.reduceMotion);
    _game.setTuning(active: widget.controller.phase == StoryPhase.tuning);
    _audio.sync(widget.controller);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight > constraints.maxWidth) {
          return const _LandscapeRequiredLayer();
        }
        return Scaffold(
          body: GameAudioScope(
            audio: _audio,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _audio.handleUserGesture(),
              child: RepaintBoundary(
                key: _saveCaptureKey,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GameWidget<EchoSceneGame>(game: _game),
                    ValueListenableBuilder<bool>(
                      valueListenable: _game.sceneReady,
                      builder: (context, ready, _) {
                        if (!ready) return const _SceneLoadingLayer();
                        return AnimatedBuilder(
                          animation: widget.controller,
                          builder: (context, _) =>
                              _buildLayer(widget.controller),
                        );
                      },
                    ),
                    ValueListenableBuilder<String?>(
                      valueListenable: _game.sceneLoadError,
                      builder: (context, error, _) {
                        if (error == null) return const SizedBox.shrink();
                        return _SceneLoadErrorBanner(
                          message: error,
                          onRetry: _game.retryScene,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayer(StoryController controller) => switch (controller.phase) {
    StoryPhase.title => _TitleLayer(controller: controller),
    StoryPhase.dialogue => DialogueLayer(
      key: ValueKey(controller.currentId),
      controller: controller,
    ),
    StoryPhase.delegation => _DelegationLayer(controller: controller),
    StoryPhase.investigation => _InvestigationLayer(controller: controller),
    StoryPhase.puzzle => _PuzzleLayer(
      key: ValueKey(controller.currentId),
      controller: controller,
    ),
    StoryPhase.tuning => _TuningLayer(controller: controller, game: _game),
    StoryPhase.deduction => _DeductionLayer(controller: controller),
    StoryPhase.testimony => _TestimonyLayer(controller: controller),
    StoryPhase.ending => _EndingLayer(controller: controller),
  };
}

class _LandscapeRequiredLayer extends StatelessWidget {
  const _LandscapeRequiredLayer();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      key: ValueKey('landscape-required'),
      color: Color(0xFF080B0C),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.screen_rotation_rounded,
                  size: 46,
                  color: Color(0xFFD8A24A),
                ),
                SizedBox(height: 18),
                Text(
                  '请横屏游玩',
                  style: TextStyle(
                    color: Color(0xFFF0EEE7),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '旋转设备后将自动继续',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9EA9A4), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DelegationLayer extends StatefulWidget {
  const _DelegationLayer({required this.controller});

  final StoryController controller;

  @override
  State<_DelegationLayer> createState() => _DelegationLayerState();
}

class _DelegationLayerState extends State<_DelegationLayer> {
  String? _permission;
  String? _trustee;
  String? _witness;

  static const _permissions = [
    (id: 'read', label: '只读', icon: Icons.visibility_outlined),
    (id: 'door', label: '门禁', icon: Icons.door_front_door_outlined),
    (id: 'clause', label: '条款', icon: Icons.article_outlined),
    (id: 'full', label: '完整', icon: Icons.admin_panel_settings_outlined),
  ];
  static const _trustees = [
    (id: 'hanqi', label: '韩骐 / 04', icon: Icons.shield_outlined),
    (id: 'tangyi', label: '唐弈 / 06', icon: Icons.swap_horiz_rounded),
    (id: 'chenmo', label: '陈默 / 08', icon: Icons.terminal_rounded),
  ];
  static const _witnesses = [
    (id: 'xingyao', label: '黎星遥 / 02', icon: Icons.graphic_eq_rounded),
    (id: 'sumi', label: '苏弥 / 03', icon: Icons.monitor_heart_outlined),
    (id: 'yelan', label: '叶岚 / 11', icon: Icons.fact_check_outlined),
  ];

  bool get _ready =>
      _permission != null && _trustee != null && _witness != null;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xE8080B0C),
      child: Stack(
        children: [
          _TopBar(controller: widget.controller, title: '临时托管 / PDA'),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 56, 82, 10),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Material(
                  color: const Color(0xF20C1213),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: const BorderSide(color: Color(0xFF52605B)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.phonelink_lock_outlined,
                              size: 19,
                              color: Color(0xFFD8A24A),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '01号终端 · 20分钟审计授权',
                                style: TextStyle(
                                  color: Color(0xFFF2F3EE),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '等待三方签名',
                              style: TextStyle(
                                color: Color(0xFF8FC7B8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _DelegationRow(
                          title: '权限范围',
                          options: _permissions,
                          selected: _permission,
                          onSelected: (value) =>
                              setState(() => _permission = value),
                        ),
                        const SizedBox(height: 7),
                        _DelegationRow(
                          title: '受托人',
                          options: _trustees,
                          selected: _trustee,
                          onSelected: (value) =>
                              setState(() => _trustee = value),
                        ),
                        const SizedBox(height: 7),
                        _DelegationRow(
                          title: '见证人',
                          options: _witnesses,
                          selected: _witness,
                          onSelected: (value) =>
                              setState(() => _witness = value),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: FilledButton.icon(
                            key: const ValueKey('confirm-delegation'),
                            onPressed: _ready
                                ? () => widget.controller.completeDelegation(
                                    permission: _permission!,
                                    trustee: _trustee!,
                                    witness: _witness!,
                                  )
                                : null,
                            icon: const Icon(Icons.verified_user_outlined),
                            label: const Text('生成三方托管记录'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _RightControlRail(
            controller: widget.controller,
            playbackEnabled: false,
          ),
        ],
      ),
    );
  }
}

class _DelegationRow extends StatelessWidget {
  const _DelegationRow({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<({IconData icon, String id, String label})> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFAAB3AF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              for (final option in options) ...[
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      key: ValueKey('delegation-${option.id}'),
                      onPressed: () => onSelected(option.id),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        backgroundColor: selected == option.id
                            ? const Color(0xFF284B43)
                            : const Color(0xFF111819),
                        side: BorderSide(
                          color: selected == option.id
                              ? const Color(0xFF8FC7B8)
                              : const Color(0xFF35433F),
                        ),
                      ),
                      icon: Icon(option.icon, size: 15),
                      label: Text(
                        option.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ),
                if (option != options.last) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SceneLoadErrorBanner extends StatelessWidget {
  const _SceneLoadErrorBanner({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 10, 80, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Material(
            color: const Color(0xF2111718),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0xFFD8A24A)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFFD8A24A),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xFFF2F4F1),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SceneLoadingLayer extends StatelessWidget {
  const _SceneLoadingLayer();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF080B0C),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '168:00:00',
              style: TextStyle(
                color: Color(0xFFD8A24A),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(width: 120, child: LinearProgressIndicator(minHeight: 2)),
          ],
        ),
      ),
    );
  }
}

class _TitleLayer extends StatelessWidget {
  const _TitleLayer({required this.controller});

  final StoryController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xE6080B0C), Color(0x66080B0C), Color(0x18080B0C)],
          stops: [0, 0.58, 1],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 900;
            // Retina browser captures can expose only about 720 logical pixels;
            // keep that common landscape height in the one-screen title layout.
            final short = constraints.maxHeight < 760;
            final veryShort = constraints.maxHeight < 380;
            final leftPadding = veryShort ? 24.0 : (narrow ? 40.0 : 72.0);
            final rightPadding = veryShort ? 16.0 : (narrow ? 28.0 : 56.0);
            final panelGap = veryShort ? 14.0 : (narrow ? 24.0 : 56.0);
            final toolsWidth = veryShort
                ? (constraints.maxWidth * 0.38).clamp(190.0, 220.0)
                : (narrow ? 230.0 : 320.0);
            final commandWidth = math.min(
              260.0,
              constraints.maxWidth -
                  leftPadding -
                  rightPadding -
                  panelGap -
                  toolsWidth,
            );
            final buttonGap = veryShort ? 6.0 : 9.0;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                leftPadding,
                veryShort ? 8 : (short ? 22 : 62),
                rightPadding,
                veryShort ? 8 : (short ? 16 : 24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Eyebrow(
                                text: 'ZERO HOUR PROTOCOL / 168:00:00',
                              ),
                              SizedBox(
                                height: veryShort ? 3 : (short ? 6 : 12),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '零点协议',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        fontSize: veryShort
                                            ? 34
                                            : (short ? 40 : 72),
                                        color: const Color(0xFFF0EEE7),
                                      ),
                                ),
                              ),
                              SizedBox(
                                height: veryShort ? 2 : (short ? 6 : 14),
                              ),
                              Text(
                                '规则只决定谁能活，选择决定你还是不是人。',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: const Color(0xFFB9C3BE),
                                      fontSize: veryShort
                                          ? 13
                                          : (narrow ? 15 : 18),
                                      height: veryShort ? 1.4 : null,
                                    ),
                              ),
                              SizedBox(
                                height: veryShort ? 6 : (short ? 16 : 32),
                              ),
                              _CommandButton(
                                icon: Icons.play_arrow_rounded,
                                label: '开始游戏',
                                onPressed: () => controller.startNew(),
                                primary: true,
                                width: commandWidth,
                                height: veryShort ? 40 : 46,
                              ),
                              if (controller.auditModeUnlocked) ...[
                                SizedBox(height: buttonGap),
                                _CommandButton(
                                  icon: Icons.manage_search_rounded,
                                  label: '审计周目',
                                  onPressed: () => controller.startNew(
                                    mode: StoryRunMode.audit,
                                  ),
                                  width: commandWidth,
                                  height: veryShort ? 40 : 46,
                                ),
                              ],
                              SizedBox(height: buttonGap),
                              _CommandButton(
                                icon: Icons.update_rounded,
                                label: '继续游戏',
                                onPressed: controller.hasAutoSave
                                    ? controller.resume
                                    : null,
                                width: commandWidth,
                                height: veryShort ? 40 : 46,
                              ),
                              SizedBox(height: buttonGap),
                              _CommandButton(
                                icon: Icons.folder_open_rounded,
                                label: '读取存档',
                                onPressed: () => showSaveLoad(
                                  context,
                                  controller,
                                  loadOnly: true,
                                ),
                                width: commandWidth,
                                height: veryShort ? 40 : 46,
                              ),
                              SizedBox(
                                height: veryShort ? 6 : (short ? 14 : 26),
                              ),
                              Text(
                                'DAY 1–2 · 已开放',
                                style: TextStyle(
                                  color: Color(0xFF8D9994),
                                  fontSize: veryShort ? 10 : 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: panelGap),
                  SizedBox(
                    width: toolsWidth,
                    child: _TitleToolsPanel(
                      controller: controller,
                      compact: short,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TitleToolsPanel extends StatelessWidget {
  const _TitleToolsPanel({required this.controller, required this.compact});

  final StoryController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tools = [
      _TitleTool(
        icon: Icons.account_tree_outlined,
        label: '线路图',
        onPressed: () => showRouteMap(context, controller),
      ),
      _TitleTool(
        icon: Icons.collections_outlined,
        label: 'CG 鉴赏',
        onPressed: () => showCgGallery(context, controller),
      ),
      _TitleTool(
        icon: Icons.emoji_events_outlined,
        label: '结局回顾',
        onPressed: () => showEndingReview(context, controller),
      ),
      _TitleTool(
        icon: Icons.tune_rounded,
        label: '设置',
        onPressed: () => showSettings(context, controller),
      ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow(text: 'ARCHIVE / SYSTEM'),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: compact ? 1.5 : 1.6,
          children: tools,
        ),
      ],
    );
  }
}

class DialogueLayer extends StatefulWidget {
  const DialogueLayer({super.key, required this.controller});

  final StoryController controller;

  @override
  State<DialogueLayer> createState() => _DialogueLayerState();
}

class _DialogueLayerState extends State<DialogueLayer> {
  Timer? _typeTimer;
  Timer? _advanceTimer;
  late final List<_DialoguePage> _textPages;
  int _pageIndex = 0;
  int _visibleCharacters = 0;
  bool _progressionScheduled = false;
  bool _interfaceHidden = false;

  StoryBeat get beat => widget.controller.current;
  CgEntry? get _cgEntry => cgById(beat.cgId);
  _DialoguePage get _currentPage => _textPages[_pageIndex];
  bool get _isLastPage => _pageIndex == _textPages.length - 1;
  bool get _isFinalCgFrame {
    final entry = _cgEntry;
    return entry != null && beat.cgFrame >= entry.assets.length - 1;
  }

  int get _totalCharacters => _currentPage.text.characters.length;
  bool get _finished => _visibleCharacters >= _totalCharacters;

  @override
  void initState() {
    super.initState();
    _textPages = _paginateText(
      beat,
      maxCharacters: beat.cgId == null ? 72 : 46,
    );
    _syncThumbnailFallback();
    _startTyping();
  }

  static List<_DialoguePage> _paginateText(
    StoryBeat beat, {
    int maxCharacters = 72,
  }) {
    final pages = <_DialoguePage>[];
    for (final passage in beat.passages) {
      pages.addAll(_paginatePassage(passage, maxCharacters: maxCharacters));
    }
    return pages.isEmpty
        ? const [_DialoguePage(text: '', speaker: Speaker.narration)]
        : pages;
  }

  static List<_DialoguePage> _paginatePassage(
    StoryPassage passage, {
    required int maxCharacters,
  }) {
    final text = passage.text;
    final characters = text.trim().characters.toList();
    if (characters.isEmpty) {
      return [_DialoguePage(text: '', speaker: passage.speaker)];
    }

    const preferredBreaks = {'。', '！', '？', '；', '\n'};
    const fallbackBreaks = {'，', '：', '、'};
    final pages = <_DialoguePage>[];
    var start = 0;
    while (start < characters.length) {
      var end = start + maxCharacters;
      if (end >= characters.length) {
        end = characters.length;
      } else {
        final minimumBreak = start + maxCharacters ~/ 2;
        var preferred = -1;
        var fallback = -1;
        for (var index = end; index > minimumBreak; index--) {
          final character = characters[index - 1];
          if (preferred < 0 && preferredBreaks.contains(character)) {
            preferred = index;
            break;
          }
          if (fallback < 0 && fallbackBreaks.contains(character)) {
            fallback = index;
          }
        }
        if (preferred >= 0) {
          end = preferred;
        } else if (fallback >= 0) {
          end = fallback;
        }
      }
      final page = characters.sublist(start, end).join().trim();
      if (page.isNotEmpty) {
        pages.add(_DialoguePage(text: page, speaker: passage.speaker));
      }
      start = end;
    }
    return pages;
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _advanceTimer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _visibleCharacters = 0;
    final interval = Duration(
      milliseconds: (38 - widget.controller.textSpeed * 20).round(),
    );
    _typeTimer = Timer.periodic(interval, (timer) {
      if (!mounted) return;
      if (_visibleCharacters >= _totalCharacters) {
        timer.cancel();
        _markCgViewedIfComplete();
        _scheduleProgression();
      } else {
        setState(() => _visibleCharacters += 1);
      }
    });
  }

  void _finishTyping() {
    _typeTimer?.cancel();
    if (!_finished) setState(() => _visibleCharacters = _totalCharacters);
    _markCgViewedIfComplete();
    _scheduleProgression();
  }

  void _markCgViewedIfComplete() {
    if (!_isLastPage || !_finished || !_isFinalCgFrame) return;
    if (beat.cgId case final id?) widget.controller.markCgViewed(id);
  }

  void _showNextPage() {
    if (_isLastPage) return;
    _typeTimer?.cancel();
    _advanceTimer?.cancel();
    setState(() {
      _pageIndex += 1;
      _visibleCharacters = 0;
      _progressionScheduled = false;
    });
    _syncThumbnailFallback();
    _startTyping();
  }

  void _advancePageOrNode() {
    if (_isLastPage) {
      _completeNode();
    } else {
      _showNextPage();
    }
  }

  void _completeNode() {
    if (_isFinalCgFrame) {
      if (beat.cgId case final id?) widget.controller.markCgViewed(id);
    }
    widget.controller.advance();
  }

  void _scheduleProgression() {
    _advanceTimer?.cancel();
    _progressionScheduled = false;
    if (_isLastPage && beat.choices.isNotEmpty) return;

    if (widget.controller.skipMode) {
      if (!widget.controller.canSkipCurrent) {
        widget.controller.setSkipMode(false);
        return;
      }
      _advanceTimer = Timer(const Duration(milliseconds: 110), () {
        if (mounted) _advancePageOrNode();
      });
      return;
    }

    if (widget.controller.autoPlay) {
      _advanceTimer = Timer(
        Duration(milliseconds: (widget.controller.autoDelay * 1000).round()),
        () {
          if (mounted) _advancePageOrNode();
        },
      );
    }
  }

  void _syncPlaybackMode() {
    if (_progressionScheduled) return;
    _progressionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.controller.skipMode && !_finished) {
        _finishTyping();
      } else if (_finished) {
        _scheduleProgression();
      }
    });
  }

  void _hideInterface() {
    _advanceTimer?.cancel();
    if (widget.controller.autoPlay) {
      widget.controller.setAutoPlay(false);
    }
    if (widget.controller.skipMode) {
      widget.controller.setSkipMode(false);
    }
    setState(() => _interfaceHidden = true);
  }

  void _restoreInterface() {
    setState(() => _interfaceHidden = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.skipMode || widget.controller.autoPlay) {
      _syncPlaybackMode();
    } else {
      _advanceTimer?.cancel();
      _progressionScheduled = false;
    }

    final visibleText = _currentPage.text.characters
        .take(_visibleCharacters)
        .toString();
    return LayoutBuilder(
      builder: (context, constraints) {
        final short = constraints.maxHeight < 520;
        const panelHeight = 112.0;
        final railInset = short ? 72.0 : 84.0;
        final visiblePortrait = _cgEntry == null
            ? portraitAsset(_portraitSpeaker, _portraitMood)
            : null;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (_cgEntry case final entry?)
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: widget.controller.reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 360),
                  child: SizedBox.expand(
                    key: ValueKey('story-cg-${entry.id}-${beat.cgFrame}'),
                    child: Image.asset(
                      _cgAsset(entry),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, _, _) => const ColoredBox(
                        color: Color(0xFF090E0F),
                        child: Center(
                          child: Text(
                            '事件 CG 加载失败',
                            style: TextStyle(color: Color(0xFFF2F4F1)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!_interfaceHidden) _TopBar(controller: widget.controller),
            if (visiblePortrait case final asset?)
              Positioned.fill(
                top: 42,
                right: railInset,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    key: ValueKey('portrait-${_portraitSpeaker.name}'),
                    width: (constraints.maxWidth * 0.42).clamp(230.0, 430.0),
                    height: double.infinity,
                    child: _RetryingPortrait(asset: asset),
                  ),
                ),
              ),
            if (!_interfaceHidden &&
                _finished &&
                _isLastPage &&
                widget.controller.availableChoices.isNotEmpty)
              SafeArea(
                minimum: EdgeInsets.fromLTRB(
                  20,
                  62,
                  railInset,
                  panelHeight + 28,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: _ChoiceOverlay(
                      choices: widget.controller.availableChoices,
                      compact: short,
                      onChoice: (choice) {
                        GameAudioScope.maybeOf(
                          context,
                        )?.playSfx(GameSfx.choiceReveal);
                        widget.controller.choose(choice);
                      },
                    ),
                  ),
                ),
              ),
            if (!_interfaceHidden)
              SafeArea(
                minimum: EdgeInsets.fromLTRB(16, 64, railInset, 14),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: SizedBox(
                      width: double.infinity,
                      height: panelHeight,
                      child: _DialoguePanel(
                        speaker: _currentPage.speaker,
                        visibleText: visibleText,
                        finished: _finished,
                        onHide: _hideInterface,
                        onTap: !_finished
                            ? _finishTyping
                            : !_isLastPage
                            ? _showNextPage
                            : beat.choices.isEmpty
                            ? _completeNode
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            if (!_interfaceHidden)
              _RightControlRail(controller: widget.controller),
            if (_interfaceHidden)
              Positioned.fill(
                child: Semantics(
                  button: true,
                  label: '恢复界面',
                  child: GestureDetector(
                    key: const ValueKey('restore-dialogue-interface'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _restoreInterface,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Speaker get _portraitSpeaker {
    if (portraitAsset(_currentPage.speaker) != null) {
      return _currentPage.speaker;
    }
    return beat.speaker;
  }

  String get _portraitMood =>
      _portraitSpeaker == beat.speaker ? beat.portraitMood : 'neutral';

  String _cgAsset(CgEntry entry) {
    final frame = beat.cgFrame.clamp(0, entry.assets.length - 1);
    return entry.assets[frame];
  }

  void _syncThumbnailFallback() {
    final entry = _cgEntry;
    widget.controller.setSaveThumbnailFallback(
      asset: entry == null ? sceneImageAsset(beat.scene) : _cgAsset(entry),
      text: _currentPage.text,
    );
  }
}

class _RetryingPortrait extends StatefulWidget {
  const _RetryingPortrait({required this.asset});

  final String asset;

  @override
  State<_RetryingPortrait> createState() => _RetryingPortraitState();
}

class _RetryingPortraitState extends State<_RetryingPortrait> {
  int _attempt = 0;

  @override
  void didUpdateWidget(covariant _RetryingPortrait oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _attempt = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      widget.asset,
      key: ValueKey('${widget.asset}-$_attempt'),
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, _, _) {
        return Center(
          child: Material(
            color: const Color(0xE6111718),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0xFFD8A24A)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    color: Color(0xFFD8A24A),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '立绘资源加载失败',
                    style: TextStyle(color: Color(0xFFF2F4F1), fontSize: 13),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _attempt++),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重试立绘'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DialoguePage {
  const _DialoguePage({required this.text, required this.speaker});

  final String text;
  final Speaker speaker;
}

class _DialoguePanel extends StatelessWidget {
  const _DialoguePanel({
    required this.speaker,
    required this.visibleText,
    required this.finished,
    required this.onHide,
    required this.onTap,
  });

  final Speaker speaker;
  final String visibleText;
  final bool finished;
  final VoidCallback onHide;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('dialogue-panel'),
      color: const Color(0xED101516),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        side: BorderSide(color: Color(0x667F9B94)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('dialogue-tap-target'),
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 9),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (speakerName(speaker).isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 2,
                          color: _speakerColor(speaker),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          speakerName(speaker),
                          style: TextStyle(
                            color: _speakerColor(speaker),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                  ],
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 34),
                      child: Text(
                        visibleText,
                        maxLines: speakerName(speaker).isEmpty ? 4 : 3,
                        overflow: TextOverflow.clip,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          height: 1.5,
                          color: const Color(0xFFE9EAE5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: -9,
                right: -9,
                child: Tooltip(
                  message: '隐藏界面',
                  child: IconButton(
                    key: const ValueKey('hide-dialogue-interface'),
                    onPressed: onHide,
                    style: IconButton.styleFrom(
                      fixedSize: const Size.square(34),
                      padding: EdgeInsets.zero,
                      foregroundColor: const Color(0xFF9EA9A4),
                    ),
                    icon: const Icon(Icons.visibility_off_outlined, size: 18),
                  ),
                ),
              ),
              if (finished && onTap != null)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFFD8A24A),
                    size: 21,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _speakerColor(Speaker speaker) => switch (speaker) {
    Speaker.liXingyao => const Color(0xFF8FC7B8),
    Speaker.suMi => const Color(0xFFE0A38D),
    Speaker.hanQi => const Color(0xFFD9695F),
    Speaker.wuZheng => const Color(0xFF8EA6B8),
    Speaker.tangYi => const Color(0xFFC6A6D8),
    Speaker.linCheng => const Color(0xFF72C8C0),
    Speaker.chenMo => const Color(0xFF8FB8C8),
    Speaker.gaoYuan => const Color(0xFFC6A36A),
    Speaker.zhouXu => const Color(0xFF9BA7C9),
    Speaker.yeLan => const Color(0xFFC68A9B),
    Speaker.administrator => const Color(0xFFD8A24A),
    _ => const Color(0xFFC7CECA),
  };
}

class _ChoiceOverlay extends StatelessWidget {
  const _ChoiceOverlay({
    required this.choices,
    required this.compact,
    required this.onChoice,
  });

  final List<StoryChoice> choices;
  final bool compact;
  final ValueChanged<StoryChoice> onChoice;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('choice-overlay'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: choices
            .map(
              (choice) => Padding(
                padding: EdgeInsets.only(top: compact ? 5 : 8),
                child: _ChoiceButton(
                  choice: choice,
                  showCaption: !compact,
                  onPressed: () => onChoice(choice),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.choice,
    required this.showCaption,
    required this.onPressed,
  });

  final StoryChoice choice;
  final bool showCaption;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1B2222),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        side: BorderSide(color: Color(0xFF35433F)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: showCaption ? 10 : 8,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.arrow_forward_rounded,
                size: 17,
                color: Color(0xFFD8A24A),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (showCaption) ...[
                      const SizedBox(height: 2),
                      Text(
                        choice.caption,
                        style: const TextStyle(
                          color: Color(0xFFAAB3AF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PuzzleLayer extends StatefulWidget {
  const _PuzzleLayer({super.key, required this.controller});

  final StoryController controller;

  @override
  State<_PuzzleLayer> createState() => _PuzzleLayerState();
}

class _PuzzleLayerState extends State<_PuzzleLayer> {
  static const _weightNames = <String, String>{
    'ring': '环',
    'triangle': '三角',
    'square': '方框',
    'cross': '十字',
    'dot': '圆点',
  };
  static const _weightValues = <String, int>{
    'triangle': 1,
    'cross': 2,
    'ring': 3,
    'dot': 4,
    'square': 5,
  };
  static const _initialTiles = <int>[1, 4, 2, 3, 0, 8, 6, 7, 5];

  String _accessLocation = 'transfer';
  String _accessCode = '';
  String? _feedback;
  String? _balanceLeft;
  String? _balanceRight;
  final List<String?> _balanceOrder = List<String?>.filled(5, null);
  late List<int> _tiles = List<int>.of(_initialTiles);
  int _slideMoves = 0;
  final List<String> _auditOrder = [];
  final Map<String, int> _syncChannels = {
    'north': 2,
    'archive': 5,
    'maintenance': 3,
  };
  final List<String> _syncOrder = [];

  static const _auditFields = <String, String>{
    'slot': '身份槽 / 12',
    'owner': '界面署名 / 01',
    'lease': '撤销会话 / R-08',
    'area': '区域代码 / E-04',
    'interval': '重放间隔 / 07s',
  };

  bool get _hasCard =>
      widget.controller.inventoryItems.contains('maintenance_card');
  bool get _hasNote => widget.controller.inventoryItems.contains('shift_note');
  bool get _cardSwiped =>
      widget.controller.flags.contains('ch3_access_card_swiped');

  void _collectAccessItem(String id) {
    if (id == 'maintenance_card' && !_hasCard) {
      GameAudioScope.maybeOf(context)?.playSfx(GameSfx.itemPickup);
      widget.controller.recordPuzzleProgress(
        'ch3_access_card_found',
        grantsItem: 'maintenance_card',
      );
      setState(() => _feedback = '柜门夹层里压着一张磨损严重的维护门禁卡。');
      return;
    }
    if (id == 'shift_note' && !_hasNote) {
      GameAudioScope.maybeOf(context)?.playSfx(GameSfx.itemPickup);
      widget.controller.recordPuzzleProgress(
        'ch3_shift_note_found',
        grantsItem: 'shift_note',
      );
      setState(() {
        _feedback = '倒班记录只保留两次交接：09时和16时。页脚注明旧控制器按先后顺序连写时间。';
      });
      return;
    }
    setState(() => _feedback = '这里已经没有新的可取物。');
  }

  void _swipeAccessCard() {
    if (_cardSwiped) {
      setState(() => _feedback = '读卡器保持绿色，数字键盘已经接通。');
      return;
    }
    if (!_hasCard) {
      GameAudioScope.maybeOf(context)?.playSfx(GameSfx.accessDenied);
      setState(() => _feedback = '读卡器短促鸣叫，没有识别到可用凭证。');
      return;
    }
    GameAudioScope.maybeOf(context)?.playSfx(GameSfx.accessGranted);
    widget.controller.recordPuzzleProgress(
      'ch3_access_card_swiped',
      consumesItems: const ['maintenance_card'],
    );
    setState(() => _feedback = '卡片被读卡器吞入回收槽，门锁转为等待四位输入。');
  }

  void _enterDigit(String digit) {
    if (!_cardSwiped || _accessCode.length >= 4) return;
    GameAudioScope.maybeOf(context)?.playSfx(GameSfx.keypadPress);
    setState(() {
      _accessCode += digit;
      _feedback = null;
    });
  }

  void _submitAccessCode() {
    if (!_cardSwiped) {
      GameAudioScope.maybeOf(context)?.playSfx(GameSfx.accessDenied);
      setState(() => _feedback = '键盘没有亮起。门上的读卡器仍在等待响应。');
      return;
    }
    if (_accessCode == '0916') {
      GameAudioScope.maybeOf(context)?.playSfx(GameSfx.accessGranted);
      widget.controller.completePuzzle('access_0916');
      return;
    }
    GameAudioScope.maybeOf(context)?.playSfx(GameSfx.accessDenied);
    setState(() {
      _accessCode = '';
      _feedback = '锁舌没有动作，四个按键同时熄灭。';
    });
  }

  void _selectWeight(String id) {
    setState(() {
      _feedback = null;
      if (_balanceLeft == null || _balanceRight != null) {
        _balanceLeft = id;
        _balanceRight = null;
      } else if (_balanceLeft != id) {
        _balanceRight = id;
      }
    });
  }

  void _weigh() {
    final left = _balanceLeft;
    final right = _balanceRight;
    if (left == null || right == null) return;
    final comparison = _weightValues[left]!.compareTo(_weightValues[right]!);
    GameAudioScope.maybeOf(context)?.playSfx(GameSfx.balanceWeight);
    setState(() {
      _feedback = comparison == 0
          ? '天平保持水平。'
          : comparison < 0
          ? '${_weightNames[left]}一侧升起，${_weightNames[right]}一侧下沉。'
          : '${_weightNames[left]}一侧下沉，${_weightNames[right]}一侧升起。';
    });
  }

  void _setOrder(int index, String id) {
    setState(() {
      for (var slot = 0; slot < _balanceOrder.length; slot++) {
        if (_balanceOrder[slot] == id) _balanceOrder[slot] = null;
      }
      _balanceOrder[index] = id;
      _feedback = null;
    });
  }

  void _submitBalanceOrder() {
    const expected = ['triangle', 'cross', 'ring', 'dot', 'square'];
    if (_balanceOrder.any((id) => id == null)) {
      setState(() => _feedback = '五个承重槽仍有空位。');
      return;
    }
    if (List.generate(
      5,
      (index) => _balanceOrder[index] == expected[index],
    ).every((correct) => correct)) {
      GameAudioScope.maybeOf(context)?.playSfx(GameSfx.circuitPowerOn);
      widget.controller.completePuzzle('triangle_cross_ring_dot_square');
      return;
    }
    GameAudioScope.maybeOf(context)?.playSfx(GameSfx.accessDenied);
    setState(() => _feedback = '机关没有响应。某些相邻砝码的轻重关系仍然相反。');
  }

  void _moveTile(int index) {
    final blank = _tiles.indexOf(8);
    final sameRow = index ~/ 3 == blank ~/ 3;
    final adjacent =
        (sameRow && (index - blank).abs() == 1) || (index - blank).abs() == 3;
    if (!adjacent) {
      GameAudioScope.maybeOf(context)?.playSfx(GameSfx.combineFail);
      setState(() => _feedback = '这块石板没有与空格相邻。');
      return;
    }
    GameAudioScope.maybeOf(context)?.playSfx(GameSfx.stoneTileSlide);
    setState(() {
      final tile = _tiles[index];
      _tiles[index] = 8;
      _tiles[blank] = tile;
      _slideMoves += 1;
      _feedback = null;
    });
    if (List.generate(
      9,
      (index) => _tiles[index] == index,
    ).every((correct) => correct)) {
      GameAudioScope.maybeOf(context)?.playSfx(GameSfx.circuitPowerOn);
      widget.controller.completePuzzle('circuit_complete');
    }
  }

  void _selectAuditField(String id) {
    setState(() {
      _feedback = null;
      if (_auditOrder.remove(id)) return;
      if (_auditOrder.length == 3) _auditOrder.removeAt(0);
      _auditOrder.add(id);
    });
  }

  void _submitAuditOrder() {
    if (_auditOrder.length < 3) {
      GameAudioScope.maybeOf(context)?.playSfx(GameSfx.accessDenied);
      setState(() => _feedback = '校验输入仍有空列。');
      return;
    }
    if (_auditOrder.join('_') == 'slot_lease_interval') {
      GameAudioScope.maybeOf(context)?.playSfx(GameSfx.accessGranted);
      widget.controller.completePuzzle('slot_lease_interval');
      return;
    }
    GameAudioScope.maybeOf(context)?.playSfx(GameSfx.accessDenied);
    setState(() => _feedback = '三组短码能够成列，但校验值没有闭合。');
  }

  void _setSyncChannel(String id, double value) {
    GameAudioScope.maybeOf(context)?.playSfx(GameSfx.keypadPress);
    setState(() {
      _syncChannels[id] = value.round();
      _feedback = null;
    });
  }

  void _selectSyncOrder(String id) {
    GameAudioScope.maybeOf(context)?.playSfx(GameSfx.uiConfirm);
    setState(() {
      _feedback = null;
      if (_syncOrder.remove(id)) return;
      if (_syncOrder.length == 3) _syncOrder.removeAt(0);
      _syncOrder.add(id);
    });
  }

  void _submitSyncPlan() {
    const expectedChannels = {'north': 4, 'archive': 1, 'maintenance': 6};
    const expectedOrder = ['maintenance', 'archive', 'north'];
    final channelsMatch = expectedChannels.entries.every(
      (entry) => _syncChannels[entry.key] == entry.value,
    );
    final orderMatches = _syncOrder.join('_') == expectedOrder.join('_');
    if (channelsMatch && orderMatches) {
      GameAudioScope.maybeOf(context)?.playSfx(GameSfx.circuitPowerOn);
      widget.controller.completePuzzle(
        'channels_4_1_6__maintenance_archive_north',
      );
      return;
    }
    GameAudioScope.maybeOf(context)?.playSfx(GameSfx.accessDenied);
    setState(() {
      if (!channelsMatch && !orderMatches) {
        _feedback = '三处回声仍互相覆盖，启动顺序也让关闭脉冲被下一节点补回。';
      } else if (!channelsMatch) {
        _feedback = '顺序已经形成单向传播，但至少一处频道仍与本地延迟不匹配。';
      } else {
        _feedback = '频道已经锁定，启动时序却让先关闭的节点被后续心跳恢复。';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xD9080B0C),
      child: Stack(
        children: [
          _TopBar(controller: widget.controller, title: _puzzleTitle),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(18, 68, 82, 14),
            child: LayoutBuilder(
              builder: (context, constraints) =>
                  switch (widget.controller.currentId) {
                    'ch3_transfer_access_puzzle' => _buildAccessPuzzle(
                      constraints,
                    ),
                    'ch3_balance_puzzle' => _buildBalancePuzzle(constraints),
                    'ch3_audit_manifest_puzzle' => _buildAuditPuzzle(),
                    'ch7_sync_puzzle' => _buildSyncPuzzle(constraints),
                    _ => _buildSlidePuzzle(constraints),
                  },
            ),
          ),
          _RightControlRail(
            controller: widget.controller,
            playbackEnabled: false,
          ),
        ],
      ),
    );
  }

  String get _puzzleTitle => switch (widget.controller.currentId) {
    'ch3_transfer_access_puzzle' => '隔离转运间 / 门禁联锁',
    'ch3_balance_puzzle' => '承重机关 / 无刻度天平',
    'ch3_audit_manifest_puzzle' => '离线审计 / 灰色校验表',
    'ch7_sync_puzzle' => '三节点同步 / 传播延迟',
    _ => '图案机关 / 八块石板',
  };

  Widget _buildSyncPuzzle(BoxConstraints constraints) {
    const nodeLabels = {
      'north': '北端节点',
      'archive': '档案节点',
      'maintenance': '维护节点',
    };
    const nodeHints = {
      'north': '回声延迟 4 拍',
      'archive': '本地脉冲 1 拍',
      'maintenance': '恢复窗口 6 拍',
    };
    final compact = constraints.maxWidth < 720;
    final channelPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow(text: 'LOCAL CHANNELS'),
        const SizedBox(height: 7),
        const Text(
          '三处终端只显示各自的延迟记录。把每个节点锁到能抵消本地回声的频道，再决定关闭脉冲的传播顺序。',
          style: TextStyle(color: Color(0xFFAAB5B0), fontSize: 11, height: 1.4),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: nodeLabels.entries
                .map((entry) {
                  final value = _syncChannels[entry.key]!;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.fromLTRB(10, 9, 10, 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111817),
                        border: Border.all(color: const Color(0xFF35433F)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            entry.key == 'north'
                                ? Icons.settings_input_antenna_rounded
                                : entry.key == 'archive'
                                ? Icons.dns_outlined
                                : Icons.memory_rounded,
                            color: const Color(0xFF8FC7B8),
                            size: 21,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            entry.value,
                            style: const TextStyle(
                              color: Color(0xFFE5E8E3),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            nodeHints[entry.key]!,
                            style: const TextStyle(
                              color: Color(0xFF89948F),
                              fontSize: 9.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            value.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: Color(0xFFD8A24A),
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          Slider(
                            key: ValueKey('sync-channel-${entry.key}'),
                            min: 1,
                            max: 6,
                            divisions: 5,
                            value: value.toDouble(),
                            label: '$value',
                            onChanged: (next) =>
                                _setSyncChannel(entry.key, next),
                          ),
                        ],
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
      ],
    );
    final orderPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow(text: 'SHUTDOWN ORDER'),
        const SizedBox(height: 7),
        const Text(
          '先关闭恢复窗口最长的节点，沿单向传播压缩剩余心跳。重复点击可取消选择。',
          style: TextStyle(color: Color(0xFFAAB5B0), fontSize: 11, height: 1.4),
        ),
        const SizedBox(height: 10),
        ...nodeLabels.entries.map((entry) {
          final index = _syncOrder.indexOf(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: SizedBox(
              width: double.infinity,
              child: FilterChip(
                key: ValueKey('sync-order-${entry.key}'),
                selected: index >= 0,
                showCheckmark: false,
                avatar: index < 0
                    ? const Icon(Icons.radio_button_unchecked, size: 17)
                    : CircleAvatar(child: Text('${index + 1}')),
                label: Text(entry.value),
                onSelected: (_) => _selectSyncOrder(entry.key),
              ),
            ),
          );
        }),
        const Spacer(),
        if (_feedback != null)
          Text(
            _feedback!,
            style: const TextStyle(
              color: Color(0xFFF0D08F),
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('submit-sync-plan'),
            onPressed: _syncOrder.length == 3 ? _submitSyncPlan : null,
            icon: const Icon(Icons.power_settings_new_rounded),
            label: const Text('执行同步关闭'),
          ),
        ),
      ],
    );
    if (compact) {
      return SingleChildScrollView(
        child: SizedBox(
          height: math.max(420, constraints.maxHeight),
          child: Column(
            children: [
              Expanded(flex: 3, child: channelPanel),
              const Divider(height: 20, color: Color(0xFF35433F)),
              Expanded(flex: 2, child: orderPanel),
            ],
          ),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 3, child: channelPanel),
        const VerticalDivider(width: 24, color: Color(0xFF35433F)),
        Expanded(flex: 2, child: orderPanel),
      ],
    );
  }

  Widget _buildAuditPuzzle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow(text: 'RECOVERED CHECKSUMS'),
              const SizedBox(height: 8),
              const Text(
                '三份日志共用一组被删去的校验列。表头已经消失，只能根据两起案件中稳定存在、且不受界面署名影响的字段重建顺序。',
                style: TextStyle(
                  color: Color(0xFFDDE2DF),
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              ...const [
                ('F-01', 'SLOT 12  /  REPLAY +07s'),
                ('B-03', 'LEASE R-08  /  OWNER 01'),
                ('E-04', 'SLOT 12  /  AREA E-04'),
              ].map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111817),
                      border: Border.all(color: const Color(0xFF35433F)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 46,
                          child: Text(
                            row.$1,
                            style: const TextStyle(
                              color: Color(0xFFD8A24A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            row.$2,
                            style: const TextStyle(
                              color: Color(0xFFAAB5B0),
                              fontSize: 10.5,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 28, color: Color(0xFF35433F)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow(text: 'COLUMN ORDER'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: _auditFields.entries
                    .map((entry) {
                      final order = _auditOrder.indexOf(entry.key);
                      return FilterChip(
                        key: ValueKey('audit-field-${entry.key}'),
                        selected: order >= 0,
                        showCheckmark: false,
                        avatar: order < 0
                            ? null
                            : CircleAvatar(child: Text('${order + 1}')),
                        label: Text(entry.value),
                        onSelected: (_) => _selectAuditField(entry.key),
                      );
                    })
                    .toList(growable: false),
              ),
              const Spacer(),
              if (_feedback != null)
                Text(
                  _feedback!,
                  style: const TextStyle(
                    color: Color(0xFFF0D08F),
                    fontSize: 11,
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const ValueKey('submit-audit-order'),
                  onPressed: _submitAuditOrder,
                  icon: const Icon(Icons.rule_folder_outlined),
                  label: const Text('执行离线校验'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccessPuzzle(BoxConstraints constraints) {
    final panelHeight = math.max(210.0, constraints.maxHeight - 48);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: 'assembly',
                icon: Icon(Icons.meeting_room_outlined),
                label: Text('集合厅'),
              ),
              ButtonSegment(
                value: 'archive',
                icon: Icon(Icons.inventory_2_outlined),
                label: Text('档案走廊'),
              ),
              ButtonSegment(
                value: 'transfer',
                icon: Icon(Icons.door_sliding_outlined),
                label: Text('转运间'),
              ),
            ],
            selected: {_accessLocation},
            onSelectionChanged: (value) => setState(() {
              _accessLocation = value.single;
              _feedback = null;
            }),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: panelHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xEE101516),
                border: Border.all(color: const Color(0xFF45524E)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _accessLocation == 'transfer'
                    ? _buildTransferLock()
                    : _buildSearchLocation(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchLocation() {
    final assembly = _accessLocation == 'assembly';
    final collected = assembly ? _hasCard : _hasNote;
    final asset = assembly
        ? 'assets/images/items/storage/maintenance_card.png'
        : 'assets/images/items/storage/shift_note.png';
    return Row(
      children: [
        SizedBox(width: 150, child: Image.asset(asset, fit: BoxFit.contain)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Eyebrow(text: assembly ? 'DUTY CABINET' : 'SHIFT ARCHIVE'),
              const SizedBox(height: 7),
              Text(
                assembly
                    ? '值班柜没有上锁，里面是停电预案、过期巡检牌和一层松动的金属底板。'
                    : '旧倒班夹按日期排列。多数页面被撕走，只剩转运设备启用当天的一张复写纸。',
                style: const TextStyle(
                  color: Color(0xFFE5E8E3),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: ValueKey(
                  assembly ? 'access-search-card' : 'access-search-note',
                ),
                onPressed: collected
                    ? null
                    : () => _collectAccessItem(
                        assembly ? 'maintenance_card' : 'shift_note',
                      ),
                icon: Icon(
                  collected ? Icons.check_rounded : Icons.search_rounded,
                ),
                label: Text(collected ? '已经取走' : '检查夹层'),
              ),
              if (_feedback != null) ...[
                const SizedBox(height: 8),
                Text(
                  _feedback!,
                  style: const TextStyle(
                    color: Color(0xFFF0D08F),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransferLock() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow(text: 'MECHANICAL INTERLOCK'),
              const SizedBox(height: 7),
              const Text(
                '门上没有联网标识。读卡器、四位键盘和机械锁舌构成三段串联，失败不会显示缺少了哪一步。',
                style: TextStyle(
                  color: Color(0xFFE5E8E3),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('access-swipe-card'),
                    onPressed: _swipeAccessCard,
                    icon: Icon(
                      _cardSwiped
                          ? Icons.credit_score_rounded
                          : Icons.contactless_outlined,
                    ),
                    label: Text(_cardSwiped ? '读卡完成' : '尝试读卡'),
                  ),
                  if (_hasNote)
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _feedback = '复写纸保留09时与16时两次交接；旧控制器的页脚要求按发生顺序连写。';
                      }),
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('查看倒班记录'),
                    ),
                ],
              ),
              if (_feedback != null) ...[
                const SizedBox(height: 7),
                Text(
                  _feedback!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF0D08F),
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        const VerticalDivider(width: 24, color: Color(0xFF35433F)),
        SizedBox(
          width: 222,
          child: Column(
            children: [
              Container(
                key: const ValueKey('access-code-display'),
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF080B0C),
                  border: Border.all(color: const Color(0xFF52605B)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _accessCode.padRight(4, '—').split('').join('  '),
                  style: const TextStyle(
                    color: Color(0xFF8FC7B8),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Expanded(
                child: GridView.count(
                  padding: EdgeInsets.zero,
                  crossAxisCount: 4,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: 1.45,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final digit in '1234567890'.split(''))
                      OutlinedButton(
                        key: ValueKey('access-digit-$digit'),
                        onPressed: _cardSwiped
                            ? () => _enterDigit(digit)
                            : null,
                        child: Text(digit),
                      ),
                    IconButton.outlined(
                      tooltip: '退格',
                      onPressed: _accessCode.isEmpty
                          ? null
                          : () => setState(() {
                              _accessCode = _accessCode.substring(
                                0,
                                _accessCode.length - 1,
                              );
                            }),
                      icon: const Icon(Icons.backspace_outlined, size: 18),
                    ),
                    IconButton.filled(
                      key: const ValueKey('access-submit-code'),
                      tooltip: '确认输入',
                      onPressed: _accessCode.length == 4
                          ? _submitAccessCode
                          : null,
                      icon: const Icon(Icons.login_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalancePuzzle(BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Eyebrow(text: 'COMPARE'),
                const SizedBox(height: 7),
                const Text(
                  '五块砝码外形相同、重量各异。任选两块放上无刻度天平，记录哪一侧下沉。',
                  style: TextStyle(color: Color(0xFFDDE2DF), fontSize: 11),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: _weightNames.entries
                      .map(
                        (entry) => ChoiceChip(
                          key: ValueKey('weight-${entry.key}'),
                          label: Text(entry.value),
                          avatar: const Icon(Icons.hexagon_outlined, size: 16),
                          selected:
                              _balanceLeft == entry.key ||
                              _balanceRight == entry.key,
                          onSelected: (_) => _selectWeight(entry.key),
                        ),
                      )
                      .toList(growable: false),
                ),
                const Spacer(),
                Row(
                  children: [
                    _BalancePan(
                      label: _balanceLeft == null
                          ? '左盘'
                          : _weightNames[_balanceLeft!]!,
                    ),
                    const Expanded(
                      child: Icon(
                        Icons.balance_rounded,
                        color: Color(0xFFD8A24A),
                        size: 34,
                      ),
                    ),
                    _BalancePan(
                      label: _balanceRight == null
                          ? '右盘'
                          : _weightNames[_balanceRight!]!,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const ValueKey('weigh-selected'),
                  onPressed: _balanceLeft != null && _balanceRight != null
                      ? _weigh
                      : null,
                  icon: const Icon(Icons.scale_outlined),
                  label: const Text('称量'),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(color: Color(0xFF35433F)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Eyebrow(text: 'LIGHT TO HEAVY'),
                const SizedBox(height: 7),
                const Text(
                  '将五块砝码按从轻到重放入承重槽。每种图案只能使用一次。',
                  style: TextStyle(color: Color(0xFFDDE2DF), fontSize: 11),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var index = 0; index < 5; index++) ...[
                      Expanded(
                        child: PopupMenuButton<String>(
                          key: ValueKey('weight-slot-$index'),
                          tooltip: '选择第${index + 1}块砝码',
                          onSelected: (id) => _setOrder(index, id),
                          itemBuilder: (context) => _weightNames.entries
                              .map(
                                (entry) => PopupMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                              )
                              .toList(growable: false),
                          child: Container(
                            height: 54,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF171E1D),
                              border: Border.all(
                                color: const Color(0xFF52605B),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _balanceOrder[index] == null
                                  ? '${index + 1}'
                                  : _weightNames[_balanceOrder[index]!]!,
                              style: const TextStyle(
                                color: Color(0xFFF0EEE7),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (index < 4)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF8C9994),
                            size: 16,
                          ),
                        ),
                    ],
                  ],
                ),
                const Spacer(),
                if (_feedback != null)
                  Text(
                    _feedback!,
                    style: const TextStyle(
                      color: Color(0xFFF0D08F),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: const ValueKey('submit-weight-order'),
                    onPressed: _submitBalanceOrder,
                    icon: const Icon(Icons.power_settings_new_rounded),
                    label: const Text('启动承重机关'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlidePuzzle(BoxConstraints constraints) {
    final boardSize = math.min(232.0, constraints.maxHeight);
    return Row(
      children: [
        SizedBox.square(
          dimension: boardSize,
          child: GridView.builder(
            key: const ValueKey('circuit-slide-board'),
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final tile = _tiles[index];
              if (tile == 8) {
                return DecoratedBox(
                  key: const ValueKey('circuit-empty'),
                  decoration: BoxDecoration(
                    color: const Color(0x55080B0C),
                    border: Border.all(color: const Color(0xFF35433F)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }
              return Material(
                key: ValueKey('circuit-tile-$tile'),
                color: const Color(0xFF171E1D),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFF52605B)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: InkWell(
                  onTap: () => _moveTile(index),
                  child: CustomPaint(painter: _CircuitTilePainter(tile)),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow(text: 'PATTERN LOCK'),
              const SizedBox(height: 8),
              const Text(
                '机关盘有九个位置，只有八块石板。点击与空格相邻的石板移动它；当边缘线路和中心环纹完整闭合，最后一道轨道才会通电。',
                style: TextStyle(
                  color: Color(0xFFE5E8E3),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '移动 $_slideMoves 次',
                    style: const TextStyle(
                      color: Color(0xFFF0D08F),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    tooltip: '重置石板',
                    onPressed: () => setState(() {
                      _tiles = List<int>.of(_initialTiles);
                      _slideMoves = 0;
                      _feedback = null;
                    }),
                    icon: const Icon(Icons.restart_alt_rounded),
                  ),
                ],
              ),
              if (_feedback != null) ...[
                const SizedBox(height: 8),
                Text(
                  _feedback!,
                  style: const TextStyle(
                    color: Color(0xFFF0D08F),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BalancePan extends StatelessWidget {
  const _BalancePan({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 38,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF8FC7B8), width: 2)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFFE5E8E3), fontSize: 11),
      ),
    );
  }
}

class _CircuitTilePainter extends CustomPainter {
  const _CircuitTilePainter(this.tile);

  final int tile;

  @override
  void paint(Canvas canvas, Size size) {
    final row = tile ~/ 3;
    final column = tile % 3;
    final center = Offset(size.width / 2, size.height / 2);
    final line = Paint()
      ..color = const Color(0xFFD8A24A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, size.shortestSide * 0.035);
    final glow = Paint()
      ..color = const Color(0x558FC7B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = line.strokeWidth * 3;

    void segment(Offset end) {
      canvas.drawLine(center, end, glow);
      canvas.drawLine(center, end, line);
    }

    if (row > 0) segment(Offset(center.dx, 0));
    if (row < 2) segment(Offset(center.dx, size.height));
    if (column > 0) segment(Offset(0, center.dy));
    if (column < 2) segment(Offset(size.width, center.dy));

    final radius = size.shortestSide * (tile == 4 ? 0.19 : 0.13);
    canvas.drawCircle(center, radius, glow);
    canvas.drawCircle(center, radius, line);
    if (tile == 4) {
      canvas.drawCircle(center, radius * 0.48, line);
    } else if (tile.isEven) {
      canvas.drawCircle(center, radius * 0.22, Paint()..color = line.color);
    }
  }

  @override
  bool shouldRepaint(covariant _CircuitTilePainter oldDelegate) =>
      oldDelegate.tile != tile;
}

class _InvestigationLayer extends StatefulWidget {
  const _InvestigationLayer({required this.controller});

  final StoryController controller;

  @override
  State<_InvestigationLayer> createState() => _InvestigationLayerState();
}

class _InspectionAction {
  const _InspectionAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.result,
    this.requiresItems = const [],
    this.requiresActions = const [],
    this.consumesItems = const [],
    this.grantsItem,
    this.verifiesClue,
  });

  final String id;
  final String label;
  final IconData icon;
  final String result;
  final List<String> requiresItems;
  final List<String> requiresActions;
  final List<String> consumesItems;
  final String? grantsItem;
  final String? verifiesClue;
}

class _InvestigationItemVariant {
  const _InvestigationItemVariant({
    required this.requiresActions,
    required this.description,
    this.name,
    this.asset,
  });

  final List<String> requiresActions;
  final String description;
  final String? name;
  final String? asset;
}

class _InvestigationItem {
  const _InvestigationItem({
    required this.id,
    required this.name,
    required this.asset,
    required this.description,
    this.variants = const [],
  });

  final String id;
  final String name;
  final String asset;
  final String description;
  final List<_InvestigationItemVariant> variants;
}

class _InvestigationTarget {
  const _InvestigationTarget({
    required this.id,
    required this.initialLabel,
    required this.clueTitle,
    required this.asset,
    required this.prompt,
    required this.actions,
  });

  final String id;
  final String initialLabel;
  final String clueTitle;
  final String asset;
  final String prompt;
  final List<_InspectionAction> actions;
}

class _InvestigationSpec {
  const _InvestigationSpec({required this.title, required this.targets});

  final String title;
  final List<_InvestigationTarget> targets;
}

class _InvestigationLayerState extends State<_InvestigationLayer> {
  final ScrollController _inventoryScrollController = ScrollController();
  String? _activeItemId;
  String? _combineItemId;
  _InspectionAction? _lastAction;
  String? _feedback;
  bool _backpackOpen = false;

  @override
  void dispose() {
    _inventoryScrollController.dispose();
    super.dispose();
  }

  static const _items = <String, _InvestigationItem>{
    'terminal_area': _InvestigationItem(
      id: 'terminal_area',
      name: '终端与地面记录',
      asset: 'assets/images/items/control_room/distance_terminal.png',
      description: '倒下的终端、灰尘轮廓和尸体位置被一并收入现场记录。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['terminal_marks'],
          description: '终端边角的灰尘轮廓完整，原位已经确认；它并非在案发后才被搬到尸体附近。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['terminal_marks', 'terminal_measure'],
          name: '终端与矛盾距离',
          description: '灰尘轮廓确认终端原位；实测距离为 1.4m，而裁定缓存写着 23m。两组位置数据无法同时成立。',
        ),
      ],
    ),
    'wall_box': _InvestigationItem(
      id: 'wall_box',
      name: '墙边黑盒',
      asset: 'assets/images/items/control_room/sealed_signal_box.png',
      description: '无铭牌黑盒，外壳无电源指示，侧面带有屏蔽层。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['box_heat'],
          name: '有余温的墙边黑盒',
          description: '隔着布仍能感觉到外壳余温，散热孔附近还留有新鲜指纹。它在断电前不久运行过，但屏蔽层仍未打开。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['box_heat', 'box_open'],
          name: '拆开的信号中继器',
          asset: 'assets/images/items/control_room/signal_repeater.png',
          description: '屏蔽层已经拆开。新装模块接在终端定位频道上，缓存停在案发前三分钟，能够转发伪造的距离握手。',
        ),
      ],
    ),
    'collar_lock': _InvestigationItem(
      id: 'collar_lock',
      name: '项圈锁扣记录',
      asset: 'assets/images/items/control_room/collar_timer.png',
      description: '爆裂后的锁扣和计时模块，焦痕与金属受力方向并不一致。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['collar_force'],
          description: '锁舌没有撬压变形，外部划痕也未延伸到触发片；强拆引爆的可能已经排除。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['collar_force', 'collar_compare'],
          name: '项圈阈值记录',
          description: '缓存中的距离异常持续 181 秒，项圈在 180 秒阈值执行。死亡来自规则内的计时触发。',
        ),
      ],
    ),
    'tool_tray': _InvestigationItem(
      id: 'tool_tray',
      name: '公共工具盘',
      asset: 'assets/images/items/control_room/tool_tray.png',
      description: '放着旧维修件的分格工具盘，大多数工具被多人使用过。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['tray_ruler'],
          description: '折叠尺已经取走，盘内还剩几件混有多人污痕的维修工具。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['tray_pick'],
          description: '绝缘拨片已经取走，盘内其余维修工具混有多人使用痕迹。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['tray_ruler', 'tray_pick'],
          name: '翻检后的公共工具盘',
          description: '折叠尺与绝缘拨片均已取走。剩余表面只有重叠污痕，无法作为身份指认依据。',
        ),
      ],
    ),
    'folding_ruler': _InvestigationItem(
      id: 'folding_ruler',
      name: '折叠尺',
      asset: 'assets/images/items/control_room/folding_ruler.png',
      description: '金属折叠尺，适合沿地面灰尘轮廓复原终端距离。',
    ),
    'insulated_pick': _InvestigationItem(
      id: 'insulated_pick',
      name: '绝缘拨片',
      asset: 'assets/images/items/control_room/insulated_pick.png',
      description: '非金属绝缘撬片，可在不短接内部线路的情况下拆开屏蔽层。',
    ),
    'distance_record': _InvestigationItem(
      id: 'distance_record',
      name: '1.4m 实测记录',
      asset: 'assets/images/items/control_room/distance_record.png',
      description: '终端原位到尸体的实测距离，可与项圈裁定缓存交叉比对。',
    ),
    'control_inner': _InvestigationItem(
      id: 'control_inner',
      name: '控制箱内侧',
      asset: 'assets/images/items/gym/shutter_control.png',
      description: '封锁控制箱的内部面板，新旧线路混在一起。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['control_trace'],
          description: '亮铜线把“首次查看”接到“登记操作者”，长度恰好可以藏回面板；还需要离线验证它是否会启动撤权计时。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['control_trace', 'control_replay'],
          name: '确认过的桥接控制箱',
          description: '离线复现确认：控制页首次开启就会启动十分钟撤权计时，桥接线专门把调查者登记为留守者。',
        ),
      ],
    ),
    'north_door_floor': _InvestigationItem(
      id: 'north_door_floor',
      name: '北门断索与灰样',
      asset: 'assets/images/items/gym/brake_cable.png',
      description: '从北门滑轮下方取得的断索、积灰和封条碎片。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['cable_dust'],
          description: '滑轮槽有旧灰，断面仍亮，金属碎屑压在今天移动的封条上；断裂发生在今天。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['cable_dust', 'cable_marks'],
          name: '人为剪断的制动索',
          description: '断口两侧留下角度相同的钳口压痕，结合积灰顺序，可确认制动索在当天被人为剪断。',
        ),
      ],
    ),
    'empty_cradle': _InvestigationItem(
      id: 'empty_cradle',
      name: '12号空底座',
      asset: 'assets/images/items/gym/terminal_cradle.png',
      description: '没有终端的充电底座，本地指示灯仍以七秒间隔闪烁。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['cradle_isolate'],
          description: '外部网络已切断，指示灯仍每七秒闪烁；握手记录预先存在底座内部。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['cradle_isolate', 'cradle_read'],
          name: '12号伪造握手底座',
          description: '本地缓存反复发送“身份槽12、状态有效、距离0.0m”，让空设备被地图识别为场内参与者。',
        ),
      ],
    ),
    'service_cart': _InvestigationItem(
      id: 'service_cart',
      name: '维修推车',
      asset: 'assets/images/items/gym/service_cart.png',
      description: '体育馆设备间的旧推车，抽屉里还有封存的检测工具。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['cart_lead'],
          description: '离线测试线已经取走，抽屉深处仍能看到一只包着软布的光学工具盒。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['cart_lens'],
          description: '折叠放大镜已经取走，线材格里还留着一条封存测试线。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['cart_lead', 'cart_lens'],
          name: '翻空的维修推车',
          description: '离线测试线和折叠放大镜都已收入背包，推车剩余零件没有进一步调查价值。',
        ),
      ],
    ),
    'offline_test_lead': _InvestigationItem(
      id: 'offline_test_lead',
      name: '离线测试线',
      asset: 'assets/images/items/gym/offline_test_lead.png',
      description: '不接入设施网络的测试线，可复现控制输入或读取本地缓存。',
    ),
    'folding_magnifier': _InvestigationItem(
      id: 'folding_magnifier',
      name: '折叠放大镜',
      asset: 'assets/images/items/gym/folding_magnifier.png',
      description: '小型检验放大镜，能分辨钢索断口上的微小压痕。',
    ),
    'sealed_crate': _InvestigationItem(
      id: 'sealed_crate',
      name: '重新封好的水箱',
      asset: 'assets/images/items/storage/sealed_crate.png',
      description: '纸箱封条平整贴合，表面没有普通撕开的破口。仅凭外观无法确认它是否被动过。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['crate_seam'],
          name: '胶层异常的水箱',
          description: '封条边缘纤维完整，胶层中央却有连续的平滑带，像整片受热后脱离。需要用不会破坏胶层的方式确认。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['crate_seam', 'crate_uv'],
          name: '二次热压封条',
          description: '紫外照射显出两层不同方向的胶纹与连续热痕。箱体确实被打开过，随后又把原封条压回原位。',
        ),
      ],
    ),
    'locked_audit_pda': _InvestigationItem(
      id: 'locked_audit_pda',
      name: '锁定的审计PDA',
      asset: 'assets/images/items/storage/locked_audit_pda.png',
      description: '墙面审计终端只显示“所有者01已确认”，详细字段被锁定在离线缓存中。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['pda_clock'],
          name: '时钟异常的审计PDA',
          description: '本地时钟比公共频道慢0.2秒，远不足以解释四十二秒差值；机身侧面还有一个封闭维护接口。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['pda_clock', 'pda_log'],
          name: '恢复会话记录的审计PDA',
          description: '离线缓存显示：操作来自早晨已经撤销的托管会话，控制器在撤销后仍保留了四十二秒的可用窗口。',
        ),
      ],
    ),
    'supply_shelf': _InvestigationItem(
      id: 'supply_shelf',
      name: '出现空位的货架',
      asset: 'assets/images/items/storage/supply_shelf.png',
      description: '水、止痛剂和滤芯各少了一部分，货架没有倾倒，地面也没有明显拖痕。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['shelf_dust'],
          name: '带撞针印的货架',
          description: '底部承重弹簧旁夹着一张压纸，机械撞针留下时间痕迹，但刻度需要独立校准。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['shelf_dust', 'shelf_weight'],
          name: '先于签名减重的货架',
          description: '校准后确认货架在09:16:03减轻26.4kg，比01电子签名早四十五秒。物资先离开，授权记录后出现。',
        ),
      ],
    ),
    'audit_case': _InvestigationItem(
      id: 'audit_case',
      name: '墙角审计工具箱',
      asset: 'assets/images/items/storage/audit_case.png',
      description: '铅封已经由叶岚记录，内部格位放着几件不会直接联网的审计工具。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['case_uv', 'case_scale', 'case_reader'],
          name: '取空的审计工具箱',
          description: '紫外检验灯、弹簧测力计和离线读取器都已收入背包。空格位没有夹层或身份痕迹。',
        ),
      ],
    ),
    'uv_lamp': _InvestigationItem(
      id: 'uv_lamp',
      name: '紫外检验灯',
      asset: 'assets/images/items/storage/uv_lamp.png',
      description: '手持冷光检验灯，可显出胶层受热、叠压和重新粘合后的纹理差异。',
    ),
    'spring_scale': _InvestigationItem(
      id: 'spring_scale',
      name: '弹簧测力计',
      asset: 'assets/images/items/storage/spring_scale.png',
      description: '带机械刻度的校准测力计，不依赖设施供电，可复核货架承重弹簧的偏移量。',
    ),
    'offline_reader': _InvestigationItem(
      id: 'offline_reader',
      name: '离线读取器',
      asset: 'assets/images/items/storage/offline_reader.png',
      description: '只读取本地存储、不向主机发送握手的审计设备，适合检查被界面隐藏的缓存字段。',
    ),
    'handover_receipt': _InvestigationItem(
      id: 'handover_receipt',
      name: '托管会话交接凭条',
      asset: 'assets/images/items/storage/handover_receipt.png',
      description: '从审计缓存恢复的实体凭条：撤销标记、旧会话编号和控制器确认时间被印在同一张记录上。',
    ),
    'maintenance_card': _InvestigationItem(
      id: 'maintenance_card',
      name: '旧维护门禁卡',
      asset: 'assets/images/items/storage/maintenance_card.png',
      description: '从集合厅值班柜夹层取出的旧卡，边缘磨损严重，芯片仍可被离线读卡器识别。',
    ),
    'shift_note': _InvestigationItem(
      id: 'shift_note',
      name: '转运设备倒班记录',
      asset: 'assets/images/items/storage/shift_note.png',
      description: '复写纸只保留09时与16时两次交接，页脚注明旧控制器按发生顺序连写时间。',
    ),
    'medical_test_case': _InvestigationItem(
      id: 'medical_test_case',
      name: '离线医疗检验盒',
      asset: 'assets/images/items/medical/medical_test_case.png',
      description: '封签完整的床旁检验盒，内部工具可以在不联网的情况下复核残液与音频输出。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['medical_case_strip', 'medical_case_spectrum'],
          name: '取空的医疗检验盒',
          description: '药物试纸与离线频谱夹已收入背包，盒内剩余格位均为密封备品。',
        ),
      ],
    ),
    'sedative_test_strip': _InvestigationItem(
      id: 'sedative_test_strip',
      name: '镇静剂检验试纸',
      asset: 'assets/images/items/medical/sedative_test_strip.png',
      description: '可对注射器内壁与输液残液进行同批对照，显色结果会保留在纸卡上。',
    ),
    'offline_spectrum_clip': _InvestigationItem(
      id: 'offline_spectrum_clip',
      name: '离线频谱夹',
      asset: 'assets/images/items/medical/offline_spectrum_clip.png',
      description: '夹在耳机左右声道之间的被动检测器，不向PDA发送任何握手。',
    ),
    'injection_infusion_set': _InvestigationItem(
      id: 'injection_infusion_set',
      name: '注射器与输液残液',
      asset: 'assets/images/items/medical/injection_infusion_set.png',
      description: '外层注射器包装已被打开，无菌内封、针帽和输液接口需要分开检查。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['medical_inner_seal'],
          name: '未穿刺的注射与输液组',
          description: '注射器内封没有针帽穿刺点，输液端口防回流膜也完整；还需要检验残液。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['medical_inner_seal', 'medical_residue_assay'],
          name: '排除镇静剂投药的器材',
          asset: 'assets/images/items/medical/injection_infusion_checked.png',
          description: '无菌内封与输液接口均未穿破，试纸对照也未检出失踪镇静剂。现场没有可验证的投药路径。',
        ),
      ],
    ),
    'medical_assay_card': _InvestigationItem(
      id: 'medical_assay_card',
      name: '药物检验对照卡',
      asset: 'assets/images/items/medical/medical_assay_card.png',
      description: '注射器内壁、输液残液和标准样并列显色；前两项均未呈现镇静剂反应。',
    ),
    'triage_record': _InvestigationItem(
      id: 'triage_record',
      name: '分时检伤记录',
      asset: 'assets/images/items/medical/triage_record.png',
      description: '星遥从首次耳鸣到恢复对话的体征、症状与操作时间被分开记录。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['triage_timeline'],
          description: '眼震、恶心与定向障碍均早于意识丧失，拔掉右耳机后逐步减轻。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['triage_timeline', 'triage_compare'],
          name: '前庭刺激型晕厥记录',
          description: '呼吸未受抑制，瞳孔等大；眼震与定向障碍随单侧暴露加重，与常见镇静剂过量模式不同。',
        ),
      ],
    ),
    'patient_headset': _InvestigationItem(
      id: 'patient_headset',
      name: '星遥的双声道耳机',
      asset: 'assets/images/items/medical/patient_headset.png',
      description: '右侧耳罩被星遥在倒下前抓住，左右接头可以分别离线检查。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['headset_channel_check'],
          description: '左右声道线路完整，右侧输出缓存的写入频率却显著高于左侧。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['headset_channel_check', 'headset_spectrum'],
          name: '记录定向脉冲的耳机',
          asset: 'assets/images/items/medical/patient_headset_checked.png',
          description: '离线频谱显示右声道每七秒收到一组18.6kHz窄脉冲，左声道与空气麦克风中都不存在。',
        ),
      ],
    ),
    'headset_spectrum_capture': _InvestigationItem(
      id: 'headset_spectrum_capture',
      name: '右声道脉冲捕获卡',
      asset: 'assets/images/items/medical/headset_spectrum_capture.png',
      description: '七秒周期的18.6kHz脉冲只存在于右声道，证明暴露沿PDA输出链定向发生。',
    ),
    'archive_roster': _InvestigationItem(
      id: 'archive_roster',
      name: '装订绑架名册',
      asset: 'assets/images/items/archive/archive_roster.png',
      description: '厚纸名册从01排到12，末页的纸张、墨色与装订状态需要分开核对。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['archive_roster_binding'],
          name: '装订痕迹连续的名册',
          description: '01至11的页码、骑缝章和指纹栏连续；“12”位于末页新墨粉上，还需要复原打印先后。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['archive_roster_binding', 'archive_roster_overlay'],
          name: '确认只有十一人的原始名册',
          asset: 'assets/images/items/archive/archive_roster_verified.png',
          description: '斜纹片显示“12”的墨粉覆盖装订锈斑，且缺少姓名、指纹、药量和运输编号。原始绑架链只包含01至11。',
        ),
      ],
    ),
    'archive_photo': _InvestigationItem(
      id: 'archive_photo',
      name: '被涂改的旧员工合照',
      asset: 'assets/images/items/archive/archive_photo.png',
      description: '合照右侧有一块被黑墨覆盖的长方形区域，背面粘着半张褪色资产签。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['archive_photo_edges'],
          description: '黑墨边缘是规则的设备轮廓，不像沿人像描画；背面资产签仍无法完整辨认。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['archive_photo_edges', 'archive_photo_light'],
          name: '显出维护终端的旧合照',
          asset: 'assets/images/items/archive/archive_photo_revealed.png',
          description: '透射光显出推车式测试终端与“SLOT-12 / MAINTENANCE”资产标签。被遮住的从来不是一张人脸。',
        ),
      ],
    ),
    'access_backup': _InvestigationItem(
      id: 'access_backup',
      name: '门禁备份纸卷',
      asset: 'assets/images/items/archive/access_backup.png',
      description: '热敏纸连续记录身份槽、区域和秒级时间，纸卷很长，直接阅读难以看出跨区关系。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['archive_access_sequence'],
          description: '已圈出12号握手：F-01、C-02与E-04的记录相隔只有七秒，但还需要与实际路线时间叠合。',
        ),
        _InvestigationItemVariant(
          requiresActions: [
            'archive_access_sequence',
            'archive_access_overlay',
          ],
          name: '不可能的12号跨区路径',
          asset: 'assets/images/items/archive/access_backup_mapped.png',
          description: '透明时间尺显示最短步行需要九分钟；七秒切换只能由多个固定底座轮流重放同一身份。',
        ),
      ],
    ),
    'archive_server': _InvestigationItem(
      id: 'archive_server',
      name: '离线服务器镜像台',
      asset: 'assets/images/items/archive/server_mirror.png',
      description: '镜像台与主机物理断开，抽屉内封存着三件年代鉴别和校验工具。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: [
            'archive_take_overlay',
            'archive_take_light',
            'archive_take_checksum',
          ],
          name: '取出工具的镜像台',
          description: '年代斜纹片、冷光透射片和只读校验钥匙均已取出；镜像配置仍需要独立校验。',
        ),
        _InvestigationItemVariant(
          requiresActions: [
            'archive_take_overlay',
            'archive_take_light',
            'archive_take_checksum',
            'archive_server_checksum',
          ],
          name: '验证身份槽配置的镜像台',
          asset: 'assets/images/items/archive/server_mirror_verified.png',
          description: '只读校验确认12号仅有“计入人数、接受托管、占用区域”三项开关，没有个人档案；修改均由ZERO裁定进程签名。',
        ),
      ],
    ),
    'date_overlay': _InvestigationItem(
      id: 'date_overlay',
      name: '年代斜纹片',
      asset: 'assets/images/items/archive/date_overlay.png',
      description: '带微距刻线的透明片，可对齐纸张压痕、锈斑与热敏时间，判断记录生成先后。',
    ),
    'transmitted_light': _InvestigationItem(
      id: 'transmitted_light',
      name: '冷光透射片',
      asset: 'assets/images/items/archive/transmitted_light.png',
      description: '均匀低温背光片，可显出相纸黑墨下的轮廓和背面资产标签，不继续损伤旧照片。',
    ),
    'checksum_key': _InvestigationItem(
      id: 'checksum_key',
      name: '只读校验钥匙',
      asset: 'assets/images/items/archive/checksum_key.png',
      description: '只验证离线镜像签名、不具备写入能力的硬件钥匙，无法借检查动作修改配置。',
    ),
    'ballot_packet': _InvestigationItem(
      id: 'ballot_packet',
      name: '实体票纸审计包',
      asset: 'assets/images/items/vote/ballot_packet.png',
      description: '透明封套里装着匿名槽与委托槽吐出的实体票纸。相同文字不代表它们来自同一张纸。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['ballot_take_lamp'],
          description: '封套侧袋中的斜光检验灯已取出。票纸边缘的微孔和纸尾摘要还没有进行叠合。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['ballot_take_lamp', 'ballot_microholes'],
          name: '一次草稿、两次提交的票纸',
          asset: 'assets/images/items/vote/ballot_packet_verified.png',
          description: '两张票拥有不同感应槽微孔，却共享同一枚草稿摘要和唯一生成时间。内容只输入过一次，系统却接受了两次提交。',
        ),
      ],
    ),
    'ballot_oblique_lamp': _InvestigationItem(
      id: 'ballot_oblique_lamp',
      name: '票纸斜光检验灯',
      asset: 'assets/images/items/vote/ballot_oblique_lamp.png',
      description: '低角度冷光能同时显出感应微孔、压痕和热敏摘要，不会照出匿名票的持有人。',
    ),
    'delegation_roll': _InvestigationItem(
      id: 'delegation_roll',
      name: '委托链热敏纸卷',
      asset: 'assets/images/items/vote/delegation_roll.png',
      description: '纸卷显示委托、再次转交与撤回均有真实签名，但界面只展示最外层的当前状态。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['delegation_take_reader'],
          description: '离线租约读取夹已经取出。纸上的撤回印章还需要与每一层会话的失效时间对齐。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['delegation_take_reader', 'delegation_chain_trace'],
          name: '末端租约仍有效的委托链',
          asset: 'assets/images/items/vote/delegation_roll_verified.png',
          description: '原持有人撤回后立即恢复票权，第二层代理却仍保留十分钟租约。同一授权根在撤回传播不完整时分成了两条有效路径。',
        ),
      ],
    ),
    'delegation_lease_reader': _InvestigationItem(
      id: 'delegation_lease_reader',
      name: '离线租约读取夹',
      asset: 'assets/images/items/vote/delegation_lease_reader.png',
      description: '只读设备可显示每层委托的授权根、建立时间和本地到期时间，不会访问匿名票内容。',
    ),
    'location_board': _InvestigationItem(
      id: 'location_board',
      name: '位置快照与点名板',
      asset: 'assets/images/items/vote/location_board.png',
      description: '系统地图和纸质点名使用相同编号，却分别记录自动同步位置与本人到场时间。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['location_take_overlay'],
          description: '透明时间叠片已经取出。两份记录尚未按分钟对齐，不能只凭编号位置不同认定有人撒谎。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['location_take_overlay', 'location_superimpose'],
          name: '滞后十分钟的位置快照',
          asset: 'assets/images/items/vote/location_board_verified.png',
          description:
              '林澄已回到集合厅、系统仍把07留在仓储；高原已进入安保侧廊、地图却显示09在白板旁。快照会把撤离警告发往错误位置。',
        ),
      ],
    ),
    'position_time_overlay': _InvestigationItem(
      id: 'position_time_overlay',
      name: '透明分钟叠片',
      asset: 'assets/images/items/vote/position_time_overlay.png',
      description: '印有六十秒网格的透明片，可把系统快照、本人点名和门禁经过时间放到同一条轴上。',
    ),
    'security_manifest': _InvestigationItem(
      id: 'security_manifest',
      name: '安保架与物资清单',
      asset: 'assets/images/items/vote/security_manifest.png',
      description: '总重量少了1.8公斤，界面将缺口自动归为一支控制棒，但空位轮廓被遮在托盘下面。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['security_take_gauge'],
          description: '软质轮廓尺已从架底取出。仅凭总重量仍无法判断缺少的是单件武器还是多件工具。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['security_take_gauge', 'security_rack_compare'],
          name: '三件组合工具的安保空位',
          asset: 'assets/images/items/vote/security_manifest_verified.png',
          description: '空位分别对应备用电芯、束缚带和门磁旁路片。三件物品分开并不显眼，组合后足以锁门并限制被困者反抗。',
        ),
      ],
    ),
    'rack_contour_gauge': _InvestigationItem(
      id: 'rack_contour_gauge',
      name: '软质轮廓尺',
      asset: 'assets/images/items/vote/rack_contour_gauge.png',
      description: '可贴合托盘压痕复原多个物件的外形，避免把相同总重量武断归为单件武器。',
    ),
    'project_approval_plate': _InvestigationItem(
      id: 'project_approval_plate',
      name: '酸洗项目审批板',
      asset: 'assets/images/items/core/project_approval_plate.png',
      description: '金属审批板上的姓名被溶剂擦除，斜光下只能看到断续压痕。夹槽里压着一张未使用的石墨转印膜。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['core_take_graphite'],
          description: '石墨转印膜已经取出。审批栏仍不能凭肉眼确认是人工签署还是系统套印。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['core_take_graphite', 'core_lift_approval'],
          name: '恢复笔压的项目审批板',
          asset: 'assets/images/items/core/project_approval_plate_revealed.png',
          description: '转印恢复出负责人笔压、个人印章序列与早于绑架四十七天的签署时间。H-7由人类预先授权。',
        ),
      ],
    ),
    'graphite_lifting_film': _InvestigationItem(
      id: 'graphite_lifting_film',
      name: '石墨转印膜',
      asset: 'assets/images/items/core/graphite_lifting_film.png',
      description: '一次性低黏转印膜，可显出金属表面残留笔压，不会恢复被酸洗掉的墨迹。',
    ),
    'replay_topology': _InvestigationItem(
      id: 'replay_topology',
      name: '三节点拓扑板',
      asset: 'assets/images/items/core/replay_topology.png',
      description: '体育馆、档案区与仓储环线之间只画了普通备份线，板后收纳着一支被动光纤示踪器。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['core_take_tracer'],
          description: '光纤示踪器已经取出。印刷线路无法解释三组节点为何每七秒轮流出现同一裁定心跳。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['core_take_tracer', 'core_trace_topology'],
          name: '显出迁移心跳的拓扑板',
          asset: 'assets/images/items/core/replay_topology_traced.png',
          description: '隐藏光路已经显现：三处不是独立备份，而是每七秒转交一次执行权的同一ZERO进程。',
        ),
      ],
    ),
    'fiber_tracer': _InvestigationItem(
      id: 'fiber_tracer',
      name: '被动光纤示踪器',
      asset: 'assets/images/items/core/fiber_tracer.png',
      description: '不向网络发送握手的低功率示踪器，只让真实连接路径短暂发光。',
    ),
    'participant_input_bus': _InvestigationItem(
      id: 'participant_input_bus',
      name: '参与者输入总线',
      asset: 'assets/images/items/core/participant_input_bus.png',
      description: '托管、投票、位置申诉与撤回请求在这里汇流，面板默认只显示“实验记录”。维护口卡着只读校验桥。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['core_take_bridge'],
          description: '只读校验桥已经取出。总线仍将观察日志与现场执行输出折叠在同一行里。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['core_take_bridge', 'core_decode_input_bus'],
          name: '分离执行输出的输入总线',
          asset: 'assets/images/items/core/participant_input_bus_decoded.png',
          description: '每条参与者签名都有第二路输出，直接进入门锁、项圈与区域封锁队列。选择不仅被观察，也被当作执行参数。',
        ),
      ],
    ),
    'checksum_bridge': _InvestigationItem(
      id: 'checksum_bridge',
      name: '只读校验桥',
      asset: 'assets/images/items/core/checksum_bridge.png',
      description: '双端硬件桥可把总线输出分流到离线屏幕，不具备写入和远程调用能力。',
    ),
    'weapon_cradle': _InvestigationItem(
      id: 'weapon_cradle',
      name: '未登记武器空槽',
      asset: 'assets/images/items/core/weapon_cradle.png',
      description: '泡棉槽中只剩短管、折叠托和气瓶卡扣的局部压痕，侧袋封着一包硅胶取形膜。',
      variants: [
        _InvestigationItemVariant(
          requiresActions: ['core_take_cast'],
          description: '硅胶取形膜已经取出。仅看局部凹痕，仍可能把工业工具误认成枪械。',
        ),
        _InvestigationItemVariant(
          requiresActions: ['core_take_cast', 'core_cast_weapon_slot'],
          name: '复原射钉器轮廓的空槽',
          asset: 'assets/images/items/core/weapon_cradle_cast.png',
          description: '凝固取形完整复原短管射钉器、折叠托与高压气瓶卡扣；导轨擦痕表明它在本次游戏开始后才被取走。',
        ),
      ],
    ),
    'silicone_cast_film': _InvestigationItem(
      id: 'silicone_cast_film',
      name: '硅胶取形膜',
      asset: 'assets/images/items/core/silicone_cast_film.png',
      description: '一次性低温取形材料，可复原泡棉深处的完整轮廓与导轨擦痕。',
    ),
  };

  static const _controlRoom = _InvestigationSpec(
    title: '现场调查 / A-02',
    targets: [
      _InvestigationTarget(
        id: 'terminal_area',
        initialLabel: '终端与地面',
        clueTitle: '距离矛盾',
        asset: 'assets/images/items/control_room/distance_terminal.png',
        prompt: '终端倒在尸体附近，地面有拖动痕迹。屏幕上的数字不能直接当作现场距离。',
        actions: [
          _InspectionAction(
            id: 'terminal_marks',
            label: '沿灰尘找原位',
            icon: Icons.gesture_rounded,
            result: '终端边角的灰尘轮廓没有中断，案发后没有被人挪到尸体附近。原位可以作为测量起点。',
          ),
          _InspectionAction(
            id: 'terminal_measure',
            label: '用折叠尺复原距离',
            icon: Icons.straighten_rounded,
            requiresItems: ['folding_ruler'],
            requiresActions: ['terminal_marks'],
            result: '折叠尺读数是 1.4m，裁定缓存却记录 23m。现实位置与系统收到的距离无法同时成立。',
            grantsItem: 'distance_record',
            verifiesClue: 'distance',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'wall_box',
        initialLabel: '墙边黑盒',
        clueTitle: '伪造信号的中继器',
        asset: 'assets/images/items/control_room/signal_repeater.png',
        prompt: '墙边黑盒没有铭牌，电源灯也不亮。仅凭外形无法判断它是否与死亡有关。',
        actions: [
          _InspectionAction(
            id: 'box_heat',
            label: '隔布触摸外壳',
            icon: Icons.thermostat_rounded,
            result: '断电设备仍有明显余温，散热孔附近还残留新鲜指纹。它不久前运行过。',
          ),
          _InspectionAction(
            id: 'box_open',
            label: '拆开屏蔽层',
            icon: Icons.build_rounded,
            requiresItems: ['insulated_pick'],
            requiresActions: ['box_heat'],
            consumesItems: ['insulated_pick'],
            result: '拨片撬开最后一道卡扣后断在屏蔽层内。新装模块接在终端定位频道上，缓存时间落在案发前三分钟，能够转发伪造的距离握手。',
            verifiesClue: 'repeater',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'collar_lock',
        initialLabel: '项圈锁扣',
        clueTitle: '规则阈值处决',
        asset: 'assets/images/items/control_room/collar_timer.png',
        prompt: '锁扣表面有焦痕，但爆裂点和金属受力方向并不一致。需要把机械状态与日志放在一起看。',
        actions: [
          _InspectionAction(
            id: 'collar_force',
            label: '检查锁舌与划痕',
            icon: Icons.manage_search_rounded,
            result: '锁舌没有撬压变形，外部划痕也没有延伸到触发片。它不是被强行拆除后引爆。',
          ),
          _InspectionAction(
            id: 'collar_compare',
            label: '对照实测与缓存',
            icon: Icons.rule_rounded,
            requiresItems: ['distance_record'],
            requiresActions: ['collar_force'],
            result: '距离异常在缓存中持续 181 秒，项圈于 180 秒阈值执行。死亡使用了规则内的计时触发。',
            verifiesClue: 'timer',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'tool_tray',
        initialLabel: '散开的工具盘',
        clueTitle: '公共工具盘',
        asset: 'assets/images/items/control_room/tool_tray.png',
        prompt: '工具盘里大多是普通维修件。它可能提供检查手段，也可能只是现场噪声。',
        actions: [
          _InspectionAction(
            id: 'tray_ruler',
            label: '取出折叠尺',
            icon: Icons.straighten_rounded,
            result: '分格底部卡着一把金属折叠尺，铰链正常，可以用于复原现场距离。',
            grantsItem: 'folding_ruler',
          ),
          _InspectionAction(
            id: 'tray_pick',
            label: '取出绝缘拨片',
            icon: Icons.build_rounded,
            result: '绝缘拨片仍在槽内，边缘没有金属屑。它适合安全拆开屏蔽层，但不能证明是谁装了黑盒。',
            grantsItem: 'insulated_pick',
          ),
          _InspectionAction(
            id: 'tray_prints',
            label: '寻找可辨指纹',
            icon: Icons.fingerprint_rounded,
            result: '表面被多人使用过，只有重叠污痕。继续把它当作身份线索只会制造错误指认。',
          ),
        ],
      ),
    ],
  );

  static const _gym = _InvestigationSpec(
    title: '封锁调查 / F-01',
    targets: [
      _InvestigationTarget(
        id: 'control_inner',
        initialLabel: '控制箱内侧',
        clueTitle: '诱导登记的桥接线',
        asset: 'assets/images/items/gym/shutter_control.png',
        prompt: '面板内部既有旧线路，也有颜色更亮的铜线。先区分维修遗留与刻意桥接。',
        actions: [
          _InspectionAction(
            id: 'control_trace',
            label: '追踪端子去向',
            icon: Icons.account_tree_outlined,
            result: '亮铜线没有绕过故障传感器，而是把“首次查看”连接到“登记操作者”。线长刚好能藏回面板。',
          ),
          _InspectionAction(
            id: 'control_replay',
            label: '离线复现输入',
            icon: Icons.electrical_services_rounded,
            requiresItems: ['offline_test_lead'],
            requiresActions: ['control_trace'],
            result: '控制页第一次开启后，十分钟撤权计时自动启动。桥接线专门把调查者登记成留守者。',
            verifiesClue: 'gym_control',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'north_door_floor',
        initialLabel: '北门下方',
        clueTitle: '当天剪断的制动索',
        asset: 'assets/images/items/gym/brake_cable.png',
        prompt: '地面混着断索、灰尘和旧封条。金属断裂可能是老化，也可能是人为切割。',
        actions: [
          _InspectionAction(
            id: 'cable_dust',
            label: '比对三处积灰',
            icon: Icons.blur_on_rounded,
            result: '滑轮槽有旧灰，断面却仍亮；金属碎屑只压在今天被移动的封条上。断裂发生在今天。',
          ),
          _InspectionAction(
            id: 'cable_marks',
            label: '放大断口压痕',
            icon: Icons.zoom_in_rounded,
            requiresItems: ['folding_magnifier'],
            requiresActions: ['cable_dust'],
            result: '钢索两侧各有一道角度相同的钳口压痕。自然断裂不会留下对称咬痕。',
            verifiesClue: 'gym_cable',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'empty_cradle',
        initialLabel: '缺失设备的底座',
        clueTitle: '12号离线握手',
        asset: 'assets/images/items/gym/terminal_cradle.png',
        prompt: '底座上没有终端，指示灯却每七秒闪一次。在线读取可能把主机回应误当成本地数据。',
        actions: [
          _InspectionAction(
            id: 'cradle_isolate',
            label: '切断外部网络',
            icon: Icons.link_off_rounded,
            result: '拔掉网络后，指示灯仍按七秒间隔闪烁。握手记录预先写在底座内部。',
          ),
          _InspectionAction(
            id: 'cradle_read',
            label: '读取本地握手',
            icon: Icons.memory_rounded,
            requiresItems: ['offline_test_lead'],
            requiresActions: ['cradle_isolate'],
            result: '底座反复发送“身份槽12、状态有效、距离0.0m”，让地图把空设备识别成场内参与者。',
            verifiesClue: 'gym_cradle',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'service_cart',
        initialLabel: '维修推车',
        clueTitle: '维修推车',
        asset: 'assets/images/items/gym/service_cart.png',
        prompt: '推车没有直接指向事故原因，但上面的工具可以把猜测变成可重复的检查。',
        actions: [
          _InspectionAction(
            id: 'cart_lead',
            label: '检查封存线材',
            icon: Icons.cable_rounded,
            result: '找到一条未接入设施网络的离线测试线，可以安全复现输入并读取本地缓存。',
            grantsItem: 'offline_test_lead',
          ),
          _InspectionAction(
            id: 'cart_lens',
            label: '翻找光学工具',
            icon: Icons.search_rounded,
            result: '抽屉底部有一枚折叠放大镜，镜面完整，足以分辨钢索上的细小钳口痕。',
            grantsItem: 'folding_magnifier',
          ),
        ],
      ),
    ],
  );

  static const _storage = _InvestigationSpec(
    title: '物资调查 / B-03',
    targets: [
      _InvestigationTarget(
        id: 'sealed_crate',
        initialLabel: '封好的水箱',
        clueTitle: '二次热压封条',
        asset: 'assets/images/items/storage/sealed_crate.png',
        prompt: '封条看起来完整，但纸纤维与胶层留下的痕迹并不一致。先确认异常发生在哪一层。',
        actions: [
          _InspectionAction(
            id: 'crate_seam',
            label: '沿封条检查纤维',
            icon: Icons.manage_search_rounded,
            result: '封条边缘没有普通撕裂产生的毛边，胶层中间却出现连续平滑带。有人可能整片取下过它。',
          ),
          _InspectionAction(
            id: 'crate_uv',
            label: '检查胶层热痕',
            icon: Icons.flashlight_on_outlined,
            requiresItems: ['uv_lamp'],
            requiresActions: ['crate_seam'],
            result: '紫外光下出现两层相反方向的胶纹和连续热痕。封条被低温取下，箱体打开后又被二次压回。',
            verifiesClue: 'seal_reclosed',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'locked_audit_pda',
        initialLabel: '墙面审计PDA',
        clueTitle: '撤销后的旧会话',
        asset: 'assets/images/items/storage/locked_audit_pda.png',
        prompt: '界面只显示01已确认。先判断时钟差是否足以解释操作时间，再考虑读取被折叠的字段。',
        actions: [
          _InspectionAction(
            id: 'pda_clock',
            label: '与公共频道校时',
            icon: Icons.more_time_rounded,
            result: '审计PDA只慢0.2秒，无法把09:16:03改写成09:16:48。侧面维护口仍保存本地缓存。',
          ),
          _InspectionAction(
            id: 'pda_log',
            label: '读取离线缓存',
            icon: Icons.memory_rounded,
            requiresItems: ['offline_reader'],
            requiresActions: ['pda_clock'],
            result: '缓存来源是早晨已经撤销的托管会话。控制器在撤销后四十二秒内仍接受它，并把持有者身份沿用为01。',
            grantsItem: 'handover_receipt',
            verifiesClue: 'delegation_gap',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'supply_shelf',
        initialLabel: '空位货架',
        clueTitle: '先减重后签名',
        asset: 'assets/images/items/storage/supply_shelf.png',
        prompt: '货架底部仍有机械承重结构。电子清单会被改写，机械位移却可能保存另一条时间线。',
        actions: [
          _InspectionAction(
            id: 'shelf_dust',
            label: '清理承重弹簧',
            icon: Icons.cleaning_services_outlined,
            result: '积灰下露出机械撞针和压纸，撞针在承重突变时会留下时间痕迹，但刻度尚未校准。',
          ),
          _InspectionAction(
            id: 'shelf_weight',
            label: '复核承重偏移',
            icon: Icons.scale_outlined,
            requiresItems: ['spring_scale'],
            requiresActions: ['shelf_dust'],
            result: '货架在09:16:03减轻26.4kg，01签名到09:16:48才生成。物资移动比电子确认早四十五秒。',
            verifiesClue: 'weight_mismatch',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'audit_case',
        initialLabel: '墙角工具箱',
        clueTitle: '离线审计工具',
        asset: 'assets/images/items/storage/audit_case.png',
        prompt: '箱内工具本身不能证明失窃者是谁，但能让不同物件留下的时间与材料痕迹互相校验。',
        actions: [
          _InspectionAction(
            id: 'case_uv',
            label: '取出紫外检验灯',
            icon: Icons.flashlight_on_outlined,
            result: '紫外检验灯电量充足，冷光不会进一步加热或破坏封条胶层。',
            grantsItem: 'uv_lamp',
          ),
          _InspectionAction(
            id: 'case_scale',
            label: '取出弹簧测力计',
            icon: Icons.scale_outlined,
            result: '机械测力计的零点封签完整，可以独立复核货架承重弹簧。',
            grantsItem: 'spring_scale',
          ),
          _InspectionAction(
            id: 'case_reader',
            label: '取出离线读取器',
            icon: Icons.usb_rounded,
            result: '读取器不会发送网络握手，只能复制本地字段，适合检查锁定的审计PDA。',
            grantsItem: 'offline_reader',
          ),
        ],
      ),
    ],
  );

  static const _medical = _InvestigationSpec(
    title: '医疗调查 / C-02',
    targets: [
      _InvestigationTarget(
        id: 'injection_infusion_set',
        initialLabel: '注射与输液器材',
        clueTitle: '无镇静剂投药路径',
        asset: 'assets/images/items/medical/injection_infusion_set.png',
        prompt: '外层包装已被打开，但不能因此假定注射已经完成。先检查无菌封与输液接口。',
        actions: [
          _InspectionAction(
            id: 'medical_inner_seal',
            label: '检查无菌内封与穿刺口',
            icon: Icons.biotech_outlined,
            result: '注射器内封没有针帽穿刺点，输液接口的防回流膜也完整。外包装被拆开不等于已经投药。',
          ),
          _InspectionAction(
            id: 'medical_residue_assay',
            label: '检验内壁与输液残液',
            icon: Icons.science_outlined,
            requiresItems: ['sedative_test_strip'],
            requiresActions: ['medical_inner_seal'],
            result: '标准样正常显色，注射器内壁与输液残液均为阴性。现场没有镇静剂通过这两条路径进入体内的痕迹。',
            grantsItem: 'medical_assay_card',
            verifiesClue: 'no_sedative_delivery',
            consumesItems: ['sedative_test_strip'],
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'triage_record',
        initialLabel: '分时检伤表',
        clueTitle: '前庭刺激型晕厥',
        asset: 'assets/images/items/medical/triage_record.png',
        prompt: '体征、主观感受与操作时间必须先按发生顺序排列，再与候选机制比较。',
        actions: [
          _InspectionAction(
            id: 'triage_timeline',
            label: '重建症状与操作时间线',
            icon: Icons.timeline_rounded,
            result: '耳鸣、右侧定向障碍和眼震早于意识丧失；拔掉右耳机两分钟后，意识与血压开始恢复。',
          ),
          _InspectionAction(
            id: 'triage_compare',
            label: '与镇静剂过量模式比对',
            icon: Icons.monitor_heart_outlined,
            requiresActions: ['triage_timeline'],
            result: '呼吸未受抑制，瞳孔等大，眼震与定向障碍随单侧暴露加重。记录更符合前庭感觉冲突引起的短暂晕厥。',
            verifiesClue: 'clinical_pattern',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'patient_headset',
        initialLabel: '双声道耳机',
        clueTitle: '右声道定向脉冲',
        asset: 'assets/images/items/medical/patient_headset.png',
        prompt: '星遥倒下前抓住右侧耳机。先比较左右线路，再在不发送握手的情况下捕获输出。',
        actions: [
          _InspectionAction(
            id: 'headset_channel_check',
            label: '分别检查左右声道缓存',
            icon: Icons.graphic_eq_rounded,
            result: '左右硬件完整，右侧输出缓存的写入频率却显著高于左侧。需要离线捕获实际频谱。',
          ),
          _InspectionAction(
            id: 'headset_spectrum',
            label: '对比左右声道频谱',
            icon: Icons.multiline_chart_rounded,
            requiresItems: ['offline_spectrum_clip'],
            requiresActions: ['headset_channel_check'],
            result: '右声道每七秒出现一组18.6kHz窄脉冲，左声道与空气麦克风均无对应信号。暴露沿PDA音频输出链定向发生。',
            grantsItem: 'headset_spectrum_capture',
            verifiesClue: 'directed_tone',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'medical_test_case',
        initialLabel: '床旁检验盒',
        clueTitle: '离线检验工具',
        asset: 'assets/images/items/medical/medical_test_case.png',
        prompt: '检验盒的封签完整，内部工具只用于验证材料与输出，不能直接指认持有者。',
        actions: [
          _InspectionAction(
            id: 'medical_case_strip',
            label: '取出药物检验试纸',
            icon: Icons.science_outlined,
            result: '试纸可将器材内壁、输液残液与标准样放在同一张卡上对照。',
            grantsItem: 'sedative_test_strip',
          ),
          _InspectionAction(
            id: 'medical_case_spectrum',
            label: '取出离线频谱夹',
            icon: Icons.headphones_outlined,
            result: '频谱夹只被动读取左右声道，不会向PDA或设施主机发送握手。',
            grantsItem: 'offline_spectrum_clip',
          ),
        ],
      ),
    ],
  );

  static const _archive = _InvestigationSpec(
    title: '档案复原 / E-04',
    targets: [
      _InvestigationTarget(
        id: 'archive_roster',
        initialLabel: '纸质绑架名册',
        clueTitle: '初始名单只有十一人',
        asset: 'assets/images/items/archive/archive_roster.png',
        prompt: '末页出现“12”不能直接证明第十二人存在。先核对装订连续性，再判断墨粉与锈斑的覆盖先后。',
        actions: [
          _InspectionAction(
            id: 'archive_roster_binding',
            label: '核对页码、骑缝章与指纹栏',
            icon: Icons.menu_book_outlined,
            result: '01至11的页码与骑缝章连续，每人都有指纹、药量和运输栏；末页12只有新打印编号。',
          ),
          _InspectionAction(
            id: 'archive_roster_overlay',
            label: '对齐墨粉、压痕与装订锈斑',
            icon: Icons.layers_outlined,
            requiresItems: ['date_overlay'],
            requiresActions: ['archive_roster_binding'],
            result: '斜纹片显示“12”的墨粉覆盖在装订锈斑之上，是绑架完成后补入的字段。',
            verifiesClue: 'initial_roster_11',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'archive_photo',
        initialLabel: '被涂改的员工合照',
        clueTitle: 'SLOT-12维护终端',
        asset: 'assets/images/items/archive/archive_photo.png',
        prompt: '黑墨遮住一块规则轮廓。不要先假定那是一名被抹除的人，先观察边缘与背面残签。',
        actions: [
          _InspectionAction(
            id: 'archive_photo_edges',
            label: '检查黑墨边缘与墙面螺孔',
            icon: Icons.photo_size_select_large_outlined,
            result: '遮挡区边缘笔直，底部有推车轮廓；尺寸与档案库墙上拆走设备后的螺孔一致。',
          ),
          _InspectionAction(
            id: 'archive_photo_light',
            label: '透照黑墨与背面资产签',
            icon: Icons.light_mode_outlined,
            requiresItems: ['transmitted_light'],
            requiresActions: ['archive_photo_edges'],
            result: '透射光显出一台测试终端，资产标签完整读作“SLOT-12 / MAINTENANCE”。',
            verifiesClue: 'slot12_asset_tag',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'access_backup',
        initialLabel: '门禁备份纸卷',
        clueTitle: '七秒跨区重放',
        asset: 'assets/images/items/archive/access_backup.png',
        prompt: '连续纸卷记录很多真实进出。先提取12号序列，再与设施实际步行时间叠合。',
        actions: [
          _InspectionAction(
            id: 'archive_access_sequence',
            label: '按身份槽提取连续握手',
            icon: Icons.receipt_long_outlined,
            result: '12号依次在F-01、C-02、E-04出现，相邻记录只差七秒；三个位置都装有固定底座。',
          ),
          _InspectionAction(
            id: 'archive_access_overlay',
            label: '叠合秒级时间与最短路线',
            icon: Icons.route_outlined,
            requiresItems: ['date_overlay'],
            requiresActions: ['archive_access_sequence'],
            result: '最短路线也需要九分钟。七秒切换无法来自一具连续移动的身体，只能是固定底座重放。',
            verifiesClue: 'slot12_impossible_travel',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'archive_server',
        initialLabel: '离线镜像与工具抽屉',
        clueTitle: '可切换的身份槽配置',
        asset: 'assets/images/items/archive/server_mirror.png',
        prompt: '先取出不会向主机发送握手的工具，再校验镜像；不要用联网终端直接打开配置。',
        actions: [
          _InspectionAction(
            id: 'archive_take_overlay',
            label: '取出年代斜纹片',
            icon: Icons.layers_outlined,
            result: '透明片可以比较纸张压痕、装订锈斑与热敏纸时间，但本身不提供结论。',
            grantsItem: 'date_overlay',
          ),
          _InspectionAction(
            id: 'archive_take_light',
            label: '取出冷光透射片',
            icon: Icons.light_mode_outlined,
            result: '低温背光不会进一步损伤相纸，可观察黑墨下仍保留的银盐影像。',
            grantsItem: 'transmitted_light',
          ),
          _InspectionAction(
            id: 'archive_take_checksum',
            label: '取出只读校验钥匙',
            icon: Icons.key_outlined,
            result: '硬件钥匙没有写入触点，只能验证镜像签名，无法把检查动作伪装成配置修改。',
            grantsItem: 'checksum_key',
          ),
          _InspectionAction(
            id: 'archive_server_checksum',
            label: '离线校验身份槽12配置',
            icon: Icons.verified_user_outlined,
            requiresItems: ['checksum_key'],
            requiresActions: [
              'archive_take_overlay',
              'archive_take_light',
              'archive_take_checksum',
            ],
            result: '镜像中没有12号个人档案，只有人数、托管与区域占用三项独立开关，修改由ZERO裁定进程签名。',
            verifiesClue: 'slot12_configurable_identity',
          ),
        ],
      ),
    ],
  );

  static const _vote = _InvestigationSpec(
    title: '投票设施审计 / CASE 05',
    targets: [
      _InvestigationTarget(
        id: 'ballot_packet',
        initialLabel: '实体票纸审计包',
        clueTitle: '一次草稿被提交两次',
        asset: 'assets/images/items/vote/ballot_packet.png',
        prompt: '两张票的内容完全相同。先区分纸张生成与内容生成，再判断它们是复制件还是沿不同槽位独立打印。',
        actions: [
          _InspectionAction(
            id: 'ballot_take_lamp',
            label: '取出封套侧袋中的检验灯',
            icon: Icons.flashlight_on_outlined,
            result: '检验灯以低角度照亮热敏纸，可读取微孔和压痕，不会暴露匿名持有人。',
            grantsItem: 'ballot_oblique_lamp',
          ),
          _InspectionAction(
            id: 'ballot_microholes',
            label: '叠合微孔与草稿摘要',
            icon: Icons.document_scanner_outlined,
            requiresItems: ['ballot_oblique_lamp'],
            requiresActions: ['ballot_take_lamp'],
            result: '两张票的槽位微孔不同，纸尾草稿摘要与生成时间却完全相同：一次输入沿两条路径各提交一次。',
            verifiesClue: 'ballot_single_draft',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'delegation_roll',
        initialLabel: '委托链热敏纸卷',
        clueTitle: '撤回未穿过第二层租约',
        asset: 'assets/images/items/vote/delegation_roll.png',
        prompt: '委托、转交和撤回都有真签名。不要只看界面最终状态，逐层检查每段会话何时真正失效。',
        actions: [
          _InspectionAction(
            id: 'delegation_take_reader',
            label: '拆下离线租约读取夹',
            icon: Icons.memory_outlined,
            result: '读取夹只显示授权根与本地失效时间，不读取匿名选择内容。',
            grantsItem: 'delegation_lease_reader',
          ),
          _InspectionAction(
            id: 'delegation_chain_trace',
            label: '逐层读取委托租约',
            icon: Icons.account_tree_outlined,
            requiresItems: ['delegation_lease_reader'],
            requiresActions: ['delegation_take_reader'],
            result: '原持有人撤回后立即恢复票权，第二层代理仍保留十分钟租约；同一授权根暂时拥有两条有效出口。',
            verifiesClue: 'stale_delegate_branch',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'location_board',
        initialLabel: '位置快照与点名板',
        clueTitle: '地图滞后十分钟',
        asset: 'assets/images/items/vote/location_board.png',
        prompt: '系统位置与本人点名都是真记录，但生成时间不同。先对齐分钟，再判断封锁警告会被送给谁。',
        actions: [
          _InspectionAction(
            id: 'location_take_overlay',
            label: '取下透明分钟叠片',
            icon: Icons.layers_outlined,
            result: '叠片能把快照、门禁经过与本人确认对齐到同一分钟。',
            grantsItem: 'position_time_overlay',
          ),
          _InspectionAction(
            id: 'location_superimpose',
            label: '叠合快照、门禁与点名',
            icon: Icons.my_location_outlined,
            requiresItems: ['position_time_overlay'],
            requiresActions: ['location_take_overlay'],
            result: '07与09的系统位置都落后十分钟。按旧快照执行时，一人会收到错误警告，另一人会被当作不在封锁区。',
            verifiesClue: 'location_snapshot_lag',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'security_manifest',
        initialLabel: '安保架与物资清单',
        clueTitle: '失踪的是一套组合工具',
        asset: 'assets/images/items/vote/security_manifest.png',
        prompt: '清单把重量缺口自动归为控制棒。先复原托盘轮廓，避免让总重量替物品形状作结论。',
        actions: [
          _InspectionAction(
            id: 'security_take_gauge',
            label: '取出架底软质轮廓尺',
            icon: Icons.straighten_outlined,
            result: '轮廓尺可贴合托盘压痕，分辨一个大物件与多个小物件。',
            grantsItem: 'rack_contour_gauge',
          ),
          _InspectionAction(
            id: 'security_rack_compare',
            label: '复原托盘空位轮廓',
            icon: Icons.inventory_2_outlined,
            requiresItems: ['rack_contour_gauge'],
            requiresActions: ['security_take_gauge'],
            result: '缺口对应电芯、束缚带和门磁旁路片，并非一支控制棒。它们组合后足以让门保持锁定并限制被困者。',
            verifiesClue: 'weapon_bundle_missing',
          ),
        ],
      ),
    ],
  );

  static const _core = _InvestigationSpec(
    title: '控制核心调查 / CASE 06',
    targets: [
      _InvestigationTarget(
        id: 'project_approval_plate',
        initialLabel: '酸洗审批板',
        clueTitle: '人类项目授权',
        asset: 'assets/images/items/core/project_approval_plate.png',
        prompt: '姓名已经被化学溶剂擦除。不要猜残存字形，先取得不会继续损伤表面的工具，再恢复笔压与印章顺序。',
        actions: [
          _InspectionAction(
            id: 'core_take_graphite',
            label: '检查夹槽并取出转印膜',
            icon: Icons.layers_outlined,
            result: '夹槽里有一张未使用的低黏石墨膜，能显出笔压，但需要和审批板组合才能产生结论。',
            grantsItem: 'graphite_lifting_film',
          ),
          _InspectionAction(
            id: 'core_lift_approval',
            label: '转印笔压与印章序列',
            icon: Icons.fingerprint_outlined,
            requiresItems: ['graphite_lifting_film'],
            requiresActions: ['core_take_graphite'],
            consumesItems: ['graphite_lifting_film'],
            result: '转印膜恢复出负责人手写笔压和个人印章序列，签署时间早于第一名参与者被绑架四十七天。',
            verifiesClue: 'human_project_authorization',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'replay_topology',
        initialLabel: '三节点拓扑板',
        clueTitle: '分布式ZERO心跳',
        asset: 'assets/images/items/core/replay_topology.png',
        prompt: '面板把三处设备画成普通备份。先找出不会触发联网握手的示踪工具，再观察真实光路的转交顺序。',
        actions: [
          _InspectionAction(
            id: 'core_take_tracer',
            label: '拆开板后维护筒',
            icon: Icons.cable_outlined,
            result: '维护筒里是一支被动光纤示踪器，只会让连接路径发光，不会向节点发出身份握手。',
            grantsItem: 'fiber_tracer',
          ),
          _InspectionAction(
            id: 'core_trace_topology',
            label: '追踪三处隐藏光路',
            icon: Icons.hub_outlined,
            requiresItems: ['fiber_tracer'],
            requiresActions: ['core_take_tracer'],
            consumesItems: ['fiber_tracer'],
            result: '体育馆、档案区和仓储环线每七秒转交同一裁定心跳；任一节点关闭，缺失片段都会由另外两处补回。',
            verifiesClue: 'distributed_zero_runtime',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'participant_input_bus',
        initialLabel: '参与者输入总线',
        clueTitle: '签名直达执行队列',
        asset: 'assets/images/items/core/participant_input_bus.png',
        prompt: '界面只显示实验记录，无法证明选择是否会改变现场。先取出只读桥，把观察输出和执行输出物理分开。',
        actions: [
          _InspectionAction(
            id: 'core_take_bridge',
            label: '解锁维护口的只读桥',
            icon: Icons.settings_input_component_outlined,
            result: '硬件桥没有写入针脚，可以把两路输出导向离线屏幕，不会替任何参与者提交新指令。',
            grantsItem: 'checksum_bridge',
          ),
          _InspectionAction(
            id: 'core_decode_input_bus',
            label: '分离观察与执行输出',
            icon: Icons.call_split_outlined,
            requiresItems: ['checksum_bridge'],
            requiresActions: ['core_take_bridge'],
            consumesItems: ['checksum_bridge'],
            result: '每条托管、投票与撤回签名都分成两路：一份存档，一份直接进入门锁、项圈和区域封锁队列。',
            verifiesClue: 'participant_execution_bus',
          ),
        ],
      ),
      _InvestigationTarget(
        id: 'weapon_cradle',
        initialLabel: '未登记武器空槽',
        clueTitle: '短管射钉器被取走',
        asset: 'assets/images/items/core/weapon_cradle.png',
        prompt: '泡棉只保留局部凹痕，不能凭外形直接叫它枪。先取得取形材料，再复原完整轮廓与最近擦痕。',
        actions: [
          _InspectionAction(
            id: 'core_take_cast',
            label: '拆开侧袋的取形材料',
            icon: Icons.texture_outlined,
            result: '侧袋中封着一次性低温硅胶膜，可进入泡棉深槽，凝固后完整保留外形。',
            grantsItem: 'silicone_cast_film',
          ),
          _InspectionAction(
            id: 'core_cast_weapon_slot',
            label: '复原深槽与导轨擦痕',
            icon: Icons.inventory_2_outlined,
            requiresItems: ['silicone_cast_film'],
            requiresActions: ['core_take_cast'],
            consumesItems: ['silicone_cast_film'],
            result: '凝固轮廓对应短管工业射钉器和高压气瓶。导轨内侧的新鲜擦痕证明它在本次游戏开始后才被取走。',
            verifiesClue: 'unregistered_weapon_cradle',
          ),
        ],
      ),
    ],
  );

  _InvestigationSpec get _spec => switch (widget.controller.currentId) {
    'ch2_gym_investigation' => _gym,
    'ch3_storage_investigation' => _storage,
    'ch4_medical_investigation' => _medical,
    'ch5_archive_investigation' => _archive,
    'ch6_vote_investigation' => _vote,
    'ch7_core_investigation' => _core,
    _ => _controlRoom,
  };

  Set<String> get _inventory => widget.controller.inventoryItems;
  Set<String> get _completedActions => widget.controller.investigationActions;
  Set<String> get _currentClueIds => _spec.targets
      .expand((target) => target.actions)
      .map((action) => action.verifiesClue)
      .whereType<String>()
      .toSet();
  Set<String> get _verifiedClues =>
      widget.controller.investigationClues.intersection(_currentClueIds);

  _InvestigationTarget? _targetFor(String id) {
    for (final spec in [
      _controlRoom,
      _gym,
      _storage,
      _medical,
      _archive,
      _vote,
      _core,
    ]) {
      for (final target in spec.targets) {
        if (target.id == id) return target;
      }
    }
    return null;
  }

  _InvestigationItem _resolvedItem(String id) {
    final base = _items[id]!;
    var name = base.name;
    var asset = base.asset;
    var description = base.description;
    for (final variant in base.variants) {
      if (variant.requiresActions.every(_completedActions.contains)) {
        name = variant.name ?? name;
        asset = variant.asset ?? asset;
        description = variant.description;
      }
    }
    return _InvestigationItem(
      id: base.id,
      name: name,
      asset: asset,
      description: description,
    );
  }

  void _toggleBackpack() {
    GameAudioScope.maybeOf(
      context,
    )?.playSfx(_backpackOpen ? GameSfx.pdaClose : GameSfx.pdaOpen);
    setState(() {
      _backpackOpen = !_backpackOpen;
      if (!_backpackOpen) {
        _activeItemId = null;
        _combineItemId = null;
      }
      _lastAction = null;
    });
  }

  void _collect(_InvestigationTarget target) {
    GameAudioScope.maybeOf(context)?.playSfx(GameSfx.itemPickup);
    widget.controller.collectInvestigationItem(target.id);
    setState(() {
      _feedback = '已收纳「${_resolvedItem(target.id).name}」，可从右侧打开背包查看。';
    });
  }

  void _openItem(String id) {
    final sourceId = _combineItemId;
    if (sourceId != null && sourceId != id) {
      final combined = _combine(sourceId, id);
      if (combined) setState(() => _combineItemId = null);
      return;
    }
    setState(() {
      _activeItemId = id;
      _lastAction = null;
      _feedback = null;
    });
  }

  void _runAction(_InspectionAction action) {
    if (_completedActions.contains(action.id)) {
      setState(() => _feedback = '这项检查已经完成。');
      return;
    }
    final missingItems = action.requiresItems
        .where((item) => !_inventory.contains(item))
        .toList(growable: false);
    final missingActions = action.requiresActions
        .where((id) => !_completedActions.contains(id))
        .toList(growable: false);
    if (missingItems.isNotEmpty || missingActions.isNotEmpty) {
      GameAudioScope.maybeOf(context)?.playSfx(GameSfx.combineFail);
      setState(() {
        _feedback = missingActions.isNotEmpty
            ? '这个物品还有未确认的细节，暂时无法完成组合。'
            : '现有物品还不足以完成这项操作。';
      });
      return;
    }
    setState(() {
      _lastAction = action;
      _feedback = action.result;
    });
    widget.controller.recordInvestigationAction(
      action.id,
      grantsItem: action.grantsItem,
      verifiesClue: action.verifiesClue,
      consumesItems: action.consumesItems,
    );
    final audio = GameAudioScope.maybeOf(context);
    if (action.verifiesClue != null) {
      audio?.playSfx(GameSfx.clueAcquired);
    } else if (action.grantsItem != null) {
      audio?.playSfx(GameSfx.itemPickup);
    } else if (action.requiresItems.isNotEmpty) {
      audio?.playSfx(GameSfx.combineSuccess);
    } else {
      audio?.playSfx(GameSfx.uiConfirm);
    }
    if (_activeItemId != null && !_inventory.contains(_activeItemId)) {
      setState(() => _activeItemId = null);
    }
    if (_combineItemId != null && !_inventory.contains(_combineItemId)) {
      setState(() => _combineItemId = null);
    }
  }

  bool _combine(String firstId, String secondId) {
    if (firstId == secondId) return false;

    _InvestigationTarget? resolvedTarget;
    _InspectionAction? resolvedAction;
    for (final pair in [
      (targetId: firstId, toolId: secondId),
      (targetId: secondId, toolId: firstId),
    ]) {
      final target = _targetFor(pair.targetId);
      if (target == null || !_items.containsKey(pair.toolId)) continue;
      final candidates = target.actions
          .where((action) => action.requiresItems.contains(pair.toolId))
          .toList(growable: false);
      if (candidates.isEmpty) continue;
      resolvedTarget = target;
      resolvedAction = candidates.firstWhere(
        (candidate) => !_completedActions.contains(candidate.id),
        orElse: () => candidates.first,
      );
      break;
    }

    if (resolvedTarget == null || resolvedAction == null) {
      GameAudioScope.maybeOf(context)?.playSfx(GameSfx.combineFail);
      setState(() => _feedback = '这两件物品无法组合。');
      return false;
    }

    setState(() {
      _activeItemId = resolvedTarget!.id;
      _lastAction = null;
    });
    _runAction(resolvedAction);
    return _completedActions.contains(resolvedAction.id);
  }

  @override
  Widget build(BuildContext context) {
    final targets = _spec.targets;
    const targetAlignments = [
      Alignment(-0.78, -0.48),
      Alignment(-0.26, 0.48),
      Alignment(0.32, -0.44),
      Alignment(0.78, 0.42),
    ];
    return Stack(
      children: [
        _TopBar(controller: widget.controller, title: _spec.title),
        Positioned.fill(
          child: SafeArea(
            minimum: EdgeInsets.fromLTRB(12, 56, 78, _backpackOpen ? 86 : 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 360;
                return Stack(
                  children: [
                    for (final (index, target) in targets.indexed)
                      if (!_inventory.contains(target.id))
                        Align(
                          alignment: targetAlignments[index],
                          child: _InvestigationGlint(
                            targetId: target.id,
                            tooltip: '收取调查点',
                            compact: compact,
                            onPressed: () => _collect(target),
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
        ),
        if (_backpackOpen &&
            _activeItemId != null &&
            _items.containsKey(_activeItemId) &&
            _inventory.contains(_activeItemId))
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 60, 82, 104),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: _InventoryDetailPanel(
                  key: ValueKey(_activeItemId),
                  item: _resolvedItem(_activeItemId!),
                  target: _targetFor(_activeItemId!),
                  completedActions: _completedActions,
                  lastAction: _lastAction,
                  onAction: _runAction,
                  selectedForCombine: _combineItemId == _activeItemId,
                  onSelectForCombine: () => setState(() {
                    _combineItemId = _activeItemId;
                    _activeItemId = null;
                    _feedback =
                        '已选中「${_resolvedItem(_combineItemId!).name}」。滚动背包并点击另一件物品尝试组合。';
                  }),
                  onClose: () => setState(() => _activeItemId = null),
                ),
              ),
            ),
          ),
        if (_backpackOpen)
          Align(
            key: const ValueKey('inventory-backpack-panel'),
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(14, 8, 82, 10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Container(
                  height: 86,
                  padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
                  decoration: BoxDecoration(
                    color: const Color(0xED101516),
                    border: Border.all(color: const Color(0xFF35433F)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.backpack_outlined,
                                  color: Color(0xFF8FC7B8),
                                  size: 15,
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  '背包',
                                  style: TextStyle(
                                    color: Color(0xFFF0EEE7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _combineItemId == null
                                        ? '点击查看 · 拖动或选中后跨页组合'
                                        : '组合中：${_resolvedItem(_combineItemId!).name}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF8C9994),
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                                if (_combineItemId != null)
                                  IconButton(
                                    key: const ValueKey(
                                      'inventory-cancel-combine',
                                    ),
                                    tooltip: '取消组合',
                                    visualDensity: VisualDensity.compact,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 26,
                                      height: 22,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: () => setState(() {
                                      _combineItemId = null;
                                      _feedback = null;
                                    }),
                                    icon: const Icon(
                                      Icons.link_off_rounded,
                                      size: 15,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: _inventory.isEmpty
                                  ? const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '点击场景中的亮点收取可疑物品',
                                        style: TextStyle(
                                          color: Color(0xFFB7C0BC),
                                          fontSize: 11,
                                        ),
                                      ),
                                    )
                                  : ScrollConfiguration(
                                      behavior:
                                          const _InventoryScrollBehavior(),
                                      child: ListView.separated(
                                        key: const ValueKey(
                                          'inventory-scroll-list',
                                        ),
                                        controller: _inventoryScrollController,
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(
                                          parent:
                                              AlwaysScrollableScrollPhysics(),
                                        ),
                                        itemCount: _items.values
                                            .where(
                                              (item) =>
                                                  _inventory.contains(item.id),
                                            )
                                            .length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(width: 6),
                                        itemBuilder: (context, index) {
                                          final baseItem = _items.values
                                              .where(
                                                (entry) => _inventory.contains(
                                                  entry.id,
                                                ),
                                              )
                                              .elementAt(index);
                                          final item = _resolvedItem(
                                            baseItem.id,
                                          );
                                          final target = _targetFor(item.id);
                                          final verified =
                                              target?.actions.any(
                                                (action) =>
                                                    action.verifiesClue !=
                                                        null &&
                                                    widget
                                                        .controller
                                                        .investigationClues
                                                        .contains(
                                                          action.verifiesClue,
                                                        ),
                                              ) ??
                                              false;
                                          return _InventoryItemCard(
                                            item: item,
                                            verified: verified,
                                            selectedForCombine:
                                                _combineItemId == item.id,
                                            onTap: () => _openItem(item.id),
                                            onCombine: (draggedId) =>
                                                _combine(draggedId, item.id),
                                          );
                                        },
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 105,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '已验证 ${_verifiedClues.length} / 3',
                              style: const TextStyle(
                                color: Color(0xFFF0D08F),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              width: double.infinity,
                              height: 34,
                              child: FilledButton.icon(
                                onPressed: _verifiedClues.length == 3
                                    ? () => widget.controller
                                          .completeInvestigation(_verifiedClues)
                                    : null,
                                icon: const Icon(
                                  Icons.fact_check_outlined,
                                  size: 16,
                                ),
                                label: const Text('完成'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_feedback != null && _activeItemId == null)
          SafeArea(
            minimum: EdgeInsets.fromLTRB(18, 60, 84, _backpackOpen ? 104 : 18),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: const Color(0xF0182020),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: Color(0xFF69A89D)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Text(
                    _feedback!,
                    style: const TextStyle(
                      color: Color(0xFFF2F3EE),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ),
        _RightControlRail(
          controller: widget.controller,
          playbackEnabled: false,
          backpackOpen: _backpackOpen,
          onBackpackPressed: _toggleBackpack,
        ),
      ],
    );
  }
}

class _InventoryScrollBehavior extends MaterialScrollBehavior {
  const _InventoryScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
  };
}

class _InventoryDetailPanel extends StatelessWidget {
  const _InventoryDetailPanel({
    super.key,
    required this.item,
    required this.target,
    required this.completedActions,
    required this.lastAction,
    required this.onAction,
    required this.selectedForCombine,
    required this.onSelectForCombine,
    required this.onClose,
  });

  final _InvestigationItem item;
  final _InvestigationTarget? target;
  final Set<String> completedActions;
  final _InspectionAction? lastAction;
  final ValueChanged<_InspectionAction> onAction;
  final bool selectedForCombine;
  final VoidCallback onSelectForCombine;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('inspection-result'),
      color: const Color(0xFF0C1112),
      elevation: 10,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFFD8A24A), width: 1.2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 82,
                    height: 82,
                    child: Image.asset(
                      item.asset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  color: Color(0xFFF0D08F),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: '关闭',
                              visualDensity: VisualDensity.compact,
                              onPressed: onClose,
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        Text(
                          lastAction?.result ?? item.description,
                          style: const TextStyle(
                            color: Color(0xFFF2F3EE),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: ValueKey('inventory-select-combine-${item.id}'),
                onPressed: selectedForCombine ? null : onSelectForCombine,
                icon: Icon(
                  selectedForCombine
                      ? Icons.check_rounded
                      : Icons.add_link_rounded,
                  size: 17,
                ),
                label: Text(selectedForCombine ? '已选作组合物' : '选作组合物'),
              ),
              if (target != null) ...[
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: target!.actions
                      .where((action) => action.requiresItems.isEmpty)
                      .map((action) {
                        final completed = completedActions.contains(action.id);
                        return OutlinedButton.icon(
                          key: ValueKey('inspection-action-${action.id}'),
                          onPressed: completed ? null : () => onAction(action),
                          icon: Icon(
                            completed ? Icons.check_rounded : action.icon,
                            size: 17,
                          ),
                          label: Text(action.label),
                        );
                      })
                      .toList(growable: false),
                ),
                if (target!.actions.any(
                  (action) => action.requiresItems.isNotEmpty,
                )) ...[
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    children: target!.actions
                        .where((action) => action.requiresItems.isNotEmpty)
                        .map((action) {
                          final completed = completedActions.contains(
                            action.id,
                          );
                          return Container(
                            key: ValueKey(
                              'inspection-combination-hint-${action.id}',
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: completed
                                  ? const Color(0x332E7065)
                                  : const Color(0x331D2625),
                              border: Border.all(
                                color: completed
                                    ? const Color(0xFF69A89D)
                                    : const Color(0xFF52605B),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  completed
                                      ? Icons.check_rounded
                                      : Icons.drag_indicator_rounded,
                                  size: 14,
                                  color: completed
                                      ? const Color(0xFF8FC7B8)
                                      : const Color(0xFFD8A24A),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  completed ? action.label : '可尝试与其他物品组合',
                                  style: const TextStyle(
                                    color: Color(0xFFD8DEDA),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ],
              ] else ...[
                const SizedBox(height: 9),
                const Text(
                  '长按或拖动这件物品到另一件物品上，尝试组合。',
                  style: TextStyle(color: Color(0xFF9EA9A4), fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InvestigationGlint extends StatefulWidget {
  const _InvestigationGlint({
    required this.targetId,
    required this.tooltip,
    required this.compact,
    required this.onPressed,
  });

  final String targetId;
  final String tooltip;
  final bool compact;
  final VoidCallback onPressed;

  @override
  State<_InvestigationGlint> createState() => _InvestigationGlintState();
}

class _InvestigationGlintState extends State<_InvestigationGlint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween(
      begin: 0.82,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 34.0 : 42.0;
    return Tooltip(
      message: widget.tooltip,
      child: ScaleTransition(
        scale: _scale,
        child: IconButton(
          key: ValueKey('investigation-glint-${widget.targetId}'),
          onPressed: widget.onPressed,
          style: IconButton.styleFrom(
            fixedSize: Size.square(size),
            backgroundColor: const Color(0x997A5A21),
            side: const BorderSide(color: Color(0xFFF0D08F), width: 1.2),
            shadowColor: const Color(0xFFD8A24A),
            elevation: 7,
          ),
          icon: Icon(
            Icons.flare_rounded,
            color: const Color(0xFFFFE2A0),
            size: size * 0.54,
          ),
        ),
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({
    required this.item,
    required this.verified,
    required this.selectedForCombine,
    required this.onTap,
    required this.onCombine,
  });

  final _InvestigationItem item;
  final bool verified;
  final bool selectedForCombine;
  final VoidCallback onTap;
  final ValueChanged<String> onCombine;

  @override
  Widget build(BuildContext context) {
    Widget card({required bool highlighted}) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 68,
        padding: const EdgeInsets.fromLTRB(4, 3, 4, 2),
        decoration: BoxDecoration(
          color: highlighted || selectedForCombine
              ? const Color(0xFF263A35)
              : const Color(0xFF171E1D),
          border: Border.all(
            color: highlighted || selectedForCombine
                ? const Color(0xFFF0D08F)
                : verified
                ? const Color(0xFF69A89D)
                : const Color(0xFF45524E),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Expanded(
              child: Image.asset(
                item.asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFDDE2DF), fontSize: 8.5),
            ),
          ],
        ),
      ),
    );

    return DragTarget<String>(
      key: ValueKey('inventory-drop-${item.id}'),
      onWillAcceptWithDetails: (details) => details.data != item.id,
      onAcceptWithDetails: (details) => onCombine(details.data),
      builder: (context, candidateData, rejectedData) =>
          LongPressDraggable<String>(
            key: ValueKey('inventory-item-${item.id}'),
            data: item.id,
            delay: const Duration(milliseconds: 300),
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: 72,
                height: 58,
                child: card(highlighted: true),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.28,
              child: card(highlighted: false),
            ),
            child: card(highlighted: candidateData.isNotEmpty),
          ),
    );
  }
}

class _TuningLayer extends StatefulWidget {
  const _TuningLayer({required this.controller, required this.game});

  final StoryController controller;
  final EchoSceneGame game;

  @override
  State<_TuningLayer> createState() => _TuningLayerState();
}

class _TuningLayerState extends State<_TuningLayer> {
  double _frequency = 6.55;
  int _phase = 0;

  bool get _frequencyLocked => (_frequency - 7.20).abs() <= 0.04;
  bool get _locked => _frequencyLocked && _phase == 3;

  @override
  void initState() {
    super.initState();
    widget.game.setTuning(active: true, frequency: _frequency);
  }

  @override
  void dispose() {
    widget.game.setTuning(active: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quality = (1 - ((_frequency - 7.2).abs() / 0.8)).clamp(0.0, 1.0);
    return Stack(
      children: [
        _TopBar(controller: widget.controller, title: '中继器解密 / R-CHANNEL'),
        Center(
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(18, 18, 82, 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                decoration: BoxDecoration(
                  color: const Color(0xF0121819),
                  border: Border.all(color: const Color(0xFF496159)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.settings_input_antenna_rounded,
                          color: Color(0xFF8FC7B8),
                        ),
                        const SizedBox(width: 9),
                        const Expanded(child: Text('中继频道 / 删除日志')),
                        Text(
                          '${_frequency.toStringAsFixed(2)} MHz',
                          style: const TextStyle(
                            color: Color(0xFFD8A24A),
                            fontSize: 19,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    LinearProgressIndicator(
                      value: quality,
                      minHeight: 3,
                      color: _frequencyLocked
                          ? const Color(0xFF8FC7B8)
                          : const Color(0xFFD8A24A),
                      backgroundColor: const Color(0xFF27312F),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _frequency,
                      min: 6.4,
                      max: 8,
                      divisions: 160,
                      label: _frequency.toStringAsFixed(2),
                      onChanged: (value) {
                        setState(() => _frequency = value);
                        widget.game.setTuning(active: true, frequency: value);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '同步相位 / 缺失脉冲每四拍重复',
                            style: TextStyle(
                              color: Color(0xFFAAB3AF),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        ...List.generate(
                          8,
                          (index) => Container(
                            width: 8,
                            height: index % 4 == 2 ? 5 : 16,
                            margin: const EdgeInsets.only(left: 4),
                            color: index % 4 == 2
                                ? const Color(0xFF4A5552)
                                : const Color(0xFF8FC7B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('01')),
                        ButtonSegment(value: 2, label: Text('02')),
                        ButtonSegment(value: 3, label: Text('03')),
                        ButtonSegment(value: 4, label: Text('04')),
                      ],
                      selected: _phase == 0 ? const {} : {_phase},
                      emptySelectionAllowed: true,
                      onSelectionChanged: (selection) {
                        setState(
                          () =>
                              _phase = selection.isEmpty ? 0 : selection.first,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _locked
                            ? widget.controller.completeTuning
                            : null,
                        icon: Icon(
                          _locked
                              ? Icons.lock_open_rounded
                              : Icons.lock_outline_rounded,
                        ),
                        label: Text(
                          _locked
                              ? '读取删除日志'
                              : !_frequencyLocked
                              ? '频率未同步'
                              : '选择缺失脉冲相位',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _RightControlRail(
          controller: widget.controller,
          playbackEnabled: false,
        ),
      ],
    );
  }
}

class _DeductionLayer extends StatefulWidget {
  const _DeductionLayer({required this.controller});

  final StoryController controller;

  @override
  State<_DeductionLayer> createState() => _DeductionLayerState();
}

class _DeductionLayerState extends State<_DeductionLayer> {
  late final List<({String id, IconData icon, String title, String body})>
  _orderedEvidence;
  late final List<(String, String, String)> _orderedHypotheses;
  String? _selected;
  final Map<String, String?> _chain = {
    'fact': null,
    'threshold': null,
    'mechanism': null,
  };
  String _activeRole = 'fact';
  bool _chainVerified = false;
  String? _chainFeedback;

  bool get _isCase02 => widget.controller.currentId == 'ch3_case02_deduction';
  bool get _isCase03 => widget.controller.currentId == 'ch4_case03_deduction';
  bool get _isCase04 => widget.controller.currentId == 'ch5_case04_deduction';
  bool get _isCase05 => widget.controller.currentId == 'ch6_case05_deduction';
  bool get _isCase06 => widget.controller.currentId == 'ch7_case06_deduction';

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _orderedEvidence = List.of(_evidence)..shuffle(random);
    _orderedHypotheses = List.of(_hypotheses)..shuffle(random);

    final correctIds = _correctChain.values.toSet();
    final leadingCorrect = _orderedEvidence
        .take(3)
        .where((item) => correctIds.contains(item.id))
        .length;
    if (leadingCorrect == 3) {
      final distractorIndex = _orderedEvidence.indexWhere(
        (item) => !correctIds.contains(item.id),
        3,
      );
      final swapIndex = random.nextInt(3);
      final displaced = _orderedEvidence[swapIndex];
      _orderedEvidence[swapIndex] = _orderedEvidence[distractorIndex];
      _orderedEvidence[distractorIndex] = displaced;
    }
  }

  List<({String id, String title, String prompt})> get _roles => _isCase06
      ? const [
          (id: 'fact', title: '项目起点', prompt: '确认绑架与项圈部署由谁预先授权'),
          (id: 'threshold', title: '现场裁定', prompt: '找出负责人不在场时什么仍能持续执行'),
          (id: 'mechanism', title: '续写输入', prompt: '说明参与者选择怎样进入门锁与项圈'),
        ]
      : _isCase05
      ? const [
          (id: 'fact', title: '生成事实', prompt: '确认相同内容究竟被输入了几次'),
          (id: 'threshold', title: '权限分叉', prompt: '找出一份票权何时同时拥有两条有效路径'),
          (id: 'mechanism', title: '致命后果', prompt: '说明系统为何会把错误票数变成封锁风险'),
        ]
      : _isCase04
      ? const [
          (id: 'fact', title: '初始实体', prompt: '确认绑架开始时有多少组完整的人身记录'),
          (id: 'threshold', title: '连续身体', prompt: '判断12号的区域移动是否可能由同一人完成'),
          (id: 'mechanism', title: '系统身份', prompt: '说明服务器究竟为12号保存了什么'),
        ]
      : _isCase03
      ? const [
          (id: 'fact', title: '身体反应', prompt: '先确认昏厥前后出现了哪组体征'),
          (id: 'threshold', title: '暴露媒介', prompt: '找出症状加重前什么只作用于患者'),
          (id: 'mechanism', title: '排除路径', prompt: '确认失踪药物是否真的进入了体内'),
        ]
      : _isCase02
      ? const [
          (id: 'fact', title: '现场动作', prompt: '确认物资是否真实移动，以及动作发生的先后'),
          (id: 'threshold', title: '授权窗口', prompt: '找出撤销为何没有立刻终止门禁会话'),
          (id: 'mechanism', title: '责任归属', prompt: '解释最终署名为何晚于现场动作出现'),
        ]
      : const [
          (id: 'fact', title: '现场事实', prompt: '找出肉眼与系统记录无法同时成立的事实'),
          (id: 'threshold', title: '规则阈值', prompt: '说明项圈为何会把异常当作合法处决条件'),
          (id: 'mechanism', title: '实施媒介', prompt: '指出什么装置能把伪造数据送进裁定链'),
        ];

  List<({String id, IconData icon, String title, String body})> get _evidence =>
      _isCase06
      ? const [
          (
            id: 'human_project_authorization',
            icon: Icons.approval_outlined,
            title: '早于绑架的人类授权',
            body: '负责人手写笔压与个人印章在绑架前四十七天批准H-7部署',
          ),
          (
            id: 'distributed_zero_runtime',
            icon: Icons.hub_outlined,
            title: '跨三节点迁移的ZERO',
            body: '裁定心跳每七秒转交，关闭一处会由另外两处补回缺失片段',
          ),
          (
            id: 'participant_execution_bus',
            icon: Icons.call_split_outlined,
            title: '参与者签名直达执行队列',
            body: '托管、投票与撤回同时写入实验记录、门锁、项圈和区域封锁',
          ),
          (
            id: 'unregistered_weapon_cradle',
            icon: Icons.inventory_2_outlined,
            title: '被取走的短管射钉器',
            body: '证明现场能力已经变化，却不能说明谁批准实验或ZERO如何持续运行',
          ),
          (
            id: 'acid_erased_names',
            icon: Icons.format_clear_outlined,
            title: '七个被酸洗的姓名',
            body: '能确认有人试图隐藏身份，残缺字形本身不足以重建完整责任链',
          ),
          (
            id: 'slot12_white_signal',
            icon: Icons.radio_button_checked,
            title: '12号白点仍在线',
            body: '说明维护槽还能重放，不能单独回答系统由人、程序还是参与者主持',
          ),
        ]
      : _isCase05
      ? const [
          (
            id: 'ballot_single_draft',
            icon: Icons.ballot_outlined,
            title: '一次输入、两次有效提交',
            body: '两张实体票微孔不同，却共享唯一草稿摘要与生成时间',
          ),
          (
            id: 'stale_delegate_branch',
            icon: Icons.account_tree_outlined,
            title: '撤回未穿过第二层租约',
            body: '本人票权恢复时，末端代理仍保留十分钟有效会话',
          ),
          (
            id: 'location_snapshot_lag',
            icon: Icons.my_location_outlined,
            title: '滞后十分钟的位置快照',
            body: '封锁系统会向旧位置发送警告，并把当前在场者当作已离开',
          ),
          (
            id: 'weapon_bundle_missing',
            icon: Icons.inventory_2_outlined,
            title: '三件组合工具失踪',
            body: '电芯、束缚带与门磁片能放大封锁后果，但不会增加票数',
          ),
          (
            id: 'matching_typo',
            icon: Icons.spellcheck_outlined,
            title: '两张票有相同错别字',
            body: '能证明内容同源，不能单独证明由谁提交或为何被计作两票',
          ),
          (
            id: 'different_slot_holes',
            icon: Icons.more_horiz_rounded,
            title: '匿名槽与委托槽微孔',
            body: '证明两张纸分别打印，单独看仍无法解释授权根是否相同',
          ),
        ]
      : _isCase04
      ? const [
          (
            id: 'initial_roster_11',
            icon: Icons.menu_book_outlined,
            title: '连续的十一组绑架记录',
            body: '01至11有指纹、药量与运输栏，12为事后补印',
          ),
          (
            id: 'slot12_impossible_travel',
            icon: Icons.route_outlined,
            title: '七秒跨越三处区域',
            body: '最短步行九分钟，三个固定底座依次发出握手',
          ),
          (
            id: 'slot12_configurable_identity',
            icon: Icons.settings_input_component_outlined,
            title: '三项可切换配置',
            body: '只有人数、托管与区域开关，没有个人档案',
          ),
          (
            id: 'slot12_asset_tag',
            icon: Icons.badge_outlined,
            title: 'SLOT-12资产标签',
            body: '旧合照中被涂黑的是推车式维护终端',
          ),
          (
            id: 'missing_wall_mount',
            icon: Icons.crop_square_outlined,
            title: '墙面设备拆除印记',
            body: '螺孔尺寸与旧照片里的测试设备相符',
          ),
          (
            id: 'white_signal_online',
            icon: Icons.radio_button_checked,
            title: '12号白点持续在线',
            body: '白点在多个区域出现，但在线本身不能证明实体存在',
          ),
        ]
      : _isCase03
      ? const [
          (
            id: 'clinical_pattern',
            icon: Icons.monitor_heart_outlined,
            title: '眼震与定向障碍',
            body: '呼吸未受抑制，症状随右侧定向刺激加重',
          ),
          (
            id: 'directed_tone',
            icon: Icons.headphones_outlined,
            title: '右声道18.6kHz脉冲',
            body: '每七秒进入星遥耳机，左声道与空气中都没有',
          ),
          (
            id: 'no_sedative_delivery',
            icon: Icons.vaccines_outlined,
            title: '无穿刺与阴性残液',
            body: '注射器内封未穿破，输液残液未检出镇静剂',
          ),
          (
            id: 'missing_ampoule',
            icon: Icons.medication_liquid_outlined,
            title: '镇静剂缺失',
            body: '药柜少一支完整安瓿，取出时间仍无法确定',
          ),
          (
            id: 'dirty_filter',
            icon: Icons.air_outlined,
            title: '换气滤网积灰',
            body: '风量下降但仍在安全范围，其他人没有同步症状',
          ),
          (
            id: 'opened_wrapper',
            icon: Icons.inventory_2_outlined,
            title: '拆开的注射器外包',
            body: '外层包装已打开，但内部无菌封仍保持完整',
          ),
        ]
      : _isCase02
      ? const [
          (
            id: 'seal_reclosed',
            icon: Icons.inventory_2_outlined,
            title: '二次热压封条',
            body: '证明物资箱确实被人打开并重新封好',
          ),
          (
            id: 'delegation_gap',
            icon: Icons.timer_outlined,
            title: '撤销后 42 秒',
            body: '旧托管会话仍被门禁控制器接受',
          ),
          (
            id: 'weight_mismatch',
            icon: Icons.scale_outlined,
            title: '先减重后签名',
            body: '物资移动比01电子确认早45秒',
          ),
          (
            id: 'owner_signature',
            icon: Icons.draw_outlined,
            title: '01真实签名',
            body: '库存清单保留完整的01加密签名，生成于09:16:48',
          ),
          (
            id: 'trustee_skill',
            icon: Icons.terminal_rounded,
            title: '受托人懂接口',
            body: '早晨的受托人读过接口说明，并完成过一次公开操作',
          ),
          (
            id: 'missing_supplies',
            icon: Icons.water_drop_outlined,
            title: '物资出现缺口',
            body: '十二份水、六支止痛剂与两组滤芯不在原货位',
          ),
        ]
      : const [
          (
            id: 'distance',
            icon: Icons.social_distance_rounded,
            title: '1.4m / 23m',
            body: '现实距离与回传距离冲突',
          ),
          (
            id: 'timer',
            icon: Icons.timer_outlined,
            title: '180 秒',
            body: '项圈按规则阈值精确执行',
          ),
          (
            id: 'repeater',
            icon: Icons.settings_input_antenna_rounded,
            title: '中继器',
            body: '断电设备在案发时工作',
          ),
          (
            id: 'log',
            icon: Icons.data_object_rounded,
            title: '181 秒日志',
            body: '定位频道连续181秒返回超出两米的距离数据',
          ),
          (
            id: 'lock',
            icon: Icons.lock_outline_rounded,
            title: '完整锁舌',
            body: '项圈锁舌没有撬压变形，爆裂前仍处于闭合状态',
          ),
          (
            id: 'camera',
            icon: Icons.videocam_off_outlined,
            title: '监控空白',
            body: 'A-02监控在案发前三分钟失去画面，音轨仍连续',
          ),
        ];

  List<(String, String, String)> get _hypotheses => _isCase06
      ? const [
          (
            'human_director_only',
            '项目负责人是唯一主办者',
            '人类批准绑架与部署，因此现场程序和参与者输入都只是没有独立责任的工具。',
          ),
          (
            'autonomous_zero_only',
            'ZERO程序是唯一主办者',
            '分布式程序持续裁定一切，人类授权与参与者签名都不再影响当前责任。',
          ),
          (
            'protocol_three_layer_host',
            '三层共同维持零点协议',
            '人类设计起点、ZERO迁移裁定、参与者可执行选择持续输入；三层责任不相等，也不能互相抹除。',
          ),
        ]
      : _isCase05
      ? const [
          ('coordinated_ballots', '两名参与者串通投出同文票', '两个人预先共享了草稿，因此两张相同选票同时进入票箱。'),
          ('stale_location_only', '位置缓存制造了额外票数', '十分钟前的位置快照让系统重复计算了移动中的参与者。'),
          (
            'delegation_branch_replay',
            '撤回不完整造成委托分叉',
            '本人路径已恢复，末端代理租约却未失效，同一授权根沿两条路径调用同一草稿。',
          ),
        ]
      : _isCase04
      ? const [
          ('hidden_person', '被隐藏的第十二名参与者', '12号是被主办方删除姓名、藏在设施深处的真人。'),
          ('deleted_participant', '已死亡后继续使用的编号', '12号曾是参与者，死亡后其终端仍被系统当作在线身份。'),
          (
            'maintenance_slot',
            '可重放的维护身份槽',
            '12号没有对应身体，由多个底座重放并被选择性计入人数、托管与区域。',
          ),
        ]
      : _isCase03
      ? const [
          ('sedative_poisoning', '镇静剂投药', '失踪药物被用在星遥身上，高频只是与昏厥同时出现。'),
          ('air_contamination', '换气污染导致昏厥', '隔离病房的风管向室内输送了未知刺激物。'),
          ('directed_resonance', '定向音频诱发晕厥', '特定耳机收到持续脉冲，引发前庭感觉冲突；药物失踪是独立事件。'),
        ]
      : _isCase02
      ? const [
          ('owner_action', '01本人自愿转移', '最终电子签名真实，因此物资一定由01本人授权移走。'),
          ('trustee_action', '受托人亲自窃取', '拥有过01权限的人利用技术能力完成了全部操作。'),
          ('lease_replay', '重放已撤销会话', '未知设备重放旧授权，让控制器把操作继续归到01名下。'),
        ]
      : const [
          ('suicide', '主动离开终端', '10 号为了满足自己的条件而自杀。'),
          ('swap', '终端被交换', '凶手把另一台终端放在死者身边制造假距离。'),
          ('repeater', '中继器伪造定位', '凶手转发了距离握手，让项圈在规则内执行死刑。'),
        ];

  Map<String, String> get _correctChain => _isCase06
      ? const {
          'fact': 'human_project_authorization',
          'threshold': 'distributed_zero_runtime',
          'mechanism': 'participant_execution_bus',
        }
      : _isCase05
      ? const {
          'fact': 'ballot_single_draft',
          'threshold': 'stale_delegate_branch',
          'mechanism': 'location_snapshot_lag',
        }
      : _isCase04
      ? const {
          'fact': 'initial_roster_11',
          'threshold': 'slot12_impossible_travel',
          'mechanism': 'slot12_configurable_identity',
        }
      : _isCase03
      ? const {
          'fact': 'clinical_pattern',
          'threshold': 'directed_tone',
          'mechanism': 'no_sedative_delivery',
        }
      : _isCase02
      ? const {
          'fact': 'seal_reclosed',
          'threshold': 'delegation_gap',
          'mechanism': 'weight_mismatch',
        }
      : const {
          'fact': 'distance',
          'threshold': 'timer',
          'mechanism': 'repeater',
        };

  void _assignEvidence(String evidenceId) {
    setState(() {
      String? assignedRole;
      for (final role in _chain.keys) {
        if (_chain[role] == evidenceId) assignedRole = role;
      }
      _chainVerified = false;
      _selected = null;
      _chainFeedback = null;
      if (assignedRole != null) {
        _chain[assignedRole] = null;
        _activeRole = assignedRole;
        return;
      }
      _chain[_activeRole] = evidenceId;
      final emptyRoles = _chain.entries.where((entry) => entry.value == null);
      if (emptyRoles.isNotEmpty) _activeRole = emptyRoles.first.key;
    });
  }

  void _verifyChain() {
    final verified = _correctChain.entries.every(
      (entry) => _chain[entry.key] == entry.value,
    );
    GameAudioScope.maybeOf(
      context,
    )?.playSfx(verified ? GameSfx.clueAcquired : GameSfx.combineFail);
    setState(() {
      _chainVerified = verified;
      _chainFeedback = verified
          ? _isCase06
                ? '证据链闭合：人类授权创造实验，ZERO跨节点维持裁定，参与者签名又作为执行参数持续进入系统；三层共同让游戏继续运作。'
                : _isCase05
                ? '证据链闭合：内容只生成一次，撤回却没有终止末端代理；同一授权根因此提交两票，并由滞后位置快照把票数错误变成封锁风险。'
                : _isCase04
                ? '证据链闭合：初始绑架链只有十一人，12号无法对应连续身体，服务器也只保存可切换的维护身份配置。'
                : _isCase03
                ? '证据链闭合：体征符合定向感觉冲突，脉冲只进入右声道，现场也没有镇静剂进入体内的路径。'
                : _isCase02
                ? '证据链闭合：物资真实移动，旧会话在撤销后仍可用，系统随后把签名归到01名下。'
                : '证据链闭合：现实距离被伪造，异常跨过规则阈值，并由中继器送入裁定频道。'
          : '三项记录彼此真实，但目前的排列没有形成连续的时间与因果关系。换一个位置，再检查每一步究竟发生在前还是后。';
      if (!verified) _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xED080B0C),
      child: Stack(
        children: [
          _TopBar(
            controller: widget.controller,
            title: _isCase06
                ? '主办者结构 / CASE 06'
                : _isCase05
                ? '投票推演 / CASE 05'
                : _isCase04
                ? '身份推演 / CASE 04'
                : _isCase03
                ? '医学推演 / CASE 03'
                : _isCase02
                ? '权限推演 / CASE 02'
                : '规则推演 / CASE 01',
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(18, 76, 82, 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Eyebrow(text: 'BUILD THE ARGUMENT'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: _roles
                            .map((role) {
                              final evidenceId = _chain[role.id];
                              final evidence = evidenceId == null
                                  ? null
                                  : _orderedEvidence.singleWhere(
                                      (item) => item.id == evidenceId,
                                    );
                              return _ChainSlot(
                                title: role.title,
                                prompt: role.prompt,
                                evidenceTitle: evidence?.title,
                                active: _activeRole == role.id,
                                onPressed: () => setState(() {
                                  _activeRole = role.id;
                                  _chainVerified = false;
                                }),
                              );
                            })
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 16),
                      const _Eyebrow(text: 'EVIDENCE BOARD'),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: _orderedEvidence
                            .map((item) {
                              String? assignedRole;
                              for (final role in _roles) {
                                if (_chain[role.id] == item.id) {
                                  assignedRole = role.title;
                                }
                              }
                              return _EvidenceCard(
                                key: ValueKey('deduction-evidence-${item.id}'),
                                icon: item.icon,
                                title: item.title,
                                body: item.body,
                                selected: assignedRole != null,
                                assignedRole: assignedRole,
                                onPressed: () => _assignEvidence(item.id),
                              );
                            })
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _chainFeedback ??
                                  '选择上方论证位置，再从证据板放入一项记录。每项都是真实信息，但在因果链中承担的作用可能不同。',
                              style: TextStyle(
                                color: _chainFeedback == null
                                    ? const Color(0xFF9EA9A4)
                                    : _chainVerified
                                    ? const Color(0xFF8FC7B8)
                                    : const Color(0xFFF0D08F),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed:
                                _chain.values.every((value) => value != null)
                                ? _verifyChain
                                : null,
                            icon: const Icon(Icons.schema_outlined),
                            label: const Text('检验证据链'),
                          ),
                        ],
                      ),
                      if (_chainVerified) ...[
                        const SizedBox(height: 22),
                        _Eyebrow(
                          text: _isCase06
                              ? 'WHO KEEPS THE PROTOCOL RUNNING'
                              : _isCase05
                              ? 'WHY ONE VOTE BECAME TWO'
                              : _isCase04
                              ? 'IDENTITY OF SLOT 12'
                              : _isCase03
                              ? 'CAUSE OF SYNCOPE'
                              : _isCase02
                              ? 'OPERATION OWNERSHIP'
                              : 'CAUSE OF EXECUTION',
                        ),
                        const SizedBox(height: 9),
                        ..._orderedHypotheses.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _HypothesisTile(
                              key: ValueKey('deduction-hypothesis-${item.$1}'),
                              title: item.$2,
                              body: item.$3,
                              selected: _selected == item.$1,
                              onPressed: () => setState(
                                () => _selected = _selected == item.$1
                                    ? null
                                    : item.$1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _selected == null
                                ? null
                                : () {
                                    GameAudioScope.maybeOf(
                                      context,
                                    )?.playSfx(GameSfx.uiConfirm);
                                    widget.controller.submitDeduction(
                                      _selected!,
                                    );
                                  },
                            icon: const Icon(Icons.gavel_outlined),
                            label: Text(
                              _isCase06
                                  ? '提交主办者结构'
                                  : _isCase05
                                  ? '提交重复投票机制'
                                  : _isCase04
                                  ? '提交12号身份判断'
                                  : _isCase03
                                  ? '提交昏厥机制'
                                  : _isCase02
                                  ? '提交操作归属'
                                  : '提交死因推演',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          _RightControlRail(
            controller: widget.controller,
            playbackEnabled: false,
          ),
        ],
      ),
    );
  }
}

class _ChainSlot extends StatelessWidget {
  const _ChainSlot({
    required this.title,
    required this.prompt,
    required this.evidenceTitle,
    required this.active,
    required this.onPressed,
  });

  final String title;
  final String prompt;
  final String? evidenceTitle;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 304,
      height: 86,
      child: Material(
        color: active ? const Color(0xFF1D2D29) : const Color(0xFF121819),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: active ? const Color(0xFFD8A24A) : const Color(0xFF35433F),
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                Icon(
                  evidenceTitle == null
                      ? Icons.add_circle_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: active
                      ? const Color(0xFFF0D08F)
                      : const Color(0xFF8FC7B8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 3),
                      Text(
                        evidenceTitle ?? prompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: evidenceTitle == null
                              ? const Color(0xFF9EA9A4)
                              : const Color(0xFFF2F3EE),
                          fontSize: evidenceTitle == null ? 11 : 14,
                          fontWeight: evidenceTitle == null
                              ? FontWeight.w400
                              : FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.assignedRole,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final String? assignedRole;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 228,
      height: 112,
      child: Material(
        color: selected ? const Color(0xFF1D2D29) : const Color(0xFF151C1C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: selected ? const Color(0xFF69A89D) : const Color(0xFF3A4945),
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      selected ? Icons.check_circle_rounded : icon,
                      size: 18,
                      color: selected
                          ? const Color(0xFF8FC7B8)
                          : const Color(0xFFD8A24A),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  assignedRole == null ? body : '$assignedRole · $body',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFADB7B2),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HypothesisTile extends StatelessWidget {
  const _HypothesisTile({
    super.key,
    required this.title,
    required this.body,
    required this.selected,
    required this.onPressed,
  });

  final String title;
  final String body;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF1D2D29) : const Color(0xFF121819),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: selected ? const Color(0xFF69A89D) : const Color(0xFF35433F),
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? const Color(0xFF8FC7B8)
                    : const Color(0xFF7F8B87),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: const TextStyle(
                        color: Color(0xFFAAB3AF),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestimonyLayer extends StatefulWidget {
  const _TestimonyLayer({required this.controller});

  final StoryController controller;

  @override
  State<_TestimonyLayer> createState() => _TestimonyLayerState();
}

class _TestimonyLayerState extends State<_TestimonyLayer> {
  String? _selected;

  static const _answers = [
    (
      id: 'human_director',
      title: 'H-7 项目负责人',
      body: '把主办者定义为批准绑架、设施与项圈部署的人类设计者。',
      icon: Icons.fingerprint_rounded,
    ),
    (
      id: 'zero_system',
      title: 'ZERO 裁定系统',
      body: '把主办者定义为跨节点迁移、持续执行门锁与项圈裁定的程序。',
      icon: Icons.hub_outlined,
    ),
    (
      id: 'zero_protocol',
      title: '零点协议',
      body: '区分人类设计、程序裁定与参与者可执行输入，并保留三层不同责任。',
      icon: Icons.account_tree_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xF2080B0C),
      child: Stack(
        children: [
          _TopBar(controller: widget.controller, title: '隔离证词 / FINAL'),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(18, 76, 82, 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = constraints.maxWidth > 980
                    ? 980.0
                    : constraints.maxWidth;
                final compact = contentWidth < 760;
                final seatWidth = compact
                    ? (contentWidth - 10) / 2
                    : (contentWidth - 30) / 4;
                final answerWidth = compact
                    ? contentWidth
                    : (contentWidth - 20) / 3;
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Eyebrow(text: 'FOUR INDEPENDENT WITNESSES'),
                          const SizedBox(height: 7),
                          Text(
                            '提交主办者代号',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            '四席屏幕相互隔离。当前终端只记录 01 的答案，不能查看、复制或代交其他席位。',
                            style: TextStyle(
                              color: Color(0xFFAAB3AF),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: List.generate(
                              4,
                              (index) => SizedBox(
                                width: seatWidth,
                                height: compact ? 72 : 82,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xD8111718),
                                    border: Border.all(
                                      color: const Color(0xFF33413D),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(11),
                                    child: Row(
                                      children: [
                                        Icon(
                                          index == 0
                                              ? Icons.person_outline_rounded
                                              : Icons.lock_outline_rounded,
                                          color: index == 0
                                              ? const Color(0xFFD8A24A)
                                              : const Color(0xFF83908B),
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '证词席 ${index + 1}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                index == 0
                                                    ? '01 / 本人输入'
                                                    : '隔离中 / 不可见',
                                                style: const TextStyle(
                                                  color: Color(0xFF8F9B96),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const _Eyebrow(text: 'HOST IDENTIFIER'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _answers
                                .map(
                                  (answer) => SizedBox(
                                    width: answerWidth,
                                    child: _TestimonyAnswerCard(
                                      key: ValueKey(
                                        'testimony-answer-${answer.id}',
                                      ),
                                      icon: answer.icon,
                                      title: answer.title,
                                      body: answer.body,
                                      selected: _selected == answer.id,
                                      onPressed: () =>
                                          setState(() => _selected = answer.id),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                          const SizedBox(height: 14),
                          _CommandButton(
                            icon: Icons.lock_outline_rounded,
                            label: '密封并提交本人证词',
                            onPressed: _selected == null
                                ? null
                                : () => widget.controller.submitFinalTestimony(
                                    _selected!,
                                  ),
                            primary: true,
                            width: compact ? contentWidth : 300,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TestimonyAnswerCard extends StatelessWidget {
  const _TestimonyAnswerCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF25352F) : const Color(0xE6111718),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? const Color(0xFFD8A24A) : const Color(0xFF33413D),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 126,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFFD8A24A), size: 21),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selected
                          ? const Color(0xFFD8A24A)
                          : const Color(0xFF75807C),
                      size: 19,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFAAB3AF),
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EndingLayer extends StatelessWidget {
  const _EndingLayer({required this.controller});

  final StoryController controller;

  @override
  Widget build(BuildContext context) {
    final ending = endingById(controller.current.endingId)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final short = constraints.maxHeight < 520;
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x66080B0C), Color(0xFA080B0C)],
            ),
          ),
          child: SafeArea(
            minimum: EdgeInsets.all(short ? 14 : 24),
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Eyebrow(text: ending.rank),
                      SizedBox(height: short ? 4 : 12),
                      Text(
                        ending.title,
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(fontSize: short ? 32 : null),
                      ),
                      SizedBox(height: short ? 8 : 20),
                      Text(
                        controller.current.text,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFFD6DAD6),
                          fontSize: short ? 14 : null,
                          height: short ? 1.5 : null,
                        ),
                      ),
                      SizedBox(height: short ? 10 : 24),
                      Wrap(
                        spacing: 18,
                        runSpacing: 8,
                        children: [
                          _Stat(
                            label: '合作',
                            value: '${controller.cooperation}',
                          ),
                          _Stat(label: '逻辑', value: '${controller.logic}'),
                          _Stat(
                            label: '线路进度',
                            value: '${controller.progressPercent}%',
                          ),
                        ],
                      ),
                      SizedBox(height: short ? 12 : 30),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CommandButton(
                            icon: Icons.account_tree_outlined,
                            label: '打开线路图',
                            onPressed: () => showRouteMap(context, controller),
                            primary: true,
                            width: short ? 200 : 260,
                            height: short ? 40 : 46,
                          ),
                          _CommandButton(
                            icon: Icons.replay_rounded,
                            label: '从最初的苏醒重新开始',
                            onPressed: controller.startNew,
                            width: short ? 200 : 260,
                            height: short ? 40 : 46,
                          ),
                          _CommandButton(
                            icon: Icons.home_outlined,
                            label: '返回标题',
                            onPressed: controller.returnToTitle,
                            width: short ? 200 : 260,
                            height: short ? 40 : 46,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller, this.title});

  final StoryController controller;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (title == null) return const SizedBox.shrink();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 80, 0),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: const Color(0xDC101516),
              border: Border.all(color: const Color(0x663A4945)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    title!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RightControlRail extends StatelessWidget {
  const _RightControlRail({
    required this.controller,
    this.playbackEnabled = true,
    this.backpackOpen = false,
    this.onBackpackPressed,
  });

  final StoryController controller;
  final bool playbackEnabled;
  final bool backpackOpen;
  final VoidCallback? onBackpackPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          key: const ValueKey('right-control-rail'),
          padding: const EdgeInsets.only(right: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RailControl(
                label: 'AUTO',
                tooltip: playbackEnabled ? '自动播放' : '当前环节不可自动播放',
                icon: controller.autoPlay
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                active: controller.autoPlay,
                onPressed: playbackEnabled
                    ? () => controller.setAutoPlay(!controller.autoPlay)
                    : null,
              ),
              const SizedBox(height: 7),
              _RailControl(
                label: 'SKIP',
                tooltip: !playbackEnabled
                    ? '当前环节不可快进'
                    : controller.canSkipCurrent
                    ? '快进已读文本'
                    : '当前文本未读',
                icon: Icons.fast_forward_rounded,
                active: controller.skipMode,
                onPressed: playbackEnabled && controller.canSkipCurrent
                    ? () => controller.setSkipMode(!controller.skipMode)
                    : null,
              ),
              if (onBackpackPressed != null) ...[
                const SizedBox(height: 7),
                _RailControl(
                  label: 'BAG',
                  tooltip: backpackOpen ? '关闭背包' : '打开背包',
                  icon: Icons.backpack_outlined,
                  active: backpackOpen,
                  onPressed: onBackpackPressed,
                ),
              ],
              const SizedBox(height: 7),
              _RailControl(
                label: 'PDA',
                tooltip: '打开 PDA',
                icon: Icons.smartphone_rounded,
                active: controller.markedSector != null,
                onPressed: () => showPda(context, controller),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailControl extends StatelessWidget {
  const _RailControl({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  final String label;
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFF0D08F) : const Color(0xFF9EA9A4),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Tooltip(
          message: tooltip,
          child: IconButton(
            onPressed: onPressed,
            style: IconButton.styleFrom(
              fixedSize: const Size.square(48),
              backgroundColor: active
                  ? const Color(0xFF315A50)
                  : const Color(0xE6101516),
              foregroundColor: active ? const Color(0xFFF0D08F) : null,
              side: BorderSide(
                color: active
                    ? const Color(0xFF69A89D)
                    : const Color(0x663A4945),
              ),
            ),
            icon: Icon(icon),
          ),
        ),
      ],
    );
  }
}

class _TitleTool extends StatelessWidget {
  const _TitleTool({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: const Color(0xCC141B1B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFF34423E)),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: const Color(0xFFD8A24A)),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommandButton extends StatelessWidget {
  const _CommandButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.width = 260,
    this.height = 46,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final button = primary
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          );
    return SizedBox(width: width, height: height, child: button);
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFD8A24A),
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: const TextStyle(color: Color(0xFF8E9A95)),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xFFD8A24A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

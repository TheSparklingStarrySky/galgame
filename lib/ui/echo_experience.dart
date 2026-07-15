import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/echo_scene_game.dart';
import '../story/story.dart';
import '../story/story_controller.dart';
import 'system_panels.dart';

class EchoExperience extends StatefulWidget {
  const EchoExperience({super.key, required this.controller});

  final StoryController controller;

  @override
  State<EchoExperience> createState() => _EchoExperienceState();
}

class _EchoExperienceState extends State<EchoExperience> {
  late final EchoSceneGame _game;

  @override
  void initState() {
    super.initState();
    _game = EchoSceneGame();
    widget.controller.addListener(_syncGame);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncGame);
    super.dispose();
  }

  void _syncGame() {
    _game.setScene(widget.controller.scene);
    _game.setReducedMotion(widget.controller.reduceMotion);
    _game.setTuning(active: widget.controller.phase == StoryPhase.tuning);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget<EchoSceneGame>(game: _game),
          ValueListenableBuilder<bool>(
            valueListenable: _game.sceneReady,
            builder: (context, ready, _) {
              if (!ready) return const _SceneLoadingLayer();
              return AnimatedBuilder(
                animation: widget.controller,
                builder: (context, _) => _buildLayer(widget.controller),
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
    );
  }

  Widget _buildLayer(StoryController controller) => switch (controller.phase) {
    StoryPhase.title => _TitleLayer(controller: controller),
    StoryPhase.dialogue => DialogueLayer(
      key: ValueKey(controller.currentId),
      controller: controller,
    ),
    StoryPhase.investigation => _InvestigationLayer(controller: controller),
    StoryPhase.tuning => _TuningLayer(controller: controller, game: _game),
    StoryPhase.deduction => _DeductionLayer(controller: controller),
    StoryPhase.ending => _EndingLayer(controller: controller),
  };
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
            final short = constraints.maxHeight < 650;
            final toolsWidth = narrow ? 230.0 : 320.0;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                narrow ? 40 : 72,
                short ? 22 : 62,
                narrow ? 28 : 56,
                short ? 16 : 24,
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
                              SizedBox(height: short ? 6 : 12),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '零点协议',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        fontSize: short ? 40 : 72,
                                        color: const Color(0xFFF0EEE7),
                                      ),
                                ),
                              ),
                              SizedBox(height: short ? 6 : 14),
                              Text(
                                '规则只决定谁能活，选择决定你还是不是人。',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: const Color(0xFFB9C3BE),
                                      fontSize: narrow ? 15 : 18,
                                    ),
                              ),
                              SizedBox(height: short ? 16 : 32),
                              _CommandButton(
                                icon: Icons.play_arrow_rounded,
                                label: '开始游戏',
                                onPressed: controller.startNew,
                                primary: true,
                              ),
                              const SizedBox(height: 9),
                              _CommandButton(
                                icon: Icons.update_rounded,
                                label: '继续游戏',
                                onPressed: controller.hasAutoSave
                                    ? controller.resume
                                    : null,
                              ),
                              const SizedBox(height: 9),
                              _CommandButton(
                                icon: Icons.folder_open_rounded,
                                label: '读取存档',
                                onPressed: () => showSaveLoad(
                                  context,
                                  controller,
                                  loadOnly: true,
                                ),
                              ),
                              SizedBox(height: short ? 14 : 26),
                              const Text(
                                '第一章 · 两米之外',
                                style: TextStyle(
                                  color: Color(0xFF8D9994),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: narrow ? 24 : 56),
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

  StoryBeat get beat => widget.controller.current;
  _DialoguePage get _currentPage => _textPages[_pageIndex];
  bool get _isLastPage => _pageIndex == _textPages.length - 1;
  int get _totalCharacters => _currentPage.text.characters.length;
  bool get _finished => _visibleCharacters >= _totalCharacters;

  @override
  void initState() {
    super.initState();
    _textPages = _paginateText(beat);
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
        _scheduleProgression();
      } else {
        setState(() => _visibleCharacters += 1);
      }
    });
  }

  void _finishTyping() {
    _typeTimer?.cancel();
    if (!_finished) setState(() => _visibleCharacters = _totalCharacters);
    _scheduleProgression();
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
    _startTyping();
  }

  void _advancePageOrNode() {
    if (_isLastPage) {
      widget.controller.advance();
    } else {
      _showNextPage();
    }
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
        return Stack(
          fit: StackFit.expand,
          children: [
            _TopBar(controller: widget.controller),
            if (portraitAsset(_portraitSpeaker, _portraitMood)
                case final asset?)
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
            if (_finished &&
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
                      onChoice: widget.controller.choose,
                    ),
                  ),
                ),
              ),
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
                      onTap: !_finished
                          ? _finishTyping
                          : !_isLastPage
                          ? _showNextPage
                          : beat.choices.isEmpty
                          ? widget.controller.advance
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            _RightControlRail(controller: widget.controller),
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
    required this.onTap,
  });

  final Speaker speaker;
  final String visibleText;
  final bool finished;
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
        onTap: onTap,
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
                      padding: EdgeInsets.only(right: finished ? 24 : 0),
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

class _InvestigationLayer extends StatefulWidget {
  const _InvestigationLayer({required this.controller});

  final StoryController controller;

  @override
  State<_InvestigationLayer> createState() => _InvestigationLayerState();
}

class _InvestigationLayerState extends State<_InvestigationLayer> {
  final Set<String> _found = {};
  String? _activeClueId;

  static const _clues = {
    'distance': (
      title: '距离记录',
      body: '折叠尺显示终端与死者相距 1.4m，屏幕回传却是 23m。现实位置与裁定数据不可能同时成立。',
      asset: 'assets/images/items/control_room/distance_terminal.png',
    ),
    'repeater': (
      title: '信号中继器',
      body: '设备本应断电，外壳却仍有余温；新装模块连接着终端定位频道，案发前三分钟曾被启动。',
      asset: 'assets/images/items/control_room/signal_repeater.png',
    ),
    'timer': (
      title: '项圈计时模块',
      body: '锁扣没有被强行破坏，计时模块在距离异常持续 180 秒后执行。这更像合法触发，而不是设备爆炸。',
      asset: 'assets/images/items/control_room/collar_timer.png',
    ),
  };

  void _inspect(String id) {
    setState(() {
      _found.add(id);
      _activeClueId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _TopBar(controller: widget.controller, title: '现场调查 / A-02'),
        Positioned.fill(
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(12, 56, 78, 86),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 360;
                final objectSize = compact ? 98.0 : 148.0;
                return Stack(
                  children: [
                    Align(
                      alignment: const Alignment(-0.74, -0.36),
                      child: _InvestigationObject(
                        asset: _clues['repeater']!.asset,
                        label: _clues['repeater']!.title,
                        size: objectSize,
                        found: _found.contains('repeater'),
                        onPressed: () => _inspect('repeater'),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(-0.02, 0.55),
                      child: _InvestigationObject(
                        asset: _clues['distance']!.asset,
                        label: _clues['distance']!.title,
                        size: objectSize,
                        found: _found.contains('distance'),
                        onPressed: () => _inspect('distance'),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0.72, -0.28),
                      child: _InvestigationObject(
                        asset: _clues['timer']!.asset,
                        label: _clues['timer']!.title,
                        size: objectSize,
                        found: _found.contains('timer'),
                        onPressed: () => _inspect('timer'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        if (_activeClueId case final clueId?)
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 62, 82, 112),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: _InspectionResultPanel(
                  key: ValueKey(clueId),
                  title: _clues[clueId]!.title,
                  body: _clues[clueId]!.body,
                  onClose: () => setState(() => _activeClueId = null),
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(14, 14, 82, 14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xED101516),
                  border: Border.all(color: const Color(0xFF35433F)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: _clues.entries
                            .map(
                              (entry) => _EvidenceTag(
                                label: entry.value.title,
                                active: _found.contains(entry.key),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _found.length == _clues.length
                          ? () =>
                                widget.controller.completeInvestigation(_found)
                          : null,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('完成'),
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

class _InspectionResultPanel extends StatelessWidget {
  const _InspectionResultPanel({
    super.key,
    required this.title,
    required this.body,
    required this.onClose,
  });

  final String title;
  final String body;
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFFD8A24A),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFF0D08F),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xFFF2F3EE),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '关闭',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvestigationObject extends StatelessWidget {
  const _InvestigationObject({
    required this.asset,
    required this.label,
    required this.size,
    required this.found,
    required this.onPressed,
  });

  final String asset;
  final String label;
  final double size;
  final bool found;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '检查$label',
      child: Semantics(
        button: true,
        label: '调查物品：$label',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('investigation-object-$label'),
            onTap: onPressed,
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: size * 1.18,
              height: size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0x22080B0C),
                      border: Border.all(
                        color: found
                            ? const Color(0xFF69A89D)
                            : const Color(0x99D8A24A),
                        width: found ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 7, 8, 20),
                      child: Image.asset(
                        asset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          found ? Icons.check_rounded : Icons.search_rounded,
                          size: 13,
                          color: found
                              ? const Color(0xFF8FC7B8)
                              : const Color(0xFFF0D08F),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFF0EEE7),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
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
  String? _selected;
  final Set<String> _selectedEvidence = {};

  static const _evidence = [
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
      body: '伪造信号超过阈值一秒',
    ),
  ];

  static const _hypotheses = [
    ('suicide', '主动离开终端', '10 号为了满足自己的条件而自杀。'),
    ('swap', '终端被交换', '凶手把另一台终端放在死者身边制造假距离。'),
    ('repeater', '中继器伪造定位', '凶手转发了距离握手，让项圈在规则内执行死刑。'),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xED080B0C),
      child: Stack(
        children: [
          _TopBar(controller: widget.controller, title: '规则推演 / CASE 01'),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(18, 76, 82, 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Eyebrow(text: 'VERIFIED EVIDENCE'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: _evidence
                            .map((item) {
                              final selected = _selectedEvidence.contains(
                                item.id,
                              );
                              return _EvidenceCard(
                                icon: item.icon,
                                title: item.title,
                                body: item.body,
                                selected: selected,
                                onPressed: () {
                                  setState(() {
                                    if (selected) {
                                      _selectedEvidence.remove(item.id);
                                    } else {
                                      _selectedEvidence.add(item.id);
                                    }
                                  });
                                },
                              );
                            })
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 22),
                      const _Eyebrow(text: 'CAUSE OF EXECUTION'),
                      const SizedBox(height: 9),
                      ..._hypotheses.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _HypothesisTile(
                            title: item.$2,
                            body: item.$3,
                            selected: _selected == item.$1,
                            onPressed: () =>
                                setState(() => _selected = item.$1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '已引用 ${_selectedEvidence.length} / 3 项证据',
                              style: const TextStyle(
                                color: Color(0xFF9EA9A4),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed:
                                  _selected == null ||
                                      _selectedEvidence.length < 3
                                  ? null
                                  : () => widget.controller.submitDeduction(
                                      _selected!,
                                    ),
                              icon: const Icon(Icons.gavel_outlined),
                              label: const Text('提交证据链'),
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
          _RightControlRail(
            controller: widget.controller,
            playbackEnabled: false,
          ),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
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
    return SizedBox(
      width: 228,
      height: 106,
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
                  body,
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
                            label: '从序章重新开始',
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
                Text(
                  controller.remainingTime,
                  style: const TextStyle(
                    color: Color(0xFFD8A24A),
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 1, height: 15, color: const Color(0xFF3A4945)),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    title ?? controller.current.label,
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
  });

  final StoryController controller;
  final bool playbackEnabled;

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

class _EvidenceTag extends StatelessWidget {
  const _EvidenceTag({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF29463F) : const Color(0xFF1A2020),
        border: Border.all(
          color: active ? const Color(0xFF69A89D) : const Color(0xFF323A38),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_rounded : Icons.lock_outline_rounded,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(active ? label : '未知', style: const TextStyle(fontSize: 12)),
        ],
      ),
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

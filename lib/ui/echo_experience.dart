import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
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
                                '第一至二章 · 已开放',
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
  String? _activeItemId;
  _InspectionAction? _lastAction;
  String? _feedback;
  bool _backpackOpen = false;

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

  _InvestigationSpec get _spec =>
      widget.controller.currentId == 'ch2_gym_investigation'
      ? _gym
      : _controlRoom;

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
    for (final spec in [_controlRoom, _gym]) {
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
    setState(() {
      _backpackOpen = !_backpackOpen;
      if (!_backpackOpen) _activeItemId = null;
      _lastAction = null;
    });
  }

  void _collect(_InvestigationTarget target) {
    widget.controller.collectInvestigationItem(target.id);
    setState(() {
      _feedback = '已收纳「${_resolvedItem(target.id).name}」，可从右侧打开背包查看。';
    });
  }

  void _openItem(String id) {
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
    if (_activeItemId != null && !_inventory.contains(_activeItemId)) {
      setState(() => _activeItemId = null);
    }
  }

  void _combine(String draggedId, String targetId) {
    if (draggedId == targetId) return;
    final target = _targetFor(targetId);
    final dragged = _items[draggedId];
    if (target == null || dragged == null) {
      setState(() => _feedback = '这两件物品无法组合。');
      return;
    }
    final candidates = target.actions
        .where((action) => action.requiresItems.contains(draggedId))
        .toList(growable: false);
    if (candidates.isEmpty) {
      setState(
        () => _feedback =
            '「${_resolvedItem(draggedId).name}」用在「${_resolvedItem(targetId).name}」上没有反应。',
      );
      return;
    }
    final action = candidates.firstWhere(
      (candidate) => !_completedActions.contains(candidate.id),
      orElse: () => candidates.first,
    );
    setState(() {
      _activeItemId = targetId;
      _lastAction = null;
    });
    _runAction(action);
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
                  onClose: () => setState(() => _activeItemId = null),
                ),
              ),
            ),
          ),
        if (_backpackOpen)
          Align(
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
                            const Row(
                              children: [
                                Icon(
                                  Icons.backpack_outlined,
                                  color: Color(0xFF8FC7B8),
                                  size: 15,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  '背包',
                                  style: TextStyle(
                                    color: Color(0xFFF0EEE7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '点击查看 · 拖动组合',
                                  style: TextStyle(
                                    color: Color(0xFF8C9994),
                                    fontSize: 9,
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
    required this.onClose,
  });

  final _InvestigationItem item;
  final _InvestigationTarget? target;
  final Set<String> completedActions;
  final _InspectionAction? lastAction;
  final ValueChanged<_InspectionAction> onAction;
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
    required this.onTap,
    required this.onCombine,
  });

  final _InvestigationItem item;
  final bool verified;
  final VoidCallback onTap;
  final ValueChanged<String> onCombine;

  @override
  Widget build(BuildContext context) {
    Widget card({required bool highlighted}) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 68,
        padding: const EdgeInsets.fromLTRB(4, 3, 4, 2),
        decoration: BoxDecoration(
          color: highlighted
              ? const Color(0xFF263A35)
              : const Color(0xFF171E1D),
          border: Border.all(
            color: highlighted
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
  String? _selected;
  final Map<String, String?> _chain = {
    'fact': null,
    'threshold': null,
    'mechanism': null,
  };
  String _activeRole = 'fact';
  bool _chainVerified = false;
  String? _chainFeedback;

  static const _roles = [
    (id: 'fact', title: '现场事实', prompt: '找出肉眼与系统记录无法同时成立的事实'),
    (id: 'threshold', title: '规则阈值', prompt: '说明项圈为何会把异常当作合法处决条件'),
    (id: 'mechanism', title: '实施媒介', prompt: '指出什么装置能把伪造数据送进裁定链'),
  ];

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
      body: '异常持续超过阈值一秒，但日志本身不说明来源',
    ),
    (
      id: 'lock',
      icon: Icons.lock_outline_rounded,
      title: '完整锁舌',
      body: '排除强拆，却不能单独证明项圈为何执行',
    ),
    (
      id: 'camera',
      icon: Icons.videocam_off_outlined,
      title: '监控空白',
      body: '只能说明画面缺失，不能替代现场物证',
    ),
  ];

  static const _hypotheses = [
    ('suicide', '主动离开终端', '10 号为了满足自己的条件而自杀。'),
    ('swap', '终端被交换', '凶手把另一台终端放在死者身边制造假距离。'),
    ('repeater', '中继器伪造定位', '凶手转发了距离握手，让项圈在规则内执行死刑。'),
  ];

  void _assignEvidence(String evidenceId) {
    setState(() {
      for (final role in _chain.keys) {
        if (_chain[role] == evidenceId) _chain[role] = null;
      }
      _chain[_activeRole] = evidenceId;
      _chainVerified = false;
      _chainFeedback = null;
      final emptyRoles = _chain.entries.where((entry) => entry.value == null);
      if (emptyRoles.isNotEmpty) _activeRole = emptyRoles.first.key;
    });
  }

  void _verifyChain() {
    const correct = {
      'fact': 'distance',
      'threshold': 'timer',
      'mechanism': 'repeater',
    };
    final verified = correct.entries.every(
      (entry) => _chain[entry.key] == entry.value,
    );
    setState(() {
      _chainVerified = verified;
      _chainFeedback = verified
          ? '证据链闭合：现实距离被伪造，异常跨过规则阈值，并由中继器送入裁定频道。'
          : '这组证据还不能从现场事实一路推到处决机制。检查是否把辅助记录当成了原因，或让一项证据承担了它无法证明的结论。';
      if (!verified) _selected = null;
    });
  }

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
                                  : _evidence.singleWhere(
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
                        children: _evidence
                            .map((item) {
                              String? assignedRole;
                              for (final role in _roles) {
                                if (_chain[role.id] == item.id) {
                                  assignedRole = role.title;
                                }
                              }
                              return _EvidenceCard(
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
                                  '选择上方论证位置，再从证据板放入一项证据。辅助证据不一定适合作为因果链主干。',
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
                          child: FilledButton.icon(
                            onPressed: _selected == null
                                ? null
                                : () => widget.controller.submitDeduction(
                                    _selected!,
                                  ),
                            icon: const Icon(Icons.gavel_outlined),
                            label: const Text('提交死因推演'),
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

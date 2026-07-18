import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galgame/main.dart';
import 'package:galgame/story/story.dart';
import 'package:galgame/story/story_controller.dart';
import 'package:galgame/ui/echo_experience.dart';
import 'package:galgame/ui/system_panels.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('标题界面可以开始死亡游戏并打开 PDA', (tester) async {
    await tester.pumpWidget(const GalgameApp(audioEnabled: false));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();

    expect(find.text('零点协议'), findsOneWidget);
    expect(find.text('开始游戏'), findsOneWidget);

    await tester.tap(find.text('开始游戏'));
    await tester.pump();

    expect(find.text('168:00:00'), findsNothing);
    await tester.tap(find.byIcon(Icons.smartphone_rounded));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PDA / PARTICIPANT 01'), findsOneWidget);
    expect(find.text('条款'), findsOneWidget);
    expect(find.text('名册'), findsOneWidget);
    expect(find.text('区域地图'), findsOneWidget);
    expect(find.text('证据'), findsOneWidget);
    expect(find.text('审计'), findsOneWidget);
    expect(find.text('系统'), findsOneWidget);
    expect(find.byKey(const ValueKey('pda-device')), findsOneWidget);
    expect(find.text('ZP-PDA 01 / SECURE TERMINAL'), findsOneWidget);
  });

  testWidgets('PDA 实体外壳在短横屏内不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('打开 PDA'));
    await tester.pump(const Duration(milliseconds: 300));

    final device = find.byKey(const ValueKey('pda-device'));
    expect(device, findsOneWidget);
    final rect = tester.getRect(device);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(844));
    expect(rect.bottom, lessThanOrEqualTo(390));
    expect(tester.takeException(), isNull);
  });

  test('PDA 路线规划会改变后续分支收益', () async {
    final controller = await StoryController.load();
    controller.startNew();
    controller.setMarkedSector('medical');
    _advanceUntil(controller, 'clause_choice');

    controller.choose(controller.availableChoices.first);
    _advanceUntil(controller, 'investigation_gate');
    controller.completeInvestigation({'distance', 'repeater', 'timer'});
    _advanceUntil(controller, 'response_choice');
    controller.choose(controller.availableChoices.first);

    expect(controller.currentId, 'help_sumi');
    expect(controller.cooperation, 5);
    expect(controller.flags, contains('planned_medical_route'));
    expect(controller.flags, contains('medical_record'));
  });

  test('多槽存读档会恢复分支数值和地图标记', () async {
    final controller = await StoryController.load();
    controller.startNew();
    controller.setMarkedSector('medical');
    _advanceUntil(controller, 'clause_choice');
    controller.choose(controller.availableChoices.first);
    controller.collectInvestigationItem('tool_tray');
    controller.recordInvestigationAction(
      'tray_pick',
      grantsItem: 'insulated_pick',
    );
    await controller.saveToSlot(2);

    controller.setMarkedSector('storage');
    controller.collectInvestigationItem('wall_box');
    _advanceUntil(controller, 'partner_choice');
    expect(controller.currentId, 'partner_choice');
    controller.choose(controller.availableChoices.last);
    expect(controller.currentId, 'lincheng_map');

    controller.loadSlot(2);
    expect(controller.currentId, 'public_pact');
    expect(controller.cooperation, 2);
    expect(controller.markedSector, 'medical');
    expect(controller.flags, contains('public_clause'));
    expect(
      controller.inventoryItems,
      containsAll(['tool_tray', 'insulated_pick']),
    );
    expect(controller.inventoryItems, isNot(contains('wall_box')));
    expect(controller.investigationActions, contains('tray_pick'));
  });

  test('手动存档会持久化当前进程画面缩略图', () async {
    final controller = await StoryController.load();
    controller.startNew();
    final thumbnail = base64Encode(const [0, 1, 2, 3, 4]);
    controller.attachSaveThumbnailCapture(() async => thumbnail);
    controller.setSaveThumbnailFallback(
      asset: cgEntries.first.assets.last,
      text: '保存时所在的当前文本页',
    );

    await controller.saveToSlot(1);

    expect(controller.saveSlots[1]!.thumbnailBase64, thumbnail);
    expect(
      controller.saveSlots[1]!.thumbnailAsset,
      cgEntries.first.assets.last,
    );
    expect(controller.saveSlots[1]!.thumbnailText, '保存时所在的当前文本页');
    final restored = await StoryController.load();
    expect(restored.saveSlots[1]!.thumbnailBase64, thumbnail);
    expect(restored.saveSlots[1]!.thumbnailAsset, cgEntries.first.assets.last);
  });

  testWidgets('存档画面完整覆盖槽位背景', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    controller.setSaveThumbnailFallback(
      asset: cgEntries.first.assets.first,
      text: '存档时的正文',
    );
    await controller.saveToSlot(0);
    final currentId = controller.currentId;
    controller.returnToTitle();

    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();
    await tester.tap(find.text('读取存档'));
    await tester.pump();

    final slotRect = tester.getRect(find.byKey(const ValueKey('save-slot-0')));
    final thumbnailRect = tester.getRect(
      find.byKey(ValueKey('save-thumbnail-$currentId')),
    );
    expect(thumbnailRect, slotRect);
  });

  testWidgets('事件 CG 只随剧情节点切帧并在末帧读完后解锁', (tester) async {
    final controller = await StoryController.load();
    controller.startNew();
    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('story-cg-cg_dormitory-0')),
      findsOneWidget,
    );
    expect(controller.unlockedCgs, isNot(contains('cg_dormitory')));

    var guard = 0;
    while (controller.currentId == 'game_start' && guard < 8) {
      guard += 1;
      await tester.tap(find.byKey(const ValueKey('dialogue-panel')));
      await tester.pump();
      if (controller.currentId == 'game_start') {
        expect(
          find.byKey(const ValueKey('story-cg-cg_dormitory-0')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('story-cg-cg_dormitory-1')),
          findsNothing,
        );
      }
    }
    expect(controller.currentId, 'wake_senses');
    expect(controller.unlockedCgs, isNot(contains('cg_dormitory')));

    _advanceUntil(controller, 'collar_discovery');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('story-cg-cg_dormitory-1')),
      findsOneWidget,
    );

    guard = 0;
    while (controller.currentId == 'collar_discovery' && guard < 12) {
      guard += 1;
      await tester.tap(find.byKey(const ValueKey('dialogue-panel')));
      await tester.pump();
    }
    expect(controller.currentId, 'collar_panic');
    expect(controller.unlockedCgs, contains('cg_dormitory'));
  });

  testWidgets('CG 鉴赏点击画面直接切换组内下一帧', (tester) async {
    final controller = await StoryController.load();
    controller.unlockedCgs.add('cg_dormitory');
    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('CG 鉴赏'));
    await tester.pump();
    await tester.tap(find.text('醒在编号里'));
    await tester.pump();
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cg-sequence-viewer')));
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.text('2 / 2'), findsOneWidget);
  });

  test('一次性调查物品被消耗后不会随存档复原', () async {
    final controller = await StoryController.load();
    controller.startNew();
    controller.collectInvestigationItem('wall_box');
    controller.collectInvestigationItem('insulated_pick');
    controller.recordInvestigationAction(
      'box_open',
      consumesItems: const ['insulated_pick'],
      verifiesClue: 'repeater',
    );
    await controller.saveToSlot(3);

    controller.startNew();
    controller.loadSlot(3);

    expect(controller.inventoryItems, contains('wall_box'));
    expect(controller.inventoryItems, isNot(contains('insulated_pick')));
    expect(controller.investigationActions, contains('box_open'));
    expect(controller.investigationClues, contains('repeater'));
  });

  test('线路图跳转恢复节点状态，已读快进状态保留', () async {
    final controller = await StoryController.load();
    controller.startNew();

    expect(controller.canSkipCurrent, isFalse);
    controller.setSkipMode(true);
    expect(controller.skipMode, isFalse);

    controller.advance();
    expect(controller.jumpToNode('game_start'), isTrue);
    expect(controller.currentId, 'game_start');
    expect(controller.canSkipCurrent, isTrue);

    controller.setSkipMode(true);
    expect(controller.skipMode, isTrue);
    expect(controller.cooperation, 0);
    expect(controller.logic, 0);
  });

  testWidgets('线路图打开后居中当前路径的关键节点并可点击跳转', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'explosion_silence');
    controller.seenNodes.add('ch4_end');

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showRouteMap(context, controller),
            child: const Text('打开线路图'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开线路图'));
    await tester.pump();
    await tester.pump();

    final viewport = tester.getRect(
      find.byKey(const ValueKey('route-map-viewport')),
    );
    final currentNode = tester.getRect(
      find.byKey(const ValueKey('route-node-collar_detonation')),
    );
    expect((currentNode.center.dx - viewport.center.dx).abs(), lessThan(1));
    expect((currentNode.center.dy - viewport.center.dy).abs(), lessThan(1));

    await tester.tap(
      find.byKey(const ValueKey('route-node-participant_twelve')),
    );
    await tester.pump();
    expect(controller.currentId, 'participant_twelve');
    expect(find.text('剧情线路图'), findsNothing);
  });

  test('开场先确认现状与身份，再由主办方演示规则后果', () async {
    final controller = await StoryController.load();
    controller.startNew();

    final order = <String>[];
    while (controller.currentId != 'personal_clause') {
      order.add(controller.currentId);
      controller.advance();
    }

    expect(
      order,
      containsAllInOrder([
        'wake_senses',
        'room_check',
        'door_test',
        'collar_discovery',
        'collar_panic',
        'corridor_encounter',
        'corridor_standoff',
        'enter_hall',
        'locked_exit',
        'intro_proposal',
        'shenyan_intro',
        'xingyao_intro',
        'hanqi_intro',
        'tang_intro',
        'lincheng_intro',
        'other_participants',
        'gaoyuan_intro',
        'zhouxu_intro',
        'yelan_intro',
        'participant_twelve',
        'ransom_theory',
        'staged_game_theory',
        'camera_attack',
        'screen_boot',
        'wu_challenge',
        'sumi_blocks_wu',
        'final_warning',
        'crowd_intervention',
        'wu_defiance',
        'collar_detonation',
        'explosion_silence',
        'death_confirmed',
        'denial_after_death',
        'host_resumes',
        'rule_one',
        'distance_demo',
        'rule_two',
        'rule_three',
      ]),
    );
    expect(order.length, greaterThan(50));
    expect(storyBeats['wu_challenge']!.speaker, Speaker.wuZheng);
    expect(storyBeats['collar_detonation']!.label, '第一次出局');
  });

  test('线路图只保留关键节点，正文仍保留足够场景细节', () {
    expect(storyBeats.length, greaterThanOrEqualTo(110));
    expect(routeNodes.length, lessThan(50));
    expect(routeNodes.length, lessThan(storyBeats.length ~/ 3));
    expect(
      routeNodes.map((node) => node.id),
      containsAll([
        'game_start',
        'participant_twelve',
        'collar_detonation',
        'investigation_gate',
        'deduction_gate',
        'ch2_chapter_title',
        'ch2_approach_choice',
        'ch2_gym_investigation',
        'ch2_seal_complete',
        'ch2_end',
      ]),
    );
    expect(routeNodes.every((node) => storyBeats.containsKey(node.id)), isTrue);
    expect(
      storyBeats.values.where((beat) => beat.text.length >= 90).length,
      greaterThanOrEqualTo(60),
    );
    expect(storyBeats['denial_after_death']!.text, contains('不可能'));
    expect(storyBeats['lincheng_not_child']!.text, contains('十八岁'));
  });

  test('同一剧情节点会分别标记角色对白和无姓名旁白', () {
    final introduction = storyBeats['xingyao_name']!;
    expect(introduction.passages.map((passage) => passage.speaker), [
      Speaker.liXingyao,
      Speaker.narration,
    ]);
    expect(introduction.passages.last.text, startsWith('我也告诉她'));

    expect(
      storyBeats['staged_game_theory']!.passages.map(
        (passage) => passage.speaker,
      ),
      [Speaker.tangYi, Speaker.wuZheng, Speaker.tangYi],
    );
    expect(
      storyBeats['wake_senses']!.passages.single.speaker,
      Speaker.narration,
    );
    expect(
      storyBeats['ch1_case_limits']!.passages.every(
        (passage) => passage.speaker == Speaker.narration,
      ),
      isTrue,
    );
    expect(
      storyBeats['ch2_route_together']!.passages.map(
        (passage) => passage.speaker,
      ),
      [Speaker.narration, Speaker.tangYi, Speaker.yeLan, Speaker.narration],
    );

    for (final beat in storyBeats.values) {
      expect(
        beat.passages.map((passage) => passage.text).join('\n'),
        beat.text,
        reason: '${beat.id} 的段落不能丢失正文',
      );
    }
  });

  test('08 至 11 号均有独立登场和立绘，12 号明确缺席', () {
    final introductions = <String, Speaker>{
      'other_participants': Speaker.chenMo,
      'gaoyuan_intro': Speaker.gaoYuan,
      'zhouxu_intro': Speaker.zhouXu,
      'yelan_intro': Speaker.yeLan,
    };

    for (final entry in introductions.entries) {
      final beat = storyBeats[entry.key]!;
      final asset = portraitAsset(entry.value);
      final moodAsset = portraitAsset(entry.value, beat.portraitMood);
      expect(beat.speaker, entry.value);
      expect(beat.text.length, greaterThan(120));
      expect(
        beat.passages.map((passage) => passage.speaker),
        contains(entry.value),
      );
      expect(asset, isNotNull);
      expect(File(asset!).existsSync(), isTrue, reason: '$asset 必须存在');
      expect(File(moodAsset!).existsSync(), isTrue, reason: '$moodAsset 必须存在');
    }

    expect(storyBeats.length, greaterThanOrEqualTo(180));
    expect(storyBeats['enter_hall']!.text, contains('只有十一人'));
    expect(storyBeats['participant_twelve']!.text, contains('无记录'));
    expect(storyBeats['participant_twelve']!.speaker, Speaker.narration);
  });

  test('十名可见角色均至少拥有中立与剧情动作两张立绘', () {
    for (final speaker in [
      Speaker.liXingyao,
      Speaker.suMi,
      Speaker.hanQi,
      Speaker.wuZheng,
      Speaker.tangYi,
      Speaker.linCheng,
      Speaker.chenMo,
      Speaker.gaoYuan,
      Speaker.zhouXu,
      Speaker.yeLan,
    ]) {
      final neutral = File(portraitAsset(speaker)!);
      expect(neutral.existsSync(), isTrue);
      expect(
        neutral.parent
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.png'))
            .length,
        greaterThanOrEqualTo(2),
        reason: '${speaker.name} 至少需要两张剧情差分',
      );
    }
  });

  test('沈砚拥有 CG 基准立绘且不破坏第一人称正文', () {
    expect(File(shenYanReferenceAsset).existsSync(), isTrue);
    expect(portraitAsset(Speaker.shenYan), isNull);
  });

  testWidgets('陈默登场时加载 08 号透明立绘', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'other_participants');

    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 700)),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('portrait-chenMo')), findsOneWidget);
    expect(controller.current.text, contains('系统工程师'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('翻到旁白段落时隐藏姓名栏但保留当前人物立绘', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'xingyao_name');

    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 700)),
    );
    await tester.pump();

    final panel = find.byKey(const ValueKey('dialogue-panel'));
    await tester.tap(panel);
    await tester.pump();
    expect(find.text('黎星遥 / 02'), findsOneWidget);

    await tester.tap(panel);
    await tester.pump();
    await tester.tap(panel);
    await tester.pump();

    expect(find.text('黎星遥 / 02'), findsNothing);
    expect(find.textContaining('我也告诉她自己叫沈砚'), findsOneWidget);
    expect(find.byKey(const ValueKey('portrait-liXingyao')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('人物台词显示透明立绘且避开右侧控制栏', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'xingyao_intro');

    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();

    final portrait = find.byKey(const ValueKey('portrait-liXingyao'));
    expect(portrait, findsOneWidget);
    expect(tester.getRect(portrait).right, lessThanOrEqualTo(772));
    expect(find.byKey(const ValueKey('right-control-rail')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('林澄以成年高三学生身份加入并显示双马尾立绘', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'lincheng_intro');

    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('portrait-linCheng')), findsOneWidget);
    expect(controller.current.text, contains('十八岁，高三'));
    expect(portraitAsset(Speaker.linCheng), contains('lin_cheng/neutral.png'));
    expect(tester.takeException(), isNull);
  });

  test('三条恋爱支线通过重复同行选择延续到第二章', () async {
    final routes = [
      (
        partner: 0,
        response: 1,
        bond: 'bond_xingyao',
        guard: 'ch2_stay_xingyao',
        aftercare: 'ch2_xingyao_aftercare',
      ),
      (
        partner: 1,
        response: 0,
        bond: 'bond_sumi',
        guard: 'ch2_stay_sumi',
        aftercare: 'ch2_sumi_aftercare',
      ),
      (
        partner: 2,
        response: 2,
        bond: 'bond_lincheng',
        guard: 'ch2_stay_lincheng',
        aftercare: 'ch2_lincheng_aftercare',
      ),
    ];

    for (final route in routes) {
      final controller = await StoryController.load();
      controller.startNew();
      _advanceUntil(controller, 'clause_choice');
      controller.choose(controller.availableChoices.first);
      _advanceUntil(controller, 'partner_choice');
      expect(controller.currentId, 'partner_choice');
      controller.choose(controller.availableChoices[route.partner]);
      _advanceUntil(controller, 'investigation_gate');
      controller.completeInvestigation({'distance', 'repeater', 'timer'});
      _advanceUntil(controller, 'response_choice');
      controller.choose(controller.availableChoices[route.response]);
      _advanceUntil(controller, 'decrypt_gate');
      controller.completeTuning();
      _advanceUntil(controller, 'deduction_gate');
      controller.submitDeduction('repeater');

      expect(controller.currentId, 'ch2_case_conclusion');
      expect(controller.flags, contains(route.bond));
      _advanceUntil(controller, 'ch2_leave_choice');
      final guardChoice = controller.availableChoices.singleWhere(
        (choice) => choice.next == route.guard,
      );
      controller.choose(guardChoice);
      _advanceUntil(controller, 'ch2_gym_investigation');
      expect(
        controller.foundClues,
        containsAll({'distance', 'repeater', 'timer'}),
      );
      controller.completeInvestigation({
        'gym_control',
        'gym_cable',
        'gym_cradle',
      });
      expect(
        controller.foundClues,
        containsAll({
          'distance',
          'repeater',
          'timer',
          'gym_control',
          'gym_cable',
          'gym_cradle',
        }),
      );
      _advanceUntil(controller, 'ch2_aftermath_choice');
      final aftercareChoice = controller.availableChoices.singleWhere(
        (choice) => choice.next == route.aftercare,
      );
      controller.choose(aftercareChoice);
      expect(controller.currentId, route.aftercare);
      _advanceUntil(controller, 'ch2_end');
      expect(controller.current.text, contains('12号第一次拥有了方向'));
    }
  });

  test('正确规则推演进入第二章，错误结论仍进入坏结局', () async {
    final pact = await StoryController.load();
    pact.startNew();
    _advanceUntil(pact, 'clause_choice');
    pact.choose(pact.availableChoices.first);
    _advanceUntil(pact, 'investigation_gate');
    pact.completeInvestigation({'distance', 'repeater', 'timer'});
    _advanceUntil(pact, 'response_choice');
    pact.choose(pact.availableChoices.first);
    _advanceUntil(pact, 'decrypt_gate');
    pact.completeTuning();
    _advanceUntil(pact, 'deduction_gate');
    pact.submitDeduction('repeater');

    expect(pact.currentId, 'ch2_case_conclusion');
    expect(pact.flags, contains('case01_solved'));

    final failed = await StoryController.load();
    failed.startNew();
    _advanceUntil(failed, 'deduction_gate', allowMechanics: true);
    failed.submitDeduction('suicide');
    expect(failed.currentId, 'bad_end');
  });

  test('第一章扩写保留群像余震并为陈默案件留下可验证伏笔', () {
    final expansion = storyBeats.values
        .where((beat) => beat.id.startsWith('ch1_'))
        .toList(growable: false);
    expect(expansion.length, 25);
    expect(
      expansion.map((beat) => beat.text.length).fold<int>(0, (a, b) => a + b),
      greaterThan(3300),
    );
    expect(storyBeats['ch1_empty_chair_test']!.text, contains('没有人坐过'));
    expect(storyBeats['ch1_ledger_stamp']!.text, contains('R-08'));
    expect(storyBeats['ch1_arrival_order']!.text, contains('迟了约二十秒'));
    expect(storyBeats['ch1_case_limits']!.text, contains('不是判决'));
    expect(storyBeats['ch1_medical_search']!.scene, SceneKey.infirmary);
    expect(storyBeats['ch1_storage_search']!.scene, SceneKey.storageRoom);
    expect(storyBeats['ch1_archive_search']!.scene, SceneKey.archiveCorridor);
    expect(storyBeats['rule_one']!.text, contains('加密校验字段'));
    expect(storyBeats['personal_clause']!.text, contains('【校验字段】加密'));
    expect(storyBeats['hanqi_threat']!.text, contains('公开主条件'));
  });

  test('第二章围绕旧体育馆封锁与12号空身份展开', () {
    final chapter = storyBeats.values
        .where((beat) => beat.id.startsWith('ch2_'))
        .toList(growable: false);
    expect(chapter.length, 90);
    expect(
      chapter.map((beat) => beat.text.length).fold<int>(0, (a, b) => a + b),
      greaterThan(13000),
    );
    expect(
      chapter.where((beat) => beat.scene == SceneKey.oldGym).length,
      greaterThan(20),
    );
    expect(storyBeats['ch2_gym_entry']!.cgId, 'cg_gym');
    expect(
      storyBeats['ch2_gym_investigation']!.phase,
      StoryPhase.investigation,
    );
    expect(storyBeats['ch2_seal_complete']!.timelineMinute, 1440);
    expect(storyBeats['ch2_end']!.next, 'ch3_chapter_title');
    expect(storyBeats['ch2_end']!.auditNext, 'ch2_audit_index');
    final approach = storyBeats['ch2_approach_choice']!;
    expect(approach.choices.length, 3);
    expect(
      approach.choices.map((choice) => choice.effect.flag),
      containsAll([
        'ch2_route_service',
        'ch2_route_archive',
        'ch2_route_together',
      ]),
    );
    expect(storyBeats['ch2_fault_hypotheses']!.text, contains('无恶意解释'));
    expect(storyBeats['ch2_public_audit']!.text, contains('亲眼确认'));
    for (final path in [
      'assets/images/scenes/old_gym.png',
      'assets/images/scenes/infirmary.png',
      'assets/images/scenes/storage_room.png',
      'assets/images/scenes/archive_corridor.png',
      'assets/images/items/gym/shutter_control.png',
      'assets/images/items/gym/brake_cable.png',
      'assets/images/items/gym/terminal_cradle.png',
      'assets/images/items/gym/service_cart.png',
      'assets/images/items/gym/offline_test_lead.png',
      'assets/images/items/gym/folding_magnifier.png',
      'assets/images/items/control_room/tool_tray.png',
      'assets/images/items/control_room/folding_ruler.png',
      'assets/images/items/control_room/insulated_pick.png',
      'assets/images/items/control_room/sealed_signal_box.png',
      'assets/images/items/control_room/distance_record.png',
      'assets/images/characters/gao_yuan/injured.png',
      'assets/images/characters/su_mi/relieved.png',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: '$path 必须存在');
    }
  });

  test('第三章以托管权限、B-03调查和CASE 02组成完整第二日', () {
    final chapter = storyBeats.values
        .where((beat) => beat.id.startsWith('ch3_'))
        .toList(growable: false);
    expect(chapter.length, greaterThanOrEqualTo(110));
    expect(
      chapter.map((beat) => beat.text.length).fold<int>(0, (a, b) => a + b),
      greaterThan(12000),
    );
    for (final beat in chapter) {
      expect(
        beat.passages.length,
        beat.text.isEmpty ? 1 : greaterThanOrEqualTo(1),
        reason: beat.id,
      );
    }
    expect(storyBeats['ch3_delegation_gate']!.phase, StoryPhase.delegation);
    expect(
      storyBeats['ch3_storage_investigation']!.phase,
      StoryPhase.investigation,
    );
    expect(storyBeats['ch3_case02_deduction']!.phase, StoryPhase.deduction);
    expect(storyBeats['ch3_transfer_access_puzzle']!.phase, StoryPhase.puzzle);
    expect(storyBeats['ch3_balance_puzzle']!.phase, StoryPhase.puzzle);
    expect(storyBeats['ch3_slide_puzzle']!.phase, StoryPhase.puzzle);
    expect(storyBeats['ch3_second_seal_notice']!.timelineMinute, 2820);
    expect(storyBeats['ch3_end']!.next, 'ch4_daybreak');
    expect(storyBeats['ch3_end']!.text, contains('镇静剂'));
    expect(
      routeNodes
          .where((node) => node.id.startsWith('ch3_'))
          .map((node) => node.id),
      containsAll([
        'ch3_chapter_title',
        'ch3_delegation_gate',
        'ch3_storage_investigation',
        'ch3_case02_deduction',
        'ch3_transfer_access_puzzle',
        'ch3_slide_puzzle',
        'ch3_protocol_choice',
        'ch3_end',
      ]),
    );
    expect(
      routeNodes.where((node) => node.id.startsWith('ch3_')).length,
      lessThan(chapter.length ~/ 8),
    );
    for (final path in [
      'assets/images/items/storage/sealed_crate.png',
      'assets/images/items/storage/locked_audit_pda.png',
      'assets/images/items/storage/supply_shelf.png',
      'assets/images/items/storage/audit_case.png',
      'assets/images/items/storage/uv_lamp.png',
      'assets/images/items/storage/spring_scale.png',
      'assets/images/items/storage/offline_reader.png',
      'assets/images/items/storage/handover_receipt.png',
      'assets/images/items/storage/maintenance_card.png',
      'assets/images/items/storage/shift_note.png',
      'assets/images/characters/han_qi/conflicted.png',
      'assets/images/characters/li_xingyao/relaxed.png',
      'assets/images/characters/lin_cheng/anxious.png',
      'assets/images/characters/chen_mo/guarded.png',
      'assets/images/scenes/transfer_room.png',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: '$path 必须存在');
    }
  });

  test('第四章完成医疗调查、CASE 03与三种首杀制度分支', () {
    final chapter = storyBeats.values
        .where((beat) => beat.id.startsWith('ch4_'))
        .toList(growable: false);
    expect(chapter.length, greaterThanOrEqualTo(140));
    expect(
      chapter.map((beat) => beat.text.length).fold<int>(0, (a, b) => a + b),
      greaterThan(21000),
    );
    expect(
      storyBeats['ch4_medical_investigation']!.phase,
      StoryPhase.investigation,
    );
    expect(storyBeats['ch4_case03_deduction']!.phase, StoryPhase.deduction);
    expect(storyBeats['ch4_high_risk_announcement']!.timelineMinute, 3450);
    expect(storyBeats['ch4_strong_custody']!.scene, SceneKey.securityRoom);
    expect(storyBeats['ch4_alliance_custody']!.scene, SceneKey.maintenanceRoom);
    expect(storyBeats['ch4_xingyao_hides_tinnitus']!.portraitMood, 'vertigo');
    expect(storyBeats['ch4_hanqi_tests_baton']!.portraitMood, 'armed');
    expect(storyBeats['ch4_chenmo_fear_admission']!.portraitMood, 'desperate');
    expect(storyBeats['ch4_majority_group_split']!.portraitMood, 'shaken');
    expect(
      storyBeats['ch4_strong_death_confirmed']!
          .deathEvents
          .single
          .participantId,
      '08',
    );
    expect(
      storyBeats['ch4_alliance_death']!.deathEvents.single.participantId,
      '04',
    );
    expect(
      storyBeats['ch4_majority_death_rescue']!.deathEvents.single.participantId,
      '09',
    );
    expect(storyBeats['ch4_end']!.next, isNull);
    expect(
      routeNodes.where((node) => node.id.startsWith('ch4_')).length,
      lessThan(chapter.length ~/ 6),
    );
    for (final path in [
      'assets/images/scenes/medical_isolation.png',
      'assets/images/scenes/security_room.png',
      'assets/images/scenes/maintenance_room.png',
      'assets/images/characters/li_xingyao/vertigo.png',
      'assets/images/characters/han_qi/armed.png',
      'assets/images/characters/chen_mo/desperate.png',
      'assets/images/characters/su_mi/shaken.png',
      'assets/images/items/medical/medical_test_case.png',
      'assets/images/items/medical/sedative_test_strip.png',
      'assets/images/items/medical/offline_spectrum_clip.png',
      'assets/images/items/medical/injection_infusion_set.png',
      'assets/images/items/medical/medical_assay_card.png',
      'assets/images/items/medical/triage_record.png',
      'assets/images/items/medical/patient_headset.png',
      'assets/images/items/medical/headset_spectrum_capture.png',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: '$path 必须存在');
    }
  });

  test('第四章标准周目的三种钥匙制度产生不同死亡责任', () async {
    const routes = [
      (
        next: 'ch4_strong_custody',
        deathNode: 'ch4_strong_death_confirmed',
        participant: '08',
        sourceItem: 'stun_controller',
        responsible: '04',
      ),
      (
        next: 'ch4_alliance_custody',
        deathNode: 'ch4_alliance_death',
        participant: '04',
        sourceItem: 'industrial_driver',
        responsible: '08',
      ),
      (
        next: 'ch4_majority_custody',
        deathNode: 'ch4_majority_death_rescue',
        participant: '09',
        sourceItem: null,
        responsible: '06',
      ),
    ];

    for (final route in routes) {
      final controller = await StoryController.load();
      controller.startNew();
      _advanceUntil(controller, 'ch4_key_custody_choice', allowMechanics: true);
      controller.choose(
        controller.availableChoices.singleWhere(
          (choice) => choice.next == route.next,
        ),
      );
      _advanceUntil(controller, route.deathNode, allowMechanics: true);

      final death = controller.deathRecords.last;
      expect(death.participantId, route.participant, reason: route.next);
      expect(
        death.responsibleParticipantIds,
        contains(route.responsible),
        reason: route.next,
      );
      expect(death.sourceItemId, route.sourceItem, reason: route.next);
      expect(
        controller.livingParticipantIds,
        isNot(contains(route.participant)),
        reason: route.next,
      );
      if (route.sourceItem case final sourceItem?) {
        expect(
          controller.highRiskItems[sourceItem]!.state,
          HighRiskItemState.used,
          reason: route.next,
        );
      }
    }
  });

  test('第四章审计周目公开预演后阻止首杀并重新封存物资', () async {
    final controller = await StoryController.load();
    controller.completeFullRunEnding('ending_four_seats');
    controller.startNew(mode: StoryRunMode.audit);
    _advanceUntil(controller, 'ch4_audit_decision', allowMechanics: true);
    controller.choose(
      controller.availableChoices.singleWhere(
        (choice) => choice.next == 'ch4_audit_public_seal',
      ),
    );
    _advanceUntil(controller, 'ch4_end', allowMechanics: true);

    expect(controller.flags, contains('ch4_audit_chain_blocked'));
    expect(
      controller.deathRecords.map((record) => record.participantId),
      isNot(contains('04')),
    );
    expect(
      controller.deathRecords.map((record) => record.participantId),
      isNot(contains('08')),
    );
    expect(
      controller.deathRecords.map((record) => record.participantId),
      isNot(contains('09')),
    );
    expect(
      controller.visibleHighRiskItems.every(
        (record) => record.state == HighRiskItemState.indexed,
      ),
      isTrue,
    );
  });

  test('游戏正文和鉴赏文案不显示制作章节字样', () {
    final chapterPattern = RegExp(r'第[一二三四五六七八九十0-9]+章|序章|章节(?:结束)?');
    for (final beat in storyBeats.values) {
      expect(chapterPattern.hasMatch(beat.label), isFalse, reason: beat.id);
      expect(chapterPattern.hasMatch(beat.text), isFalse, reason: beat.id);
    }
    for (final cg in cgEntries) {
      expect(chapterPattern.hasMatch(cg.caption), isFalse, reason: cg.id);
    }
  });

  test('所有 CG 都是正文可见的多帧事件图组', () {
    for (final cg in cgEntries) {
      expect(cg.assets.length, greaterThanOrEqualTo(2), reason: cg.id);
      final eventBeats = storyBeats.values
          .where((beat) => beat.cgId == cg.id)
          .toList();
      expect(
        eventBeats.map((beat) => beat.cgFrame).toSet(),
        Set<int>.from(List<int>.generate(cg.assets.length, (index) => index)),
        reason: '${cg.id} 的每一帧都应由独立剧情节点触发',
      );
      for (final beat in eventBeats) {
        expect(beat.cgFrame, inInclusiveRange(0, cg.assets.length - 1));
      }
      for (final asset in cg.assets) {
        expect(asset, contains('/images/cg/'), reason: cg.id);
        expect(File(asset).existsSync(), isTrue, reason: asset);
      }
    }
  });

  test('转运间三种机关分散到调查与封锁危机', () async {
    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(
      controller,
      'ch3_transfer_access_puzzle',
      allowMechanics: true,
    );

    controller.completePuzzle('access_0916');
    expect(controller.currentId, 'ch3_transfer_access_puzzle');
    controller.recordPuzzleProgress(
      'ch3_access_card_found',
      grantsItem: 'maintenance_card',
    );
    controller.recordPuzzleProgress(
      'ch3_shift_note_found',
      grantsItem: 'shift_note',
    );
    controller.recordPuzzleProgress(
      'ch3_access_card_swiped',
      consumesItems: const ['maintenance_card'],
    );
    expect(controller.inventoryItems, isNot(contains('maintenance_card')));
    controller.completePuzzle('access_0916');
    expect(controller.currentId, 'ch3_transfer_entry');

    _advanceUntil(controller, 'ch3_balance_puzzle', allowMechanics: true);
    controller.completePuzzle('ring_triangle_square_cross_dot');
    expect(controller.currentId, 'ch3_balance_puzzle');
    controller.completePuzzle('triangle_cross_ring_dot_square');
    expect(controller.currentId, 'ch3_balance_unlocked');
    expect(storyBeats['ch3_balance_unlocked']!.next, 'ch3_supplies_found');
    expect(
      storyBeats['ch3_return_for_audit']!.next,
      'ch3_evacuation_track_jam',
    );
    expect(storyBeats['ch3_evacuation_track_jam']!.next, 'ch3_slide_puzzle');

    _advanceUntil(controller, 'ch3_slide_puzzle', allowMechanics: true);
    controller.completePuzzle('circuit_complete');
    expect(controller.currentId, 'ch3_pattern_unlocked');
    expect(storyBeats['ch3_pattern_unlocked']!.next, 'ch3_shutter_split');
    expect(
      storyBeats['ch3_aftershock']!.auditNext,
      'ch3_audit_manifest_puzzle',
    );
    expect(
      controller.flags,
      containsAll([
        'puzzle_ch3_transfer_access_puzzle_solved',
        'puzzle_ch3_balance_puzzle_solved',
        'puzzle_ch3_slide_puzzle_solved',
      ]),
    );
  });

  test('完整一周目解锁审计模式并跨控制器持久化', () async {
    final controller = await StoryController.load();
    controller.startNew(mode: StoryRunMode.audit);
    expect(controller.runMode, StoryRunMode.standard);

    controller.completeFullRunEnding('ending_four');
    expect(controller.auditModeUnlocked, isFalse);
    controller.completeFullRunEnding('ending_four_seats');
    expect(controller.auditModeUnlocked, isTrue);

    final restored = await StoryController.load();
    expect(restored.auditModeUnlocked, isTrue);
    restored.startNew(mode: StoryRunMode.audit);
    expect(restored.runMode, StoryRunMode.audit);
  });

  test('审计周目串联灰色索引、隐藏解密与高危物资状态', () async {
    final controller = await StoryController.load();
    controller.completeFullRunEnding('ending_four_seats');
    controller.startNew(mode: StoryRunMode.audit);

    _advanceUntil(controller, 'ch2_end', allowMechanics: true);
    controller.advance();
    expect(controller.currentId, 'ch2_audit_index');
    expect(controller.flags, contains('audit_index_fragment'));

    controller.advance();
    _advanceUntil(
      controller,
      'ch3_audit_manifest_puzzle',
      allowMechanics: true,
    );
    expect(controller.visibleHighRiskItems, isEmpty);

    controller.completePuzzle('owner_area_slot');
    expect(controller.currentId, 'ch3_audit_manifest_puzzle');
    controller.completePuzzle('slot_lease_interval');
    expect(controller.currentId, 'ch3_audit_manifest_recovered');
    expect(controller.flags, contains('audit_weapon_manifest_found'));
    expect(
      controller.visibleHighRiskItems.map((record) => record.id),
      containsAll(highRiskItemDefinitions.map((item) => item.id)),
    );
    expect(
      controller.visibleHighRiskItems.every(
        (record) => record.state == HighRiskItemState.indexed,
      ),
      isTrue,
    );

    expect(controller.takeHighRiskItem('rescue_axe', '04'), isTrue);
    expect(
      controller.recordParticipantDeath(
        participantId: '08',
        cause: '高危物资导致的死亡',
        responsibleParticipantIds: const ['04'],
        sourceItemId: 'rescue_axe',
      ),
      isTrue,
    );
    expect(controller.livingParticipantIds, isNot(contains('08')));
    expect(
      controller.highRiskItems['rescue_axe']!.state,
      HighRiskItemState.used,
    );

    await controller.saveToSlot(6);
    controller.startNew();
    controller.loadSlot(6);
    expect(controller.runMode, StoryRunMode.audit);
    expect(controller.livingParticipantIds, isNot(contains('08')));
    expect(controller.deathRecords.last.responsibleParticipantIds, {'04'});
    expect(
      controller.highRiskItems['rescue_axe']!.state,
      HighRiskItemState.used,
    );
  });

  test('标准周目不会进入审计专属节点', () async {
    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'ch2_end', allowMechanics: true);
    controller.advance();

    expect(controller.currentId, 'ch3_chapter_title');
    expect(controller.flags, isNot(contains('audit_index_fragment')));
  });

  testWidgets('审计解密与解锁后的标题页适配手机横屏', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.completeFullRunEnding('ending_four_seats');
    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();
    expect(find.text('审计周目'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('审计周目'));
    _advanceUntil(
      controller,
      'ch3_audit_manifest_puzzle',
      allowMechanics: true,
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('audit-field-slot')), findsOneWidget);
    expect(find.byKey(const ValueKey('submit-audit-order')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('audit-field-slot')));
    await tester.tap(find.byKey(const ValueKey('audit-field-lease')));
    await tester.tap(find.byKey(const ValueKey('audit-field-interval')));
    await tester.tap(find.byKey(const ValueKey('submit-audit-order')));
    await tester.pump();

    expect(controller.currentId, 'ch3_audit_manifest_recovered');
    expect(tester.takeException(), isNull);
  });

  test('临时托管的权限、受托人与见证人会随存档恢复', () async {
    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'ch3_delegation_gate', allowMechanics: true);
    controller.completeDelegation(
      permission: 'door',
      trustee: 'hanqi',
      witness: 'yelan',
    );

    expect(controller.currentId, 'ch3_delegate_hanqi');
    expect(
      controller.flags,
      containsAll([
        'ch3_permission_door',
        'ch3_trustee_hanqi',
        'ch3_witness_yelan',
      ]),
    );
    await controller.saveToSlot(4);

    controller.startNew();
    controller.loadSlot(4);
    expect(controller.delegationPermission, 'door');
    expect(controller.delegationTrustee, 'hanqi');
    expect(controller.delegationWitness, 'yelan');
    expect(controller.currentId, 'ch3_delegate_hanqi');
  });

  test('六个结局均先播放完整剧情，再进入结局结算页', () {
    const storyIds = [
      'bad_end',
      'shadow_end',
      'pact_end',
      'xingyao_end',
      'sumi_end',
      'lincheng_end',
    ];
    for (final id in storyIds) {
      final story = storyBeats[id]!;
      final result = storyBeats[story.next]!;
      expect(story.phase, StoryPhase.dialogue);
      expect(story.passages.length, greaterThanOrEqualTo(4));
      expect(story.text.length, greaterThan(250));
      expect(result.phase, StoryPhase.ending);
      expect(result.endingId, isNotNull);
    }
  });

  testWidgets('手机横屏下分支独立于文本区且不越界', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'clause_choice');

    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump(const Duration(seconds: 3));
    for (var page = 0; page < 4; page += 1) {
      await tester.tap(find.byKey(const ValueKey('dialogue-panel')));
      await tester.pump(const Duration(milliseconds: 150));
    }

    expect(find.byKey(const ValueKey('right-control-rail')), findsOneWidget);
    expect(find.byKey(const ValueKey('choice-overlay')), findsOneWidget);
    final dialogueRect = tester.getRect(
      find.byKey(const ValueKey('dialogue-panel')),
    );
    expect(dialogueRect.height, 112);
    expect(dialogueRect.left, 16);
    expect(dialogueRect.width, greaterThan(700));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('dialogue-panel')),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );

    for (final label in ['公开 01 号当前可见条款', '只承认条件需要多人合作', '伪造一个只需自保的条件']) {
      final finder = find.text(label);
      expect(finder, findsOneWidget);
      final rect = tester.getRect(finder);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(844));
      expect(rect.bottom, lessThan(dialogueRect.top));
      expect(rect.bottom, lessThanOrEqualTo(390));
    }
  });

  testWidgets('标题页工具区位于主操作右侧', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const GalgameApp(audioEnabled: false));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();

    final startRect = tester.getRect(find.text('开始游戏'));
    final routeRect = tester.getRect(find.text('线路图'));
    expect(routeRect.left, greaterThan(startRect.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('短横屏结局页不发生布局溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'deduction_gate', allowMechanics: true);
    controller.submitDeduction('suicide');
    _advanceUntil(controller, 'bad_end_result');

    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();

    expect(find.text('无人作证'), findsOneWidget);
    expect(find.text('打开线路图'), findsOneWidget);
    expect(find.text('从最初的苏醒重新开始'), findsOneWidget);
    expect(find.text('返回标题'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('临时托管PDA在手机横屏内完成三方设置', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'ch3_delegation_gate', allowMechanics: true);

    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();

    expect(find.text('01号终端 · 20分钟审计授权'), findsOneWidget);
    expect(find.text('生成三方托管记录'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('delegation-door')));
    await tester.tap(find.byKey(const ValueKey('delegation-hanqi')));
    await tester.tap(find.byKey(const ValueKey('delegation-yelan')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-delegation')));
    await tester.pump();

    expect(controller.currentId, 'ch3_delegate_hanqi');
    expect(controller.delegationPermission, 'door');
    expect(tester.takeException(), isNull);
  });

  test('CASE 02区分署名、受托能力与被重放的旧授权', () async {
    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'ch3_case02_deduction', allowMechanics: true);
    controller.submitDeduction('owner_action');
    expect(controller.currentId, 'ch3_case02_owner_error');
    controller.advance();
    expect(controller.currentId, 'ch3_case02_deduction');
    controller.submitDeduction('lease_replay');
    expect(controller.currentId, 'ch3_case02_resolved');
    expect(controller.flags, contains('case02_solved'));
  });

  testWidgets('现场亮点收纳物品后可在背包拖放组合', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'investigation_gate');

    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();

    for (final id in [
      'terminal_area',
      'wall_box',
      'collar_lock',
      'tool_tray',
    ]) {
      expect(find.byKey(ValueKey('investigation-glint-$id')), findsOneWidget);
    }
    expect(find.text('墙边黑盒'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('investigation-glint-wall_box')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('investigation-glint-tool_tray')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('investigation-glint-wall_box')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('inventory-item-wall_box')), findsNothing);
    expect(find.byTooltip('打开背包'), findsOneWidget);

    await tester.tap(find.byTooltip('打开背包'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('inventory-item-wall_box')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('inventory-item-tool_tray')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('inventory-item-wall_box')));
    await tester.pump();
    expect(find.byKey(const ValueKey('inspection-result')), findsOneWidget);
    expect(find.text('墙边黑盒'), findsWidgets);
    expect(
      find.byKey(const ValueKey('inspection-combination-hint-box_open')),
      findsOneWidget,
    );
    expect(find.textContaining('拖入绝缘拨片'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('inspection-action-box_heat')));
    await tester.pump();
    expect(find.textContaining('仍有明显余温'), findsOneWidget);

    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('inventory-item-wall_box')));
    await tester.pump();
    expect(find.text('有余温的墙边黑盒'), findsWidgets);
    expect(find.textContaining('屏蔽层仍未打开'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('inventory-item-tool_tray')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('inspection-action-tray_pick')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('inventory-item-insulated_pick')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();
    await _longPressDrag(
      tester,
      find.byKey(const ValueKey('inventory-item-insulated_pick')),
      find.byKey(const ValueKey('inventory-drop-wall_box')),
    );
    await tester.pump();

    expect(controller.investigationActions, contains('box_open'));
    expect(controller.investigationClues, contains('repeater'));
    expect(controller.inventoryItems, isNot(contains('insulated_pick')));
    expect(
      find.byKey(const ValueKey('inventory-item-insulated_pick')),
      findsNothing,
    );
    expect(find.textContaining('转发伪造的距离握手'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('inventory-item-wall_box')));
    await tester.pump();
    expect(find.text('拆开的信号中继器'), findsWidgets);
    expect(find.textContaining('屏蔽层已经拆开'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('体育馆调查需要从维修推车取得工具后读取12号', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'clause_choice');
    controller.choose(controller.availableChoices.first);
    _advanceUntil(controller, 'partner_choice');
    controller.choose(controller.availableChoices.first);
    _advanceUntil(controller, 'investigation_gate');
    controller.completeInvestigation({'distance', 'repeater', 'timer'});
    _advanceUntil(controller, 'response_choice');
    controller.choose(controller.availableChoices[1]);
    _advanceUntil(controller, 'decrypt_gate');
    controller.completeTuning();
    _advanceUntil(controller, 'deduction_gate');
    controller.submitDeduction('repeater');
    _advanceUntil(controller, 'ch2_leave_choice');
    controller.choose(
      controller.availableChoices.singleWhere(
        (choice) => choice.next == 'ch2_stay_xingyao',
      ),
    );
    _advanceUntil(controller, 'ch2_gym_investigation');

    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();

    for (final id in [
      'control_inner',
      'north_door_floor',
      'empty_cradle',
      'service_cart',
    ]) {
      expect(find.byKey(ValueKey('investigation-glint-$id')), findsOneWidget);
    }
    await tester.tap(
      find.byKey(const ValueKey('investigation-glint-empty_cradle')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('investigation-glint-service_cart')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('inventory-item-empty_cradle')),
      findsNothing,
    );
    await tester.tap(find.byTooltip('打开背包'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('inventory-item-empty_cradle')));
    await tester.pump();

    expect(find.byKey(const ValueKey('inspection-result')), findsOneWidget);
    expect(find.textContaining('身份槽12'), findsNothing);
    expect(
      find.byKey(const ValueKey('inspection-combination-hint-cradle_read')),
      findsOneWidget,
    );
    expect(find.textContaining('离线测试线'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('inspection-action-cradle_isolate')),
    );
    await tester.pump();
    expect(find.textContaining('七秒间隔'), findsOneWidget);

    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('inventory-item-service_cart')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('inspection-action-cart_lead')));
    await tester.pump();
    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();
    await _longPressDrag(
      tester,
      find.byKey(const ValueKey('inventory-item-offline_test_lead')),
      find.byKey(const ValueKey('inventory-drop-empty_cradle')),
    );
    await tester.pump();

    expect(find.textContaining('身份槽12'), findsOneWidget);
    expect(controller.investigationClues, contains('gym_cradle'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('B-03调查通过离线工具恢复撤销后的托管会话', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(
      controller,
      'ch3_storage_investigation',
      allowMechanics: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();

    for (final id in [
      'sealed_crate',
      'locked_audit_pda',
      'supply_shelf',
      'audit_case',
    ]) {
      expect(find.byKey(ValueKey('investigation-glint-$id')), findsOneWidget);
    }
    await tester.tap(
      find.byKey(const ValueKey('investigation-glint-locked_audit_pda')),
    );
    await tester.tap(
      find.byKey(const ValueKey('investigation-glint-audit_case')),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('打开背包'));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('inventory-item-audit_case')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('inspection-action-case_reader')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('inventory-item-offline_reader')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('inventory-item-locked_audit_pda')),
    );
    await tester.pump();
    expect(find.textContaining('四十二秒'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('inspection-action-pda_clock')));
    await tester.pump();
    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();

    await _longPressDrag(
      tester,
      find.byKey(const ValueKey('inventory-item-offline_reader')),
      find.byKey(const ValueKey('inventory-drop-locked_audit_pda')),
    );
    await tester.pump();

    expect(controller.investigationClues, contains('delegation_gap'));
    expect(controller.inventoryItems, contains('handover_receipt'));
    expect(find.textContaining('撤销后四十二秒'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('inventory-item-locked_audit_pda')),
    );
    await tester.pump();
    expect(find.text('恢复会话记录的审计PDA'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('C-02医疗调查与CASE 03适配手机横屏', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(
      controller,
      'ch4_medical_investigation',
      allowMechanics: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();

    for (final id in [
      'injection_infusion_set',
      'triage_record',
      'patient_headset',
      'medical_test_case',
    ]) {
      expect(find.byKey(ValueKey('investigation-glint-$id')), findsOneWidget);
    }
    expect(find.text('医疗调查 / C-02'), findsOneWidget);
    expect(tester.takeException(), isNull);

    controller.completeInvestigation({
      'clinical_pattern',
      'directed_tone',
      'no_sedative_delivery',
    });
    _advanceUntil(controller, 'ch4_case03_deduction');
    await tester.pump();

    expect(find.text('身体反应'), findsOneWidget);
    expect(find.text('暴露媒介'), findsOneWidget);
    expect(find.text('排除路径'), findsOneWidget);
    expect(find.text('定向声刺激导致前庭性晕厥'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('背包物品栏支持鼠标向左右拖动', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'investigation_gate');
    for (final itemId in [
      'terminal_area',
      'wall_box',
      'collar_lock',
      'tool_tray',
      'folding_ruler',
      'insulated_pick',
      'distance_record',
      'control_inner',
      'north_door_floor',
      'empty_cradle',
      'service_cart',
      'offline_test_lead',
      'folding_magnifier',
    ]) {
      controller.collectInvestigationItem(itemId);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('打开背包'));
    await tester.pump();

    final list = find.byKey(const ValueKey('inventory-scroll-list'));
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);
    final scrollState = tester.state<ScrollableState>(scrollable);
    expect(scrollState.position.maxScrollExtent, greaterThan(0));

    await tester.drag(
      list,
      const Offset(-260, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump(const Duration(milliseconds: 300));
    final offsetAfterLeftDrag = scrollState.position.pixels;
    expect(offsetAfterLeftDrag, greaterThan(0));

    await tester.drag(
      list,
      const Offset(140, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(scrollState.position.pixels, lessThan(offsetAfterLeftDrag));
    expect(tester.takeException(), isNull);
  });

  testWidgets('长背包可选中远端工具后滚动并点击目标组合', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'investigation_gate');
    for (final itemId in [
      'terminal_area',
      'wall_box',
      'collar_lock',
      'tool_tray',
      'folding_ruler',
      'insulated_pick',
      'distance_record',
      'control_inner',
      'north_door_floor',
      'empty_cradle',
      'service_cart',
      'offline_test_lead',
      'folding_magnifier',
      'sealed_crate',
      'locked_audit_pda',
      'supply_shelf',
      'audit_case',
      'uv_lamp',
      'spring_scale',
      'offline_reader',
      'handover_receipt',
    ]) {
      controller.collectInvestigationItem(itemId);
    }
    controller.recordInvestigationAction('control_trace');

    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('打开背包'));
    await tester.pump();

    final list = find.byKey(const ValueKey('inventory-scroll-list'));
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    final scrollState = tester.state<ScrollableState>(scrollable);
    scrollState.position.jumpTo(500);
    await tester.pump(const Duration(milliseconds: 300));
    final offsetBeforeSelection = scrollState.position.pixels;
    await tester.tap(
      find.byKey(const ValueKey('inventory-item-offline_test_lead')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('inventory-select-combine-offline_test_lead')),
    );
    await tester.pump();
    expect(find.textContaining('组合中：离线测试线'), findsOneWidget);

    final updatedScrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    final updatedScrollState = tester.state<ScrollableState>(updatedScrollable);
    expect(
      updatedScrollState.position.pixels,
      closeTo(offsetBeforeSelection, 0.1),
    );
    updatedScrollState.position.jumpTo(0);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.byKey(const ValueKey('inventory-item-control_inner')),
    );
    await tester.pump();

    expect(controller.investigationActions, contains('control_replay'));
    expect(find.textContaining('十分钟撤权计时'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('背包选择与拖放组合都支持目标物和工具双向操作', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'investigation_gate');
    for (final itemId in [
      'wall_box',
      'insulated_pick',
      'control_inner',
      'offline_test_lead',
    ]) {
      controller.collectInvestigationItem(itemId);
    }
    controller.recordInvestigationAction('box_heat');
    controller.recordInvestigationAction('control_trace');

    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('打开背包'));
    await tester.pump();

    await _longPressDrag(
      tester,
      find.byKey(const ValueKey('inventory-item-wall_box')),
      find.byKey(const ValueKey('inventory-drop-insulated_pick')),
    );
    await tester.pump();
    expect(controller.investigationActions, contains('box_open'));

    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('inventory-item-control_inner')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('inventory-select-combine-control_inner')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('inventory-item-offline_test_lead')),
    );
    await tester.pump();

    expect(controller.investigationActions, contains('control_replay'));
    expect(find.textContaining('十分钟撤权计时'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('三种转运机关在手机横屏内均不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(
      controller,
      'ch3_transfer_access_puzzle',
      allowMechanics: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();
    expect(find.text('转运间'), findsOneWidget);
    expect(find.byKey(const ValueKey('access-swipe-card')), findsOneWidget);

    controller.recordPuzzleProgress(
      'ch3_access_card_found',
      grantsItem: 'maintenance_card',
    );
    controller.recordPuzzleProgress(
      'ch3_shift_note_found',
      grantsItem: 'shift_note',
    );
    controller.recordPuzzleProgress(
      'ch3_access_card_swiped',
      consumesItems: const ['maintenance_card'],
    );
    controller.completePuzzle('access_0916');
    _advanceUntil(controller, 'ch3_balance_puzzle', allowMechanics: true);
    await tester.pump();
    expect(find.byKey(const ValueKey('weigh-selected')), findsOneWidget);

    controller.completePuzzle('triangle_cross_ring_dot_square');
    _advanceUntil(controller, 'ch3_slide_puzzle', allowMechanics: true);
    await tester.pump();
    expect(find.byKey(const ValueKey('circuit-slide-board')), findsOneWidget);
    expect(find.byKey(const ValueKey('circuit-empty')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('规则推演先闭合三段证据链再开放死因假说', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'deduction_gate', allowMechanics: true);

    await tester.pumpWidget(
      MaterialApp(
        home: EchoExperience(controller: controller, audioEnabled: false),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();

    expect(find.text('现场事实'), findsOneWidget);
    expect(find.text('规则阈值'), findsOneWidget);
    expect(find.text('实施媒介'), findsOneWidget);
    expect(find.text('主动离开终端'), findsNothing);

    final evidencePositions = <String, Offset>{
      for (final id in [
        'distance',
        'timer',
        'repeater',
        'log',
        'lock',
        'camera',
      ])
        id: tester.getTopLeft(find.byKey(ValueKey('deduction-evidence-$id'))),
    };
    final visualOrder = evidencePositions.entries.toList()
      ..sort((a, b) {
        final row = a.value.dy.compareTo(b.value.dy);
        return row != 0 ? row : a.value.dx.compareTo(b.value.dx);
      });
    expect(
      visualOrder.take(3).map((entry) => entry.key).toSet(),
      isNot(equals({'distance', 'timer', 'repeater'})),
    );

    final distanceCard = find.byKey(
      const ValueKey('deduction-evidence-distance'),
    );
    await tester.ensureVisible(distanceCard);
    await tester.pump();
    await tester.tap(distanceCard);
    await tester.pump();
    expect(
      find.descendant(
        of: distanceCard,
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );
    await tester.tap(distanceCard);
    await tester.pump();
    expect(
      find.descendant(
        of: distanceCard,
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsNothing,
    );
    await tester.tap(distanceCard);
    await tester.pump();
    final timerCard = find.byKey(const ValueKey('deduction-evidence-timer'));
    await tester.ensureVisible(timerCard);
    await tester.pump();
    await tester.tap(timerCard);
    await tester.pump();
    final repeaterCard = find.byKey(
      const ValueKey('deduction-evidence-repeater'),
    );
    await tester.ensureVisible(repeaterCard);
    await tester.pump();
    await tester.tap(repeaterCard);
    await tester.pump();
    await tester.ensureVisible(find.text('检验证据链'));
    await tester.tap(find.text('检验证据链'));
    await tester.pump();

    expect(find.textContaining('证据链闭合'), findsOneWidget);
    await tester.ensureVisible(find.text('主动离开终端'));
    expect(find.text('主动离开终端'), findsOneWidget);
    final suicideHypothesis = find.byKey(
      const ValueKey('deduction-hypothesis-suicide'),
    );
    await tester.tap(suicideHypothesis);
    await tester.pump();
    expect(
      find.descendant(
        of: suicideHypothesis,
        matching: find.byIcon(Icons.radio_button_checked),
      ),
      findsOneWidget,
    );
    await tester.tap(suicideHypothesis);
    await tester.pump();
    expect(
      find.descendant(
        of: suicideHypothesis,
        matching: find.byIcon(Icons.radio_button_checked),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _longPressDrag(
  WidgetTester tester,
  Finder source,
  Finder target,
) async {
  final gesture = await tester.startGesture(tester.getCenter(source));
  await tester.pump(const Duration(milliseconds: 350));
  await gesture.moveTo(tester.getCenter(target));
  await tester.pump();
  await gesture.up();
}

void _advanceUntil(
  StoryController controller,
  String target, {
  bool allowMechanics = false,
}) {
  var guard = 0;
  while (controller.currentId != target && guard < 600) {
    guard += 1;
    switch (controller.phase) {
      case StoryPhase.dialogue:
        if (controller.availableChoices.isNotEmpty) {
          controller.choose(controller.availableChoices.first);
        } else {
          controller.advance();
        }
      case StoryPhase.delegation when allowMechanics:
        controller.completeDelegation(
          permission: 'door',
          trustee: 'hanqi',
          witness: 'yelan',
        );
      case StoryPhase.investigation when allowMechanics:
        controller.completeInvestigation(switch (controller.currentId) {
          'ch2_gym_investigation' => {'gym_control', 'gym_cable', 'gym_cradle'},
          'ch3_storage_investigation' => {
            'seal_reclosed',
            'delegation_gap',
            'weight_mismatch',
          },
          'ch4_medical_investigation' => {
            'clinical_pattern',
            'directed_tone',
            'no_sedative_delivery',
          },
          _ => {'distance', 'repeater', 'timer'},
        });
      case StoryPhase.puzzle when allowMechanics:
        switch (controller.currentId) {
          case 'ch3_transfer_access_puzzle':
            controller.recordPuzzleProgress(
              'ch3_access_card_found',
              grantsItem: 'maintenance_card',
            );
            controller.recordPuzzleProgress(
              'ch3_shift_note_found',
              grantsItem: 'shift_note',
            );
            controller.recordPuzzleProgress(
              'ch3_access_card_swiped',
              consumesItems: const ['maintenance_card'],
            );
            controller.completePuzzle('access_0916');
          case 'ch3_balance_puzzle':
            controller.completePuzzle('triangle_cross_ring_dot_square');
          case 'ch3_slide_puzzle':
            controller.completePuzzle('circuit_complete');
          case 'ch3_audit_manifest_puzzle':
            controller.completePuzzle('slot_lease_interval');
        }
      case StoryPhase.tuning when allowMechanics:
        controller.completeTuning();
      case StoryPhase.deduction when allowMechanics:
        controller.submitDeduction(switch (controller.currentId) {
          'ch3_case02_deduction' => 'lease_replay',
          'ch4_case03_deduction' => 'directed_resonance',
          _ => 'repeater',
        });
      default:
        fail('无法从 ${controller.currentId} 前往 $target');
    }
  }
  expect(controller.currentId, target);
}

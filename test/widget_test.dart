import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galgame/main.dart';
import 'package:galgame/story/story.dart';
import 'package:galgame/story/story_controller.dart';
import 'package:galgame/ui/echo_experience.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('标题界面可以开始死亡游戏并打开 PDA', (tester) async {
    await tester.pumpWidget(const GalgameApp());
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();

    expect(find.text('零点协议'), findsOneWidget);
    expect(find.text('开始游戏'), findsOneWidget);

    await tester.tap(find.text('开始游戏'));
    await tester.pump();

    expect(find.text('168:00:00'), findsWidgets);
    await tester.tap(find.byIcon(Icons.smartphone_rounded));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PDA / PARTICIPANT 01'), findsOneWidget);
    expect(find.text('条款'), findsOneWidget);
    expect(find.text('名册'), findsOneWidget);
    expect(find.text('区域地图'), findsOneWidget);
    expect(find.text('证据'), findsOneWidget);
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
      MaterialApp(home: EchoExperience(controller: controller)),
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
    controller.jumpToNode('game_start');
    expect(controller.currentId, 'game_start');
    expect(controller.canSkipCurrent, isTrue);

    controller.setSkipMode(true);
    expect(controller.skipMode, isTrue);
    expect(controller.cooperation, 0);
    expect(controller.logic, 0);
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
    expect(routeNodes.length, lessThan(35));
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

  testWidgets('陈默登场时加载 08 号透明立绘', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'other_participants');

    await tester.pumpWidget(
      MaterialApp(home: EchoExperience(controller: controller)),
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
      MaterialApp(home: EchoExperience(controller: controller)),
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
      MaterialApp(home: EchoExperience(controller: controller)),
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
      MaterialApp(home: EchoExperience(controller: controller)),
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
  });

  test('第二章围绕旧体育馆封锁与12号空身份展开', () {
    final chapter = storyBeats.values
        .where((beat) => beat.id.startsWith('ch2_'))
        .toList(growable: false);
    expect(chapter.length, 89);
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
    expect(storyBeats['ch2_end']!.next, isNull);
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
      MaterialApp(home: EchoExperience(controller: controller)),
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

    for (final label in ['完整公开 01 号生还条款', '只承认条件需要多人合作', '伪造一个只需自保的条件']) {
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

    await tester.pumpWidget(const GalgameApp());
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
      MaterialApp(home: EchoExperience(controller: controller)),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump();

    expect(find.text('无人作证'), findsOneWidget);
    expect(find.text('打开线路图'), findsOneWidget);
    expect(find.text('从序章重新开始'), findsOneWidget);
    expect(find.text('返回标题'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('现场亮点收纳物品后可在背包拖放组合', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'investigation_gate');

    await tester.pumpWidget(
      MaterialApp(home: EchoExperience(controller: controller)),
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
      MaterialApp(home: EchoExperience(controller: controller)),
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
      MaterialApp(home: EchoExperience(controller: controller)),
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

  testWidgets('规则推演先闭合三段证据链再开放死因假说', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await StoryController.load();
    controller.startNew();
    _advanceUntil(controller, 'deduction_gate', allowMechanics: true);

    await tester.pumpWidget(
      MaterialApp(home: EchoExperience(controller: controller)),
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

    await tester.tap(find.text('1.4m / 23m'));
    await tester.pump();
    await tester.tap(find.text('180 秒'));
    await tester.pump();
    await tester.tap(find.text('中继器'));
    await tester.pump();
    await tester.ensureVisible(find.text('检验证据链'));
    await tester.tap(find.text('检验证据链'));
    await tester.pump();

    expect(find.textContaining('证据链闭合'), findsOneWidget);
    await tester.ensureVisible(find.text('主动离开终端'));
    expect(find.text('主动离开终端'), findsOneWidget);
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
  while (controller.currentId != target && guard < 180) {
    guard += 1;
    switch (controller.phase) {
      case StoryPhase.dialogue:
        if (controller.availableChoices.isNotEmpty) {
          controller.choose(controller.availableChoices.first);
        } else {
          controller.advance();
        }
      case StoryPhase.investigation when allowMechanics:
        controller.completeInvestigation(
          controller.currentId == 'ch2_gym_investigation'
              ? {'gym_control', 'gym_cable', 'gym_cradle'}
              : {'distance', 'repeater', 'timer'},
        );
      case StoryPhase.tuning when allowMechanics:
        controller.completeTuning();
      case StoryPhase.deduction when allowMechanics:
        controller.submitDeduction('repeater');
      default:
        fail('无法从 ${controller.currentId} 前往 $target');
    }
  }
  expect(controller.currentId, target);
}

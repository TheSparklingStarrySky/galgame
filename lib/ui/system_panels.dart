import 'dart:convert';

import 'package:flutter/material.dart';

import '../audio/audio_cues.dart';
import '../audio/game_audio_controller.dart';
import '../story/story.dart';
import '../story/story_controller.dart';

Future<void> showPda(BuildContext context, StoryController controller) {
  final hostContext = context;
  final audio = GameAudioScope.maybeOf(context);
  audio?.playSfx(GameSfx.pdaOpen);
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (context) =>
        _PdaScreen(controller: controller, hostContext: hostContext),
  ).whenComplete(() => audio?.playSfx(GameSfx.pdaClose));
}

Future<void> showSaveLoad(
  BuildContext context,
  StoryController controller, {
  bool loadOnly = false,
}) {
  final audio = GameAudioScope.maybeOf(context);
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (context) => _SaveLoadScreen(
      controller: controller,
      initialLoadMode: loadOnly,
      audio: audio,
    ),
  );
}

Future<void> showHistory(BuildContext context, StoryController controller) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF101617),
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.76,
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.notes_rounded, color: Color(0xFFD8A24A)),
              title: Text('历史回顾'),
            ),
            const Divider(height: 1),
            Expanded(
              child: controller.history.isEmpty
                  ? const Center(child: Text('尚无对话记录'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(18),
                      reverse: true,
                      itemCount: controller.history.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final beat = controller.history.reversed.elementAt(
                          index,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: beat.passages
                              .map(
                                (passage) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        if (speakerName(
                                          passage.speaker,
                                        ).isNotEmpty)
                                          TextSpan(
                                            text:
                                                '${speakerName(passage.speaker)}  ',
                                            style: const TextStyle(
                                              color: Color(0xFFD8A24A),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        TextSpan(text: passage.text),
                                      ],
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFFC7CECA),
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showSettings(BuildContext context, StoryController controller) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF101617),
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.tune_rounded, color: Color(0xFFD8A24A)),
                title: Text('设置'),
              ),
              _SettingSlider(
                label: '背景音乐',
                value: controller.bgmVolume,
                min: 0,
                max: 1,
                onChanged: (value) {
                  controller.setBgmVolume(value);
                  setSheetState(() {});
                },
              ),
              _SettingSlider(
                label: '环境声音',
                value: controller.ambienceVolume,
                min: 0,
                max: 1,
                onChanged: (value) {
                  controller.setAmbienceVolume(value);
                  setSheetState(() {});
                },
              ),
              _SettingSlider(
                label: '界面与音效',
                value: controller.sfxVolume,
                min: 0,
                max: 1,
                onChanged: (value) {
                  controller.setSfxVolume(value);
                  setSheetState(() {});
                },
              ),
              const Divider(height: 22),
              _SettingSlider(
                label: '文字显示速度',
                value: controller.textSpeed,
                min: 0.2,
                max: 1,
                onChanged: (value) {
                  controller.setTextSpeed(value);
                  setSheetState(() {});
                },
              ),
              _SettingSlider(
                label: '自动播放间隔',
                value: controller.autoDelay,
                min: 0.6,
                max: 3.5,
                onChanged: (value) {
                  controller.setAutoDelay(value);
                  setSheetState(() {});
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('允许快进未读文本'),
                subtitle: const Text('关闭时，快进会在首个未读节点停止'),
                value: controller.skipUnread,
                onChanged: (value) {
                  controller.setSkipUnread(value);
                  setSheetState(() {});
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('减少动效'),
                value: controller.reduceMotion,
                onChanged: (value) {
                  controller.setReduceMotion(value);
                  setSheetState(() {});
                },
              ),
              if (controller.phase != StoryPhase.title)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('返回标题'),
                  onTap: () {
                    Navigator.pop(context);
                    controller.returnToTitle();
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showCgGallery(BuildContext context, StoryController controller) {
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (context) => _CollectionScreen(
      title: 'CG 鉴赏',
      icon: Icons.collections_outlined,
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 430,
          childAspectRatio: 16 / 11,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: cgEntries.length,
        itemBuilder: (context, index) {
          final entry = cgEntries[index];
          final unlocked = controller.unlockedCgs.contains(entry.id);
          return _CgTile(entry: entry, unlocked: unlocked);
        },
      ),
    ),
  );
}

Future<void> showEndingReview(
  BuildContext context,
  StoryController controller,
) {
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (context) => _CollectionScreen(
      title: '结局回顾',
      icon: Icons.emoji_events_outlined,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: endingEntries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final ending = endingEntries[index];
          final unlocked = controller.unlockedEndings.contains(ending.id);
          return _EndingTile(
            entry: ending,
            unlocked: unlocked,
            onOpen: unlocked
                ? () {
                    Navigator.pop(context);
                    controller.jumpToNode(ending.nodeId);
                  }
                : null,
          );
        },
      ),
    ),
  );
}

Future<void> showRouteMap(BuildContext context, StoryController controller) {
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (context) => _RouteMapScreen(controller: controller),
  );
}

class _PdaScreen extends StatelessWidget {
  const _PdaScreen({required this.controller, required this.hostContext});

  final StoryController controller;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const ValueKey('pda-device'),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(6),
      child: SafeArea(
        minimum: const EdgeInsets.all(2),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Container(
              padding: const EdgeInsets.fromLTRB(13, 9, 13, 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4C5351),
                    Color(0xFF1C2222),
                    Color(0xFF353C3A),
                  ],
                ),
                border: Border.all(color: const Color(0xFF0A0D0D), width: 2),
                borderRadius: BorderRadius.circular(5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xCC000000),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      SizedBox(
                        height: 21,
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF8FC7B8),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x998FC7B8),
                                    blurRadius: 7,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'ZP-PDA 01 / SECURE TERMINAL',
                              style: TextStyle(
                                color: Color(0xFFCED4D0),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.battery_5_bar_rounded,
                              size: 15,
                              color: Color(0xFFD8A24A),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: const Color(0xFF07100F),
                            border: Border.all(
                              color: const Color(0xFF7A8A84),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xAA000000),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              DefaultTabController(
                                length: 6,
                                child: Column(
                                  children: [
                                    _SystemHeader(
                                      icon: Icons.smartphone_rounded,
                                      title: 'PDA / PARTICIPANT 01',
                                      trailing: Text(
                                        controller.remainingTime,
                                        style: const TextStyle(
                                          color: Color(0xFFD8A24A),
                                          fontWeight: FontWeight.w700,
                                          fontFeatures: [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const TabBar(
                                      isScrollable: true,
                                      dividerColor: Color(0xFF33413D),
                                      indicatorColor: Color(0xFF8FC7B8),
                                      labelColor: Color(0xFFE2E9E5),
                                      unselectedLabelColor: Color(0xFF78847F),
                                      tabs: [
                                        Tab(
                                          icon: Icon(Icons.gavel_outlined),
                                          text: '条款',
                                        ),
                                        Tab(
                                          icon: Icon(Icons.badge_outlined),
                                          text: '名册',
                                        ),
                                        Tab(
                                          icon: Icon(Icons.map_outlined),
                                          text: '区域地图',
                                        ),
                                        Tab(
                                          icon: Icon(Icons.fact_check_outlined),
                                          text: '证据',
                                        ),
                                        Tab(
                                          icon: Icon(Icons.manage_search),
                                          text: '审计',
                                        ),
                                        Tab(
                                          icon: Icon(Icons.apps_rounded),
                                          text: '系统',
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      child: AnimatedBuilder(
                                        animation: controller,
                                        builder: (context, _) => TabBarView(
                                          children: [
                                            _ClauseTab(controller: controller),
                                            _RosterTab(controller: controller),
                                            _SectorMapTab(
                                              controller: controller,
                                            ),
                                            _EvidenceTab(
                                              controller: controller,
                                            ),
                                            _AuditTab(controller: controller),
                                            _PdaSystemTab(
                                              controller: controller,
                                              hostContext: hostContext,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const IgnorePointer(
                                child: CustomPaint(
                                  painter: _PdaScanlinePainter(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Positioned(left: 1, top: 1, child: _PdaScrew()),
                  const Positioned(right: 1, top: 1, child: _PdaScrew()),
                  const Positioned(left: 1, bottom: 1, child: _PdaScrew()),
                  const Positioned(right: 1, bottom: 1, child: _PdaScrew()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PdaScrew extends StatelessWidget {
  const _PdaScrew();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF111515),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF69716E)),
      ),
      child: const Center(
        child: SizedBox(
          width: 5,
          child: Divider(height: 1, thickness: 1, color: Color(0xFF69716E)),
        ),
      ),
    );
  }
}

class _PdaScanlinePainter extends CustomPainter {
  const _PdaScanlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x0800D5A8);
    for (double y = 0; y < size.height; y += 5) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClauseTab extends StatelessWidget {
  const _ClauseTab({required this.controller});

  final StoryController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionLabel(text: 'PERSONAL CLEAR CONDITION'),
        const SizedBox(height: 10),
        const _InfoPanel(
          icon: Icons.fingerprint_rounded,
          title: '01 / 沈砚',
          body: '游戏结束前，使四名存活参与者同时提交相同的“主办者代号”。',
          accent: Color(0xFFD8A24A),
        ),
        const SizedBox(height: 22),
        const _SectionLabel(text: 'GENERAL RULES'),
        const SizedBox(height: 10),
        ...const [
          '终端离开初始持有者两米超过 180 秒，项圈执行死刑。',
          '生还条款只对初始终端生效；他人可以占有或使用终端。',
          '禁止离开设施边界，禁止破坏裁定主机。',
          '规则未禁止的行为全部被允许。',
        ].indexed.map(
          (item) => ListTile(
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF26312E),
              child: Text(
                '${item.$1 + 1}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            title: Text(item.$2),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Metric(label: '合作', value: controller.cooperation),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Metric(label: '逻辑', value: controller.logic),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionLabel(text: 'RELATIONSHIP / TRUST'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Metric(label: '星遥信任', value: controller.xingyaoTrust),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Metric(label: '苏弥信任', value: controller.sumiTrust),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Metric(label: '林澄信任', value: controller.linchengTrust),
            ),
          ],
        ),
      ],
    );
  }
}

class _RosterTab extends StatelessWidget {
  const _RosterTab({required this.controller});

  final StoryController controller;

  static const _participants = [
    ('01', '沈砚', '事故调查员', '四人提交相同代号'),
    ('02', '黎星遥', '信号工程师', '01 号存活，信标在线'),
    ('03', '苏弥', '急诊医师', '至少六人存活'),
    ('04', '韩骐', '救援训练教官', '结束时持有 01 号终端'),
    ('05', '吴峥', '工地领班', '破坏项圈后出局'),
    ('06', '唐弈', '职业赌客', '恰好四人存活'),
    ('07', '林澄', '高三学生 / 18 岁', '与信赖对象共同存活'),
    ('08', '陈默', '系统工程师', '未公开'),
    ('09', '高原', '设备工程师', '未公开'),
    ('10', '周叙', '会计师', '已出局'),
    ('11', '叶岚', '心理咨询师', '未公开'),
    ('12', '未知', '无记录', '未公开'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _participants.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final person = _participants[index];
        final known =
            person.$1 == '01' ||
            controller.seenNodes.contains('xingyao_intro') &&
                person.$1 == '02' ||
            controller.seenNodes.contains('sumi_caution') &&
                person.$1 == '03' ||
            controller.seenNodes.contains('hanqi_intro') && person.$1 == '04' ||
            controller.seenNodes.contains('wu_rejects') && person.$1 == '05' ||
            controller.seenNodes.contains('tang_clause') && person.$1 == '06' ||
            controller.seenNodes.contains('lincheng_intro') &&
                person.$1 == '07' ||
            controller.seenNodes.contains('other_participants') &&
                person.$1 == '08' ||
            controller.seenNodes.contains('gaoyuan_intro') &&
                person.$1 == '09' ||
            controller.seenNodes.contains('zhouxu_intro') &&
                person.$1 == '10' ||
            controller.seenNodes.contains('yelan_intro') && person.$1 == '11';
        final dead =
            person.$1 != '12' &&
            !controller.livingParticipantIds.contains(person.$1);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: dead
                ? const Color(0xFF66312E)
                : const Color(0xFF263C37),
            child: Text(person.$1),
          ),
          title: Text(known ? person.$2 : '未识别参与者'),
          subtitle: Text(known ? person.$3 : 'NO DATA'),
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              known ? person.$4 : '条件未验证',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: dead ? const Color(0xFFD9695F) : const Color(0xFFAAB3AF),
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectorMapTab extends StatelessWidget {
  const _SectorMapTab({required this.controller});

  final StoryController controller;

  static const _sectors = [
    ('control', '监控室', 'A-01', Icons.settings_input_antenna_rounded, true),
    ('medical', '医疗区', 'B-03', Icons.medical_services_outlined, true),
    ('storage', '储物区', 'C-02', Icons.inventory_2_outlined, true),
    ('power', '设备间', 'D-01', Icons.bolt_rounded, false),
    ('archive', '档案库', 'E-04', Icons.folder_copy_outlined, false),
    ('gym', '旧体育馆', 'F-01', Icons.fitness_center_rounded, false),
  ];

  @override
  Widget build(BuildContext context) {
    final gymAlert = controller.seenNodes.contains('ch2_map_update');
    final gymSealed = controller.seenNodes.contains('ch2_seal_complete');
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 620 ? 2 : 3;
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                Expanded(
                  child: _InfoPanel(
                    icon: Icons.lock_clock_outlined,
                    title: '下一封锁区域',
                    body: gymSealed
                        ? 'E-04 档案库 / 23:57:00 后封闭'
                        : gymAlert
                        ? 'F-01 旧体育馆 / 零点执行永久封锁'
                        : 'F-01 旧体育馆 / 24:00:00 后封闭',
                    accent: const Color(0xFFD9695F),
                  ),
                ),
                if (constraints.maxWidth >= 700) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoPanel(
                      icon: Icons.route_outlined,
                      title: '当前路线标记',
                      body: switch (controller.markedSector) {
                        'medical' => 'B-03 医疗区',
                        'storage' => 'C-02 储物区',
                        'archive' => 'E-04 档案库',
                        _ => '未规划',
                      },
                      accent: const Color(0xFF69A89D),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: constraints.maxWidth < 620 ? 1.05 : 1.45,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _sectors.length,
              itemBuilder: (context, index) {
                final sector = _sectors[index];
                final selectable =
                    sector.$1 == 'medical' ||
                    sector.$1 == 'storage' ||
                    sector.$1 == 'archive';
                final selected = controller.markedSector == sector.$1;
                final online = sector.$1 == 'gym'
                    ? gymAlert && !gymSealed
                    : sector.$5;
                return _SectorTile(
                  id: sector.$3,
                  name: sector.$2,
                  icon: sector.$4,
                  online: online,
                  selected: selected,
                  onPressed: selectable
                      ? () => controller.setMarkedSector(
                          selected ? null : sector.$1,
                        )
                      : null,
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              gymSealed
                  ? 'F-01 已永久封锁；12 号白色信号转移至 E-04，下一轮封锁排序可能仍受伪造身份影响。'
                  : gymAlert
                  ? 'F-01 检测到 08、09 与一个无编号白色信号；封锁完成前必须重新确认真人位置。'
                  : '医疗区提高救援合作收益；储物区提高信号追踪收益；档案库会强化林澄的目击记录。',
              style: TextStyle(color: Color(0xFF9EA9A4), height: 1.5),
            ),
          ],
        );
      },
    );
  }
}

class _EvidenceTab extends StatelessWidget {
  const _EvidenceTab({required this.controller});

  final StoryController controller;

  @override
  Widget build(BuildContext context) {
    final entries = <(IconData, String, String, bool)>[
      (
        Icons.social_distance_rounded,
        '距离跳变',
        '10 号终端的回传距离从 1.4m 跳至 23m。',
        controller.foundClues.contains('distance'),
      ),
      (
        Icons.settings_input_antenna_rounded,
        '信号中继器',
        '能够转发并伪造终端的定位握手。',
        controller.foundClues.contains('repeater'),
      ),
      (
        Icons.timer_outlined,
        '181 秒日志',
        '伪造信号在距离死刑触发后恰好一秒中断。',
        controller.flags.contains('relay_log'),
      ),
      (
        Icons.edit_note_rounded,
        '掌心字母 R',
        '只有留在医疗区完成检查时能发现。',
        controller.flags.contains('medical_record'),
      ),
      (
        Icons.draw_outlined,
        '铅笔记录',
        '林澄记录了第二个人在监控室外停留的十八秒。',
        controller.flags.contains('student_witness'),
      ),
      (
        Icons.electrical_services_outlined,
        '桥接控制箱',
        'F-01 控制箱在08号操作前已被桥接，权限撤销是预设陷阱。',
        controller.foundClues.contains('gym_control'),
      ),
      (
        Icons.cable_rounded,
        '新鲜制动索断口',
        '卷帘门钢索遭两次工具剪切，破坏发生在第一天。',
        controller.foundClues.contains('gym_cable'),
      ),
      (
        Icons.phonelink_off_outlined,
        '12号空底座',
        '没有终端的底座仍能循环回放12号有效握手与零距离。',
        controller.foundClues.contains('gym_cradle'),
      ),
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _InfoPanel(
          icon: entry.$4 ? entry.$1 : Icons.lock_outline_rounded,
          title: entry.$4 ? entry.$2 : '未取得证据',
          body: entry.$4 ? entry.$3 : '继续推进调查以解锁记录。',
          accent: entry.$4 ? const Color(0xFF69A89D) : const Color(0xFF59635F),
        );
      },
    );
  }
}

class _AuditTab extends StatelessWidget {
  const _AuditTab({required this.controller});

  final StoryController controller;

  @override
  Widget build(BuildContext context) {
    final visibleItems = controller.visibleHighRiskItems.toList(
      growable: false,
    );
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoPanel(
                icon: controller.runMode == StoryRunMode.audit
                    ? Icons.manage_search_rounded
                    : Icons.shield_outlined,
                title: controller.runMode == StoryRunMode.audit
                    ? '审计周目'
                    : '标准周目',
                body: controller.flags.contains('audit_index_fragment')
                    ? '灰色索引：已取得'
                    : '灰色索引：无记录',
                accent: controller.runMode == StoryRunMode.audit
                    ? const Color(0xFFD8A24A)
                    : const Color(0xFF69A89D),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoPanel(
                icon: Icons.groups_2_outlined,
                title: '存活 ${controller.livingParticipantIds.length}',
                body: '死亡记录 ${controller.deathRecords.length} 条',
                accent: const Color(0xFF69A89D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionLabel(text: 'HIGH-RISK MANIFEST'),
        const SizedBox(height: 8),
        if (visibleItems.isEmpty)
          const _InfoPanel(
            icon: Icons.lock_outline_rounded,
            title: '目录未恢复',
            body: '当前离线记录中没有可验证的封存条目。',
            accent: Color(0xFF59635F),
          )
        else
          ...visibleItems.map((record) {
            final definition = highRiskItemDefinitions.firstWhere(
              (item) => item.id == record.id,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InfoPanel(
                icon: _highRiskIcon(record.state),
                title: definition.name,
                body:
                    '${definition.area} / ${definition.category} / ${_highRiskStateLabel(record)}',
                accent: _highRiskColor(record.state),
              ),
            );
          }),
        const SizedBox(height: 14),
        const _SectionLabel(text: 'CASUALTY LOG'),
        const SizedBox(height: 8),
        if (controller.deathRecords.isEmpty)
          const _InfoPanel(
            icon: Icons.monitor_heart_outlined,
            title: '暂无死亡记录',
            body: '当前存活名单尚未发生变更。',
            accent: Color(0xFF69A89D),
          )
        else
          ...controller.deathRecords.reversed.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InfoPanel(
                icon: Icons.person_off_outlined,
                title: '${record.participantId} 号 / ${record.cause}',
                body: _deathRecordBody(record),
                accent: const Color(0xFFD9695F),
              ),
            ),
          ),
      ],
    );
  }

  static String _highRiskStateLabel(HighRiskItemRecord record) =>
      switch (record.state) {
        HighRiskItemState.sealed => '未取得',
        HighRiskItemState.indexed => '封存',
        HighRiskItemState.held => '持有人 ${record.holderId ?? '不明'}',
        HighRiskItemState.used => '已使用',
        HighRiskItemState.missing => '去向不明',
      };

  static IconData _highRiskIcon(HighRiskItemState state) => switch (state) {
    HighRiskItemState.sealed => Icons.lock_outline_rounded,
    HighRiskItemState.indexed => Icons.inventory_2_outlined,
    HighRiskItemState.held => Icons.pan_tool_alt_outlined,
    HighRiskItemState.used => Icons.warning_amber_rounded,
    HighRiskItemState.missing => Icons.help_outline_rounded,
  };

  static Color _highRiskColor(HighRiskItemState state) => switch (state) {
    HighRiskItemState.indexed => const Color(0xFF69A89D),
    HighRiskItemState.held => const Color(0xFFD8A24A),
    HighRiskItemState.used => const Color(0xFFD9695F),
    HighRiskItemState.missing => const Color(0xFFE08A58),
    HighRiskItemState.sealed => const Color(0xFF59635F),
  };

  static String _deathRecordBody(ParticipantDeathRecord record) {
    final day = record.timelineMinute ~/ (24 * 60) + 1;
    final minuteOfDay = record.timelineMinute % (24 * 60);
    final hour = minuteOfDay ~/ 60;
    final minute = minuteOfDay % 60;
    final time =
        'DAY $day / ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    final responsibility = record.responsibleParticipantIds.isEmpty
        ? '责任未确认'
        : '责任记录 ${record.responsibleParticipantIds.join(' / ')}';
    return '$time / $responsibility';
  }
}

class _PdaSystemTab extends StatelessWidget {
  const _PdaSystemTab({required this.controller, required this.hostContext});

  final StoryController controller;
  final BuildContext hostContext;

  void _open(
    BuildContext context,
    Future<void> Function(BuildContext context) action,
  ) {
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hostContext.mounted) action(hostContext);
    });
  }

  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, String, VoidCallback?)>[
      (
        Icons.save_outlined,
        '存档',
        '保存当前节点与状态',
        controller.phase == StoryPhase.title
            ? null
            : () => _open(context, (host) => showSaveLoad(host, controller)),
      ),
      (
        Icons.folder_open_rounded,
        '读档',
        '读取八个手动存档槽',
        () => _open(
          context,
          (host) => showSaveLoad(host, controller, loadOnly: true),
        ),
      ),
      (
        Icons.notes_rounded,
        '历史回顾',
        '查看本次游戏的对话记录',
        () => _open(context, (host) => showHistory(host, controller)),
      ),
      (
        Icons.account_tree_outlined,
        '剧情线路图',
        '查看分支并跳转已见节点',
        () => _open(context, (host) => showRouteMap(host, controller)),
      ),
      (
        Icons.tune_rounded,
        '设置',
        '调整文字、自动播放与动效',
        () => _open(context, (host) => showSettings(host, controller)),
      ),
      (
        Icons.collections_outlined,
        'CG 鉴赏',
        '查看已解锁的关键画面',
        () => _open(context, (host) => showCgGallery(host, controller)),
      ),
      (
        Icons.emoji_events_outlined,
        '结局回顾',
        '查看已达成的结局记录',
        () => _open(context, (host) => showEndingReview(host, controller)),
      ),
      (
        Icons.home_outlined,
        '返回标题',
        '退出当前游戏界面',
        controller.phase == StoryPhase.title
            ? null
            : () {
                Navigator.pop(context);
                controller.returnToTitle();
              },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(18),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: columns == 4 ? 2.15 : 2.45,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _SystemActionTile(
              icon: action.$1,
              title: action.$2,
              subtitle: action.$3,
              onPressed: action.$4,
            );
          },
        );
      },
    );
  }
}

class _SystemActionTile extends StatelessWidget {
  const _SystemActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF141B1B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFF34423E)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                color: onPressed == null
                    ? const Color(0xFF59635F)
                    : const Color(0xFFD8A24A),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9EA9A4),
                        fontSize: 11,
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

class _SaveLoadScreen extends StatefulWidget {
  const _SaveLoadScreen({
    required this.controller,
    required this.initialLoadMode,
    required this.audio,
  });

  final StoryController controller;
  final bool initialLoadMode;
  final GameAudioController? audio;

  @override
  State<_SaveLoadScreen> createState() => _SaveLoadScreenState();
}

class _SaveLoadScreenState extends State<_SaveLoadScreen> {
  late bool _loadMode;

  @override
  void initState() {
    super.initState();
    _loadMode = widget.initialLoadMode;
  }

  @override
  Widget build(BuildContext context) {
    final canSave = widget.controller.phase != StoryPhase.title;
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF090E0F),
      child: SafeArea(
        child: Column(
          children: [
            _SystemHeader(
              icon: _loadMode ? Icons.folder_open_rounded : Icons.save_outlined,
              title: _loadMode ? '读取进度' : '保存进度',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.save_outlined),
                    label: Text('存档'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.folder_open_rounded),
                    label: Text('读档'),
                  ),
                ],
                selected: {_loadMode},
                onSelectionChanged: (selection) {
                  if (!canSave && !selection.first) return;
                  setState(() => _loadMode = selection.first);
                },
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: widget.controller,
                builder: (context, _) => GridView.builder(
                  padding: const EdgeInsets.all(18),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 420,
                    childAspectRatio: 2.1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: StoryController.slotCount,
                  itemBuilder: (context, index) {
                    final snapshot = widget.controller.saveSlots[index];
                    return _SaveSlotTile(
                      index: index,
                      snapshot: snapshot,
                      loadMode: _loadMode,
                      enabled: _loadMode ? snapshot != null : canSave,
                      onPressed: () async {
                        if (_loadMode) {
                          widget.controller.loadSlot(index);
                          widget.audio?.playSfx(GameSfx.loadComplete);
                          if (context.mounted) Navigator.pop(context);
                        } else {
                          await widget.controller.saveToSlot(index);
                          widget.audio?.playSfx(GameSfx.saveComplete);
                        }
                      },
                      onDelete: snapshot == null
                          ? null
                          : () => widget.controller.deleteSlot(index),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionScreen extends StatelessWidget {
  const _CollectionScreen({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF090E0F),
      child: SafeArea(
        child: Column(
          children: [
            _SystemHeader(icon: icon, title: title),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _RouteMapScreen extends StatefulWidget {
  const _RouteMapScreen({required this.controller});

  final StoryController controller;

  @override
  State<_RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<_RouteMapScreen> {
  final TransformationController _transformationController =
      TransformationController();
  Size? _centeredViewport;
  bool _centerPending = false;

  StoryController get controller => widget.controller;

  RouteNode get _focusedNode {
    for (final node in routeNodes) {
      if (node.id == controller.currentId) return node;
    }
    for (final beat in controller.history.reversed) {
      for (final node in routeNodes) {
        if (node.id == beat.id) return node;
      }
    }
    for (final node in routeNodes.reversed) {
      if (controller.seenNodes.contains(node.id)) return node;
    }
    return routeNodes.first;
  }

  void _scheduleCenter(Size viewport, RouteNode node) {
    if (_centeredViewport == viewport || _centerPending) return;
    _centerPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerPending = false;
      if (!mounted) return;
      const tileSize = Size(126, 62);
      final nodeCenter = Offset(
        node.x + tileSize.width / 2,
        node.y + tileSize.height / 2,
      );
      final viewportCenter = Offset(viewport.width / 2, viewport.height / 2);
      _transformationController.value = Matrix4.translationValues(
        viewportCenter.dx - nodeCenter.dx,
        viewportCenter.dy - nodeCenter.dy,
        0,
      );
      _centeredViewport = viewport;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focusedNode = _focusedNode;
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF090E0F),
      child: SafeArea(
        child: Column(
          children: [
            _SystemHeader(
              icon: Icons.account_tree_outlined,
              title: '剧情线路图',
              trailing: Text(
                '关键节点 ${controller.seenRouteNodeCount} / ${routeNodes.length}',
                style: const TextStyle(color: Color(0xFF9EA9A4)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '仅显示规则揭示、死亡事件、关键选择、调查推理与结局。已到达节点可跳转并恢复当时状态。',
                  style: TextStyle(color: Color(0xFF9EA9A4)),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewport = constraints.biggest;
                  _scheduleCenter(viewport, focusedNode);
                  return InteractiveViewer(
                    key: const ValueKey('route-map-viewport'),
                    transformationController: _transformationController,
                    constrained: false,
                    minScale: 0.45,
                    maxScale: 1.5,
                    boundaryMargin: const EdgeInsets.all(180),
                    child: SizedBox(
                      width: routeNodes.last.x + 180,
                      height: 500,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _RouteConnectionsPainter(
                                controller.seenNodes,
                              ),
                            ),
                          ),
                          ...routeNodes.map((node) {
                            final beat = storyBeats[node.id]!;
                            final seen = controller.seenNodes.contains(node.id);
                            final current =
                                focusedNode.id == node.id &&
                                controller.phase != StoryPhase.title;
                            return Positioned(
                              left: node.x,
                              top: node.y,
                              width: 126,
                              height: 62,
                              child: _RouteNodeTile(
                                key: ValueKey('route-node-${node.id}'),
                                label: beat.label,
                                seen: seen,
                                current: current,
                                ending: beat.phase == StoryPhase.ending,
                                onPressed: seen
                                    ? () {
                                        if (controller.jumpToNode(node.id) &&
                                            context.mounted) {
                                          GameAudioScope.maybeOf(
                                            context,
                                          )?.playSfx(GameSfx.routeJump);
                                          Navigator.pop(context);
                                        }
                                      }
                                    : null,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteConnectionsPainter extends CustomPainter {
  const _RouteConnectionsPainter(this.seenNodes);

  final Set<String> seenNodes;

  @override
  void paint(Canvas canvas, Size size) {
    final positions = {for (final node in routeNodes) node.id: node};
    for (final node in routeNodes) {
      final targets = routeConnections[node.id] ?? const <String>[];
      for (final targetId in targets) {
        final target = positions[targetId];
        if (target == null) continue;
        final active =
            seenNodes.contains(node.id) && seenNodes.contains(targetId);
        final paint = Paint()
          ..color = active ? const Color(0xFF69A89D) : const Color(0xFF2A3431)
          ..strokeWidth = active ? 2 : 1
          ..style = PaintingStyle.stroke;
        final start = Offset(node.x + 126, node.y + 31);
        final end = Offset(target.x, target.y + 31);
        final middle = (start.dx + end.dx) / 2;
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(middle, start.dy)
          ..lineTo(middle, end.dy)
          ..lineTo(end.dx, end.dy);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RouteConnectionsPainter oldDelegate) =>
      oldDelegate.seenNodes != seenNodes;
}

class _SystemHeader extends StatelessWidget {
  const _SystemHeader({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          const SizedBox(width: 12),
          IconButton(
            tooltip: '关闭',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: const Color(0xFFD8A24A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null) trailing!,
          const SizedBox(width: 18),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF141B1B),
        border: Border.all(color: const Color(0xFF34423E)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(color: Color(0xFFADB7B2), height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151D1C),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFAAB3AF)),
            ),
          ),
          Text(
            '$value',
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

class _SectorTile extends StatelessWidget {
  const _SectorTile({
    required this.id,
    required this.name,
    required this.icon,
    required this.online,
    required this.selected,
    required this.onPressed,
  });

  final String id;
  final String name;
  final IconData icon;
  final bool online;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF23443D) : const Color(0xFF141B1B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: selected ? const Color(0xFF69A89D) : const Color(0xFF34423E),
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: online
                    ? const Color(0xFF8FC7B8)
                    : const Color(0xFF69736F),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              Text(
                id,
                style: const TextStyle(color: Color(0xFF8E9994), fontSize: 11),
              ),
              if (selected) ...[
                const SizedBox(height: 6),
                const Text(
                  '已标记',
                  style: TextStyle(color: Color(0xFFD8A24A), fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveSlotTile extends StatelessWidget {
  const _SaveSlotTile({
    required this.index,
    required this.snapshot,
    required this.loadMode,
    required this.enabled,
    required this.onPressed,
    required this.onDelete,
  });

  final int index;
  final SaveSnapshot? snapshot;
  final bool loadMode;
  final bool enabled;
  final VoidCallback onPressed;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('save-slot-$index'),
      color: const Color(0xFF141B1B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFF34423E)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (snapshot != null) ...[
              _SaveThumbnail(snapshot: snapshot!),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xD90A0E0F),
                      Color(0x290A0E0F),
                      Color(0x7A0A0E0F),
                    ],
                    stops: [0, 0.52, 1],
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: snapshot == null
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xD926312E),
                    child: Text('${index + 1}'.padLeft(2, '0')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: snapshot == null
                        ? const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'EMPTY SLOT',
                              style: TextStyle(color: Color(0xFF6F7975)),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snapshot!.nodeLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 5),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(snapshot!.savedAt),
                                style: const TextStyle(
                                  color: Color(0xFFE0E6E2),
                                  fontSize: 12,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 5),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: '删除存档',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    )
                  else
                    Icon(
                      loadMode
                          ? Icons.folder_open_rounded
                          : Icons.save_outlined,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTimestamp(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _SaveThumbnail extends StatelessWidget {
  const _SaveThumbnail({required this.snapshot});

  final SaveSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final encoded = snapshot.thumbnailBase64;
    if (encoded == null || encoded.isEmpty) {
      return _SnapshotThumbnail(snapshot: snapshot);
    }
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(
          base64Decode(encoded),
          key: ValueKey('save-thumbnail-${snapshot.currentId}'),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, _, _) =>
              _SnapshotThumbnail(snapshot: snapshot),
        ),
      );
    } on FormatException {
      return _SnapshotThumbnail(snapshot: snapshot);
    }
  }
}

class _SnapshotThumbnail extends StatelessWidget {
  const _SnapshotThumbnail({required this.snapshot});

  final SaveSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final asset = snapshot.thumbnailAsset;
    if (asset == null || asset.isEmpty) return const _MissingThumbnail();
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            key: ValueKey('save-thumbnail-${snapshot.currentId}'),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, _, _) => const _MissingThumbnail(),
          ),
          if (snapshot.thumbnailText case final text? when text.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 7, 14, 9),
                color: const Color(0xD9080B0C),
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF2F4F1),
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MissingThumbnail extends StatelessWidget {
  const _MissingThumbnail();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1011),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2D3936)),
      ),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 20,
          color: Color(0xFF69736F),
        ),
      ),
    );
  }
}

class _CgTile extends StatelessWidget {
  const _CgTile({required this.entry, required this.unlocked});

  final CgEntry entry;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF141B1B),
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: unlocked
            ? () => showDialog<void>(
                context: context,
                builder: (context) => _CgViewer(entry: entry),
              )
            : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (unlocked)
              Image.asset(entry.coverAsset, fit: BoxFit.cover)
            else
              const ColoredBox(
                color: Color(0xFF111616),
                child: Center(
                  child: Icon(Icons.lock_outline_rounded, size: 36),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: const Color(0xD9080B0C),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unlocked ? entry.title : '未解锁',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      unlocked ? entry.caption : '???',
                      style: const TextStyle(
                        color: Color(0xFF9EA9A4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CgViewer extends StatefulWidget {
  const _CgViewer({required this.entry});

  final CgEntry entry;

  @override
  State<_CgViewer> createState() => _CgViewerState();
}

class _CgViewerState extends State<_CgViewer> {
  int _index = 0;

  void _nextFrame() {
    setState(() => _index = (_index + 1) % widget.entry.assets.length);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            key: const ValueKey('cg-sequence-viewer'),
            behavior: HitTestBehavior.opaque,
            onTap: _nextFrame,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: Image.asset(
                widget.entry.assets[_index],
                key: ValueKey(widget.entry.assets[_index]),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xB3000000),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                child: Text(
                  '${_index + 1} / ${widget.entry.assets.length}',
                  style: const TextStyle(
                    color: Color(0xFFF2F4F1),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton.filled(
              tooltip: '关闭',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndingTile extends StatelessWidget {
  const _EndingTile({
    required this.entry,
    required this.unlocked,
    required this.onOpen,
  });

  final EndingEntry entry;
  final bool unlocked;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: const Color(0xFF141B1B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFF34423E)),
      ),
      leading: Icon(
        unlocked ? Icons.emoji_events_outlined : Icons.lock_outline_rounded,
      ),
      title: Text(unlocked ? entry.title : '???'),
      subtitle: Text(unlocked ? entry.subtitle : '达成对应结局后解锁'),
      trailing: Text(unlocked ? entry.rank : '--'),
      onTap: onOpen,
    );
  }
}

class _RouteNodeTile extends StatelessWidget {
  const _RouteNodeTile({
    super.key,
    required this.label,
    required this.seen,
    required this.current,
    required this.ending,
    required this.onPressed,
  });

  final String label;
  final bool seen;
  final bool current;
  final bool ending;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = current
        ? const Color(0xFFD8A24A)
        : seen
        ? const Color(0xFF315A50)
        : const Color(0xFF171D1C);
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(
          color: current
              ? const Color(0xFFF0D08F)
              : seen
              ? const Color(0xFF69A89D)
              : const Color(0xFF303836),
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                ending
                    ? Icons.flag_outlined
                    : seen
                    ? Icons.circle
                    : Icons.lock_outline_rounded,
                size: 13,
                color: current ? const Color(0xFF101413) : null,
              ),
              const SizedBox(height: 4),
              Text(
                seen ? label : 'LOCKED',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: current ? const Color(0xFF101413) : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingSlider extends StatelessWidget {
  const _SettingSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Expanded(
          flex: 2,
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFD8A24A),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

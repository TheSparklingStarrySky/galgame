enum StoryPhase { title, dialogue, investigation, tuning, deduction, ending }

enum SceneKey { dormitory, corridor, assemblyHall, controlRoom }

enum Speaker {
  narration,
  shenYan,
  liXingyao,
  suMi,
  hanQi,
  wuZheng,
  tangYi,
  linCheng,
  chenMo,
  gaoYuan,
  zhouXu,
  yeLan,
  administrator,
}

class ChoiceEffect {
  const ChoiceEffect({
    this.xingyao = 0,
    this.sumi = 0,
    this.lincheng = 0,
    this.logic = 0,
    this.cooperation = 0,
    this.flag,
  });

  final int xingyao;
  final int sumi;
  final int lincheng;
  final int logic;
  final int cooperation;
  final String? flag;
}

class StoryChoice {
  const StoryChoice({
    required this.label,
    required this.caption,
    required this.next,
    this.effect = const ChoiceEffect(),
    this.requiresFlag,
  });

  final String label;
  final String caption;
  final String next;
  final ChoiceEffect effect;
  final String? requiresFlag;
}

class StoryBeat {
  const StoryBeat({
    required this.id,
    required this.label,
    required this.text,
    required this.next,
    this.speaker = Speaker.narration,
    this.scene = SceneKey.assemblyHall,
    this.phase = StoryPhase.dialogue,
    this.choices = const [],
    this.passageSpeakers = const [],
    this.portraitMood = 'neutral',
    this.cgId,
    this.endingId,
  });

  final String id;
  final String label;
  final String text;
  final String? next;
  final Speaker speaker;
  final SceneKey scene;
  final StoryPhase phase;
  final List<StoryChoice> choices;
  final List<Speaker> passageSpeakers;
  final String portraitMood;
  final String? cgId;
  final String? endingId;

  List<StoryPassage> get passages {
    if (passageSpeakers.isEmpty) {
      return [StoryPassage(speaker: speaker, text: text)];
    }

    final paragraphs = text.split('\n');
    assert(
      paragraphs.length == passageSpeakers.length,
      '$id has ${paragraphs.length} paragraphs but '
      '${passageSpeakers.length} passage speakers',
    );
    return [
      for (var index = 0; index < paragraphs.length; index++)
        StoryPassage(speaker: passageSpeakers[index], text: paragraphs[index]),
    ];
  }
}

class StoryPassage {
  const StoryPassage({required this.speaker, required this.text});

  final Speaker speaker;
  final String text;
}

class RouteNode {
  const RouteNode(this.id, this.x, this.y);

  final String id;
  final double x;
  final double y;
}

class CgEntry {
  const CgEntry({
    required this.id,
    required this.title,
    required this.caption,
    required this.asset,
  });

  final String id;
  final String title;
  final String caption;
  final String asset;
}

class EndingEntry {
  const EndingEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.rank,
    required this.nodeId,
  });

  final String id;
  final String title;
  final String subtitle;
  final String rank;
  final String nodeId;
}

const storyBeats = <String, StoryBeat>{
  'game_start': StoryBeat(
    id: 'game_start',
    label: '苏醒',
    speaker: Speaker.narration,
    scene: SceneKey.dormitory,
    cgId: 'cg_dormitory',
    text: '意识先于视线恢复。沈砚闻到旧床垫里的消毒水味，听见荧光灯管在头顶嗡嗡作响。那声音过于均匀，反而让每一次呼吸都显得异常清晰。',
    next: 'wake_senses',
  ),
  'wake_senses': StoryBeat(
    id: 'wake_senses',
    label: '没有窗的房间',
    speaker: Speaker.shenYan,
    scene: SceneKey.dormitory,
    text:
        '我没有立刻起身。天花板有大片受潮后的黄斑，墙上时钟停在零点十二分，钢制门上只有一块从外侧封住的观察窗。房间里没有真正的窗，也没有任何能证明早晚的光。',
    passageSpeakers: [Speaker.narration],
    next: 'memory_gap',
  ),
  'memory_gap': StoryBeat(
    id: 'memory_gap',
    label: '断裂的记忆',
    speaker: Speaker.shenYan,
    scene: SceneKey.dormitory,
    text:
        '最后完整的记忆停在昨晚。我离开事故调查所，在地下停车场听见了不紧不慢的脚步声。回头时只看到一只戴灰手套的手，随后口鼻被带甜味的湿布捂住。',
    passageSpeakers: [Speaker.narration],
    next: 'sedative_trace',
  ),
  'sedative_trace': StoryBeat(
    id: 'sedative_trace',
    label: '麻醉痕迹',
    speaker: Speaker.shenYan,
    scene: SceneKey.dormitory,
    text:
        '舌根还留着苦味，后脑像塞了湿棉花。我用指甲提醒自己保持清醒，同时回想车位周围的监控、出口和可能的目击者。这是职业习惯：在恐惧接管思考之前，先把确定的事实留下。',
    passageSpeakers: [Speaker.narration],
    next: 'self_check',
  ),
  'self_check': StoryBeat(
    id: 'self_check',
    label: '身体确认',
    speaker: Speaker.shenYan,
    scene: SceneKey.dormitory,
    text:
        '手指能正常屈伸，视线没有重影，衣服也没有被更换。左手腕内侧有一个细小针孔，周围已经发青。绑架者愿意精确控制药量，说明他们至少不想让我死在被带来的路上。这不是安慰，只是更坏的可能性。',
    passageSpeakers: [Speaker.narration],
    next: 'room_check',
  ),
  'room_check': StoryBeat(
    id: 'room_check',
    label: '确认现状',
    speaker: Speaker.shenYan,
    scene: SceneKey.dormitory,
    text:
        '外套口袋里的东西被分类拿走了：手机、钥匙、钱包和身份证全部消失，一张超市小票和半盒薄荷糖却还在。这不像临时起意的抢劫。对方知道哪些东西能暴露位置，也知道我是谁。',
    passageSpeakers: [Speaker.narration],
    next: 'door_test',
  ),
  'door_test': StoryBeat(
    id: 'door_test',
    label: '锁死的门',
    speaker: Speaker.shenYan,
    scene: SceneKey.dormitory,
    text:
        '门把手只能向下压半寸。我先用肩膀试了一次，又拆下钢笔去探锁舌，都没有用。门框深处传来继电器的轻响，这是电控锁。与其说我被关在房里，不如说有人正在另一端决定什么时候放我出去。',
    passageSpeakers: [Speaker.narration],
    next: 'terminal_test',
  ),
  'terminal_test': StoryBeat(
    id: 'terminal_test',
    label: '黑色终端',
    speaker: Speaker.shenYan,
    scene: SceneKey.dormitory,
    text:
        '书桌中央放着一台黑色终端，尺寸像旧式手机，表面却没有品牌、螺丝或电源键。我尝试按压屏幕、长按边缘，它始终没有反应。背面只印着一个白色数字：01。',
    passageSpeakers: [Speaker.narration],
    next: 'collar_discovery',
  ),
  'collar_discovery': StoryBeat(
    id: 'collar_discovery',
    label: '黑色项圈',
    speaker: Speaker.shenYan,
    scene: SceneKey.dormitory,
    text:
        '直到我摸向后颈，才发现那不是衣领。一圈乌黑金属紧贴着皮肤，宽度近两指，没有锁孔，也找不到铰链。指腹划过左侧接缝时，内部传来一下极轻的震动，像是某种设备在确认我还活着。',
    passageSpeakers: [Speaker.narration],
    next: 'collar_panic',
  ),
  'collar_panic': StoryBeat(
    id: 'collar_panic',
    label: '恐惧的形状',
    speaker: Speaker.shenYan,
    scene: SceneKey.dormitory,
    text:
        '我的手本能地想去扯它，却在用力前停住。金属内缘紧贴着颈动脉，稍微转头就能感觉到凉意。绑架、药物、编号终端，再加上这只项圈。所有东西都像已经排练过很多次，只有被放进其中的人毫无准备。',
    passageSpeakers: [Speaker.narration],
    next: 'wall_listening',
  ),
  'wall_listening': StoryBeat(
    id: 'wall_listening',
    label: '墙后的人',
    speaker: Speaker.narration,
    scene: SceneKey.dormitory,
    text:
        '隔壁忽然传来一连串砸门声。有个男人在喊“放我出去”，更远的地方也有人回应。声音一个接一个醒来，惊慌、愤怒、带着哭腔。这里不只关着一个人。',
    next: 'door_release',
  ),
  'door_release': StoryBeat(
    id: 'door_release',
    label: '门锁解除',
    speaker: Speaker.administrator,
    scene: SceneKey.dormitory,
    text:
        '墙上扬声器亮起白灯，一道经过处理、分不出性别的声音压过了砸门声。\n“请所有人员在五分钟内前往一层集合厅。逾时者将被强制带离。”\n“你们是谁？”\n我对着扬声器追问。它没有回答，门锁却咔哒一声自行弹开。',
    passageSpeakers: [
      Speaker.narration,
      Speaker.administrator,
      Speaker.shenYan,
      Speaker.narration,
    ],
    next: 'corridor_encounter',
  ),
  'corridor_encounter': StoryBeat(
    id: 'corridor_encounter',
    label: '走廊里的陌生人',
    speaker: Speaker.liXingyao,
    scene: SceneKey.corridor,
    text:
        '“先别碰脖子上的东西。”\n对面房门旁站着一个短黑发女人。她的苔绿工装外套还沾着机柜灰，颈间挂着老式模拟耳机，右手紧握一台印有02的终端。她的语气很稳，指节却因为用力而发白。',
    passageSpeakers: [Speaker.liXingyao, Speaker.narration],
    next: 'corridor_standoff',
  ),
  'corridor_standoff': StoryBeat(
    id: 'corridor_standoff',
    label: '互相戒备',
    speaker: Speaker.shenYan,
    scene: SceneKey.corridor,
    text:
        '我停在她三步之外，没有继续靠近。她也在看我的手和口袋，确认我有没有藏着武器。\n“你知道这里是哪？”\n“不知道。”她回答得太快，又立刻补了一句，“我也不认识广播里的人。”',
    passageSpeakers: [Speaker.narration, Speaker.shenYan, Speaker.liXingyao],
    next: 'xingyao_name',
  ),
  'xingyao_name': StoryBeat(
    id: 'xingyao_name',
    label: '姓名与编号',
    speaker: Speaker.liXingyao,
    scene: SceneKey.corridor,
    text:
        '“黎星遥。”她先报了名字，却没有伸手，“我检查过这层的无线环境，手机、对讲机和卫星频段都是干净的空白。要么我们在地下，要么整栋楼做了屏蔽。”\n我也告诉她自己叫沈砚。在这种地方，姓名至少比背后的01和02更像人。',
    passageSpeakers: [Speaker.liXingyao, Speaker.narration],
    next: 'shared_confusion',
  ),
  'shared_confusion': StoryBeat(
    id: 'shared_confusion',
    label: '同样的空白',
    speaker: Speaker.shenYan,
    scene: SceneKey.corridor,
    text:
        '星遥的最后记忆也停在昨夜；她在公司机房查看一次不存在的断线告警，身后的门忽然开了。我们暂时找不到共同点。唯一能确定的是，她看见我的项圈时眼神里的惊讶，不像伪装。',
    passageSpeakers: [Speaker.narration],
    next: 'corridor_group',
  ),
  'corridor_group': StoryBeat(
    id: 'corridor_group',
    label: '陆续打开的门',
    speaker: Speaker.narration,
    scene: SceneKey.corridor,
    text:
        '两侧房门陆续打开。一名穿医用外套的女人扶着墙走出来，先摸了摸自己的脉搏；一个高大男人拎着拆下的床架钢管，警惕地要求每个人保持距离。更远处有个双马尾女生抱紧书包，强忍着没让眼泪掉下来。每个人脖子上都有同样的黑环。',
    next: 'enter_hall',
  ),
  'enter_hall': StoryBeat(
    id: 'enter_hall',
    label: '十二人',
    speaker: Speaker.narration,
    scene: SceneKey.assemblyHall,
    cgId: 'cg_assembly',
    text:
        '集合厅像一间早已停用的企业教室。十二把折叠椅被刻意围成一圈，每把椅背都贴着编号。算上我，走进来的只有十一人，贴着12的椅子始终空着。没人按编号坐下；大家宁愿站在离门最近的地方，仿佛先坐下就等于接受了安排。',
    next: 'hall_first_impression',
  ),
  'hall_first_impression': StoryBeat(
    id: 'hall_first_impression',
    label: '乱成一团',
    speaker: Speaker.narration,
    text:
        '一名中年男人用折叠椅撞击防火门，另两人踩上桌子检查通风口。有人坚称这是某种恶作剧节目，对着摄像头大骂；也有人说自己需要给家里报平安。问题彼此覆盖，没有任何一个得到回答。',
    next: 'locked_exit',
  ),
  'locked_exit': StoryBeat(
    id: 'locked_exit',
    label: '逃生尝试',
    speaker: Speaker.hanQi,
    text:
        '“都让开。”\n穿暗橙救援工装的男人蹲到门边，用拆下的薄钢片探锁芯。他肩背宽厚，手上满是长年握绳索留下的硬茧。几分钟后，他站起身，脸色更沉。\n“门不是反锁，是电磁吸合。断电也未必能开。”',
    passageSpeakers: [Speaker.hanQi, Speaker.narration, Speaker.hanQi],
    next: 'hall_inventory',
  ),
  'hall_inventory': StoryBeat(
    id: 'hall_inventory',
    label: '被挑选过的物品',
    speaker: Speaker.shenYan,
    text:
        '我让大家先检查口袋。结果几乎一样：所有通讯设备、钥匙和身份证都被拿走，工具、纸笔与个人小物却有选择地保留。这不是搜身的疏忽。绑架者故意留给我们可以互相帮助，也可以互相伤害的东西。',
    passageSpeakers: [Speaker.narration],
    next: 'sumi_caution',
  ),
  'sumi_caution': StoryBeat(
    id: 'sumi_caution',
    label: '医生的提醒',
    speaker: Speaker.suMi,
    text:
        '“先停一下。”\n穿旧象牙白医用外套的女人提高了声音。她叫苏弥，是急诊医生；乌黑长发被匆忙束在脑后，袖口却像在值班时那样挽得整齐。\n“项圈紧贴颈动脉，内部结构不明。在确认之前，谁都不要撬、拉或者通电。”',
    passageSpeakers: [Speaker.suMi, Speaker.narration, Speaker.suMi],
    next: 'wu_demands_exit',
  ),
  'wu_demands_exit': StoryBeat(
    id: 'wu_demands_exit',
    label: '不需要医生',
    speaker: Speaker.wuZheng,
    text:
        '“不动就在这儿等死？”\n一个体格粗壮的男人从工作服口袋里抽出活动扳手。他的脸晒得黝黑，眉骨上有一道旧伤，声音大得像要盖住自己的紧张。\n“我叫吴峥，干工地的。门打不开就拆墙，摄像头背后总有线。别把几个铁环说得像鬼一样。”',
    passageSpeakers: [Speaker.wuZheng, Speaker.narration, Speaker.wuZheng],
    next: 'intro_proposal',
  ),
  'intro_proposal': StoryBeat(
    id: 'intro_proposal',
    label: '先交换事实',
    speaker: Speaker.shenYan,
    text:
        '“吴峥，你可以找墙体的薄弱点，但先不要碰项圈。”我指了指黑屏下的摄像头，“对方知道我们是谁，我们却不知道彼此。先说姓名、职业和失去意识前的最后地点。不是为了信任，只是为了找共同点。”',
    next: 'shenyan_intro',
  ),
  'shenyan_intro': StoryBeat(
    id: 'shenyan_intro',
    label: '01 / 沈砚',
    speaker: Speaker.shenYan,
    text:
        '我先报上自己的资料。\n“沈砚，二十九岁，事故调查员。昨晚十一点四十左右，在工作单位的地下停车场被人从身后麻醉。”\n说完后没人立刻接话。我能感觉到他们在判断“调查员”是否只是一个用来取得主导权的谎言。',
    passageSpeakers: [Speaker.narration, Speaker.shenYan, Speaker.narration],
    next: 'xingyao_intro',
  ),
  'xingyao_intro': StoryBeat(
    id: 'xingyao_intro',
    label: '黎星遥',
    speaker: Speaker.liXingyao,
    text:
        '星遥靠着墙，目光仍在摄像头和扬声器之间移动。\n“黎星遥，二十六岁，通信设备工程师。昨晚十一点零七分，我在公司机房检查一次不存在的断线告警。有人从消防通道进来，他知道怎么避开我们的门禁日志。”',
    passageSpeakers: [Speaker.narration, Speaker.liXingyao],
    next: 'xingyao_doubt',
  ),
  'xingyao_doubt': StoryBeat(
    id: 'xingyao_doubt',
    label: '可能的内应',
    speaker: Speaker.liXingyao,
    text:
        '“还有，这不是普通屏蔽。”星遥抬起耳机，“无线电噪声被处理得很干净，设备投入不会小。如果有人觉得这只是临时搭的摄影棚，可以先解释一下电从哪里来。”\n她的话让“恶作剧”听起来没那么可信，也让气氛变得更糟。',
    passageSpeakers: [Speaker.liXingyao, Speaker.narration],
    next: 'sumi_intro',
  ),
  'sumi_intro': StoryBeat(
    id: 'sumi_intro',
    label: '苏弥',
    speaker: Speaker.suMi,
    text:
        '苏弥一边听一边为几个头晕的人检查瞳孔。\n“苏弥，二十八岁，急诊医生。我在医院地下车库上车后失去意识。我们都有注射痕迹，剂量不完全一样，但目前没人出现严重过量反应。”\n她没说“所以对方不想杀我们”。医生显然不愿意替绑架者做这种保证。',
    passageSpeakers: [Speaker.narration, Speaker.suMi, Speaker.narration],
    next: 'hanqi_intro',
  ),
  'hanqi_intro': StoryBeat(
    id: 'hanqi_intro',
    label: '韩骐',
    speaker: Speaker.hanQi,
    text:
        '高大男人仍守在出口，他的暗橙工装肩部有被安全带反复摩擦的痕迹。\n“韩骐，三十四岁，救援训练教官。下班路上被一辆面包车故意别停，我打开车门后就什么都不知道了。”\n他看了我一眼。\n“我不认识你们。现在也还不信任你们。”',
    passageSpeakers: [
      Speaker.narration,
      Speaker.hanQi,
      Speaker.narration,
      Speaker.hanQi,
    ],
    next: 'hanqi_test',
  ),
  'hanqi_test': StoryBeat(
    id: 'hanqi_test',
    label: '楼体判断',
    speaker: Speaker.hanQi,
    text:
        '韩骐蹲下用指节敲了敲地面，又把一杯水放在椅背上观察水面。\n“没有持续振动，地面是混凝土。这里不是船，也不是行驶中的车辆。通风有旧建筑的霉味，我们应该还在某栋楼里。”\n这是第一个稍微缩小范围的结论，人群终于安静了几秒。',
    passageSpeakers: [Speaker.narration, Speaker.hanQi, Speaker.narration],
    next: 'tang_intro',
  ),
  'tang_intro': StoryBeat(
    id: 'tang_intro',
    label: '唐弈',
    speaker: Speaker.tangYi,
    text:
        '轮到穿深色西装的男人时，他才从墙边直起身。西装很贵，脚上却是一双磨损严重的旅行鞋，一枚旧硬币在他指间无声翻转。\n“唐弈，三十一岁，职业赌客。最后记得酒店电梯停在了一层没有按钮的楼层。”\n“赌客也算职业？”吴峥冷笑。\n“能活下来的时候就算。”唐弈说。',
    passageSpeakers: [
      Speaker.narration,
      Speaker.tangYi,
      Speaker.wuZheng,
      Speaker.tangYi,
    ],
    next: 'lincheng_intro',
  ),
  'lincheng_intro': StoryBeat(
    id: 'lincheng_intro',
    label: '林澄',
    speaker: Speaker.linCheng,
    text:
        '双马尾女生被所有人看着时缩了一下肩膀。她的深色制服裙角沾着灰，一侧青绿发带松了，双手却仍把一张纸折得异常整齐。\n“林澄，十八岁，高三。我在晚自习回家的公交站等车。有辆车停在我面前，后面就记不清了。”',
    passageSpeakers: [Speaker.narration, Speaker.linCheng],
    next: 'lincheng_observation',
  ),
  'lincheng_observation': StoryBeat(
    id: 'lincheng_observation',
    label: '被忽略的细节',
    speaker: Speaker.shenYan,
    text:
        '“还有一件事。”林澄犹豫了很久，才继续说，“我醒来前听见过一句话，好像是‘第七号观察样本已送达’。不一定是真的，也可能是我在做梦。”\n她一直低头涂画的纸上，已经标出了走廊摄像头的朝向、死角以及每个人进门的顺序。',
    passageSpeakers: [Speaker.linCheng, Speaker.narration],
    next: 'other_participants',
  ),
  'other_participants': StoryBeat(
    id: 'other_participants',
    label: '陈默 / 08',
    speaker: Speaker.chenMo,
    portraitMood: 'discovery',
    text:
        '靠近墙角的年轻男人终于把视线从终端上移开。他身形单薄，深蓝连帽衫外套着多口袋背心，圆框眼镜后是一双明显缺觉的眼睛。右手指甲被咬得参差不齐，左手却一直在尝试不同的按键组合。\n“陈默，二十四岁，系统工程师。昨晚十一点二十分，我收到公司服务器的越权登录告警。赶到机房后，门禁记录里只剩下我自己的名字。”\n“这台终端没有关机、重启或者退出账户的入口。”他把08号屏幕转向众人，“不是我们不会操作，是系统根本没把这些权限交给使用者。”',
    passageSpeakers: [Speaker.narration, Speaker.chenMo, Speaker.chenMo],
    next: 'gaoyuan_intro',
  ),
  'gaoyuan_intro': StoryBeat(
    id: 'gaoyuan_intro',
    label: '高原 / 09',
    speaker: Speaker.gaoYuan,
    portraitMood: 'inspecting',
    text:
        '穿灰蓝检修服的中年男人一直没有抢着说话。他颈下挂着橙色隔音耳罩，手里那台老式振动仪满是磕痕。别人争论时，他几次把鞋底贴紧地面，像在听墙体另一侧的机器。\n“高原，四十一岁，设备工程师。昨晚在旧厂房检查一台自己启动的备用风机，弯腰看控制柜时被人从后面按住。”\n他抬头看向通风口。“这里的风机轴承很旧，风阀却是新的。有人保留了原来的楼体，又重新做了一套能远程控制的通风和门禁。”',
    passageSpeakers: [Speaker.narration, Speaker.gaoYuan, Speaker.gaoYuan],
    next: 'zhouxu_intro',
  ),
  'zhouxu_intro': StoryBeat(
    id: 'zhouxu_intro',
    label: '周叙 / 10',
    speaker: Speaker.zhouXu,
    portraitMood: 'defensive',
    text:
        '轮到10号时，戴无框眼镜的男人先把散落的票据按尺寸叠齐，才像借这个动作重新找回呼吸。他的西装并不昂贵，却熨得很平，领带此刻已经被汗水浸出一块深色。\n“周叙，三十八岁，会计师。昨晚加班核对季度账目，十一点半下楼取车。电梯在地下二层开门，我只闻到一股甜味。”\n“我没有仇家，也接触不到什么商业机密。”他把计算器攥在胸前，声音越来越快，“我妻子和女儿还在等我回去。只要能联系家属，这种绑错人的事马上就能说清楚。”',
    passageSpeakers: [Speaker.narration, Speaker.zhouXu, Speaker.zhouXu],
    next: 'yelan_intro',
  ),
  'yelan_intro': StoryBeat(
    id: 'yelan_intro',
    label: '叶岚 / 11',
    speaker: Speaker.yeLan,
    portraitMood: 'intervening',
    text:
        '最后开口的女人留着齐肩卷发，暗红针织外套的袖口被她推到手腕上方。她没有记录谁“可疑”，只在笔记本上写下有人头晕、有人呼吸过快，以及谁可能需要先坐下。\n“叶岚，三十三岁，心理咨询师。昨晚送走最后一位来访者后，我在咨询中心的停车场失去意识。”\n她合上笔记本。“我不会因为职业就知道谁在撒谎，也不会要求各位现在互相信任。先把亲眼见过的事实和推测分开，至少能少制造一个敌人。”',
    passageSpeakers: [Speaker.narration, Speaker.yeLan, Speaker.yeLan],
    next: 'participant_twelve',
  ),
  'participant_twelve': StoryBeat(
    id: 'participant_twelve',
    label: '空着的 12 号',
    speaker: Speaker.narration,
    text:
        '叶岚说完后，介绍本该轮到12号，却没有人回应。贴着12的折叠椅没有坐过人的温度，椅背后的宿舍钥匙也仍封在透明袋里。\n我重新数了一遍。集合厅里确实只有十一名佩戴项圈的人，走廊上也没有第十二扇刚刚开启的房门。\n更奇怪的是，所有终端的公共名册都保留着12号的位置，姓名、职业和状态却只有一行灰字：无记录。那不像空位，更像有人刻意把一条已经存在的数据擦掉了。',
    next: 'abduction_discussion',
  ),
  'abduction_discussion': StoryBeat(
    id: 'abduction_discussion',
    label: '没有共同点',
    speaker: Speaker.shenYan,
    text:
        '我把所有时间和地点写在白板上。职业、年龄、生活区域都没有重合，唯一一致的是失去意识的时段：昨夜十一点到午夜。这种同步性需要不止一组人行动。对方花了很大代价把十一名可见参与者同时带到这里，还为一个没有现身的人保留编号，不会只为了勒索某一个人。',
    passageSpeakers: [Speaker.narration],
    next: 'ransom_theory',
  ),
  'ransom_theory': StoryBeat(
    id: 'ransom_theory',
    label: '勒索的可能',
    speaker: Speaker.suMi,
    text:
        '周叙说这仍然可能是集体勒索，也许大家的家属已经在收到要求。苏弥却摇了摇头。\n“如果目的是赎金，就应该让我们报平安，也没必要给每个人装上独立设备。”\n她说完才意识到，自己也在默认这些项圈不只是道具，脸色随即白了一层。',
    passageSpeakers: [Speaker.narration, Speaker.suMi, Speaker.narration],
    next: 'staged_game_theory',
  ),
  'staged_game_theory': StoryBeat(
    id: 'staged_game_theory',
    label: '恶作剧的可能',
    speaker: Speaker.tangYi,
    text:
        '“也可能是一场昂贵的节目。”唐弈望向摄像头，“我们表现得越害怕，镜头后面的人越高兴。”\n“那就更该拆了镜头。”吴峥说。\n“也可以先问问他们为什么在12号名下留了空白。”唐弈笑了笑，“一个连演员表都不完整的节目，我不会下注。”',
    passageSpeakers: [Speaker.tangYi, Speaker.wuZheng, Speaker.tangYi],
    next: 'wu_rejects',
  ),
  'wu_rejects': StoryBeat(
    id: 'wu_rejects',
    label: '吴峥的判断',
    speaker: Speaker.wuZheng,
    text:
        '“你们愿意坐在这儿猜就猜。”吴峥的呼吸越来越重，“我干了十几年工地，没见过真拆不开的东西。门锁、墙、摄像头，总有一样会把后面的人逼出来。”\n他不再听劝，拎着扳手走向墙角的摄像头。',
    passageSpeakers: [Speaker.wuZheng, Speaker.narration],
    next: 'camera_attack',
  ),
  'camera_attack': StoryBeat(
    id: 'camera_attack',
    label: '砸碎镜头',
    speaker: Speaker.narration,
    text:
        '第一下砸碎了摄像头的透明外罩，第二下把支架连根扯下。断线里没有跳出火花，只有一粒极小的红灯仍在闪烁。吴峥举起被砸烂的机器对着房间大喊：“看见了吗？我再给你们十秒，开门！”\n没有回应。墙上的十二块黑屏却在此时同时亮了起来。',
    next: 'screen_boot',
  ),
  'screen_boot': StoryBeat(
    id: 'screen_boot',
    label: '零点协议',
    speaker: Speaker.administrator,
    text:
        '墙上的主屏幕从中央亮起，白光把每张脸都照得失去血色。屏幕上没有人影，只有一串沉默的数字：168:00:00。\n“全员到齐。欢迎参与零点协议。从现在开始，各位将在封闭设施中度过七天，并依据个人生还条款争取离开资格。”\n十一名可见参与者，十二把椅子，广播却宣称全员到齐。陈默立刻低头去刷新名册，12号那行“无记录”没有任何变化。',
    passageSpeakers: [
      Speaker.narration,
      Speaker.administrator,
      Speaker.narration,
    ],
    next: 'disbelief',
  ),
  'disbelief': StoryBeat(
    id: 'disbelief',
    label: '质问',
    speaker: Speaker.hanQi,
    text:
        '“停止播放录音。”韩骐走到屏幕正下方，“你能看见我们，就能听见。这里是什么地方？谁委托你们绑架？钱、条件、你想要的东西，可以派一个人进来谈。但先打开门，把学生和身体不适的人放走。”',
    next: 'questions_overlap',
  ),
  'questions_overlap': StoryBeat(
    id: 'questions_overlap',
    label: '并没有全员安静',
    speaker: Speaker.narration,
    text:
        '韩骐的话像打开了闸门。周叙问家属是否安全，陈默追问终端为什么预先录入了所有人的指纹，林澄连续问了两遍“今天是几号”。苏弥则说有人可能对麻醉药产生延迟反应，必须允许医疗撤离。十几个问题堆在一起，广播沉默地等它们自行停止。',
    next: 'administrator_refusal',
  ),
  'administrator_refusal': StoryBeat(
    id: 'administrator_refusal',
    label: '没有交涉',
    speaker: Speaker.administrator,
    text:
        '“日期为十月十七日。参与者家属不在本设施内，其状态不属于游戏信息。设施位置、主办者身份与撤离请求均不予公开。”那道声音停顿了半秒，像在等待一台机器完成运算，“规则说明将在全员安静后开始。请勿破坏项圈、终端、门禁或裁定设备。”',
    next: 'wu_challenge',
  ),
  'wu_challenge': StoryBeat(
    id: 'wu_challenge',
    label: '破坏项圈',
    speaker: Speaker.wuZheng,
    text:
        '“它刚才也说别砸摄像头。”吴峥把地上的扳手踢到脚边，弯腰捡起，“结果呢？除了一堆录音，什么都没发生。”\n他把扳手开口调到最窄，卡进自己项圈的接缝。几个人同时喊住手，他反而用更大的力气向外拧。',
    passageSpeakers: [Speaker.wuZheng, Speaker.narration],
    next: 'sumi_blocks_wu',
  ),
  'sumi_blocks_wu': StoryBeat(
    id: 'sumi_blocks_wu',
    label: '别拿命验证',
    speaker: Speaker.suMi,
    text:
        '苏弥一把抓住了他的手腕。“项圈内部在震动，这意味着有电源和传感器。我不知道它能不能杀人，所以更不能让你拿自己的命验证！”\n“你自己都说不知道。”吴峥甩开她，“那就别挡我。”扳手磕在锁扣上，第一次发出金属闷响。',
    passageSpeakers: [Speaker.suMi, Speaker.wuZheng],
    next: 'final_warning',
  ),
  'final_warning': StoryBeat(
    id: 'final_warning',
    label: '最后警告',
    speaker: Speaker.administrator,
    text:
        '吴峥颈上的白色指示灯转为红色。\n“参与者05，检测到第一次蓄意破坏。请立即停止。”\n吴峥抬头望向屏幕，脸上反而露出了某种抓住破绽的兴奋。\n“你急了。”\n他说完，第二次用扳手砸了下去。\n“检测到第二次蓄意破坏。下一次冲击将被视为主动放弃游戏资格。”',
    passageSpeakers: [
      Speaker.narration,
      Speaker.administrator,
      Speaker.narration,
      Speaker.wuZheng,
      Speaker.narration,
      Speaker.administrator,
    ],
    next: 'crowd_intervention',
  ),
  'crowd_intervention': StoryBeat(
    id: 'crowd_intervention',
    label: '没有人相信',
    speaker: Speaker.hanQi,
    portraitMood: 'protective',
    text:
        '这一次不只是苏弥。韩骐从侧面扣住吴峥的肩膀，我去抢他手里的扳手，周叙在后面一迭声地说“别试了”。可我们所有人加起来的劝阻里，仍然没有一个人真正相信项圈会杀人。我们只是不愿承担它万一为真的后果。',
    passageSpeakers: [Speaker.narration],
    next: 'wu_defiance',
  ),
  'wu_defiance': StoryBeat(
    id: 'wu_defiance',
    label: '第三下',
    speaker: Speaker.wuZheng,
    portraitMood: 'defiant',
    text:
        '吴峥猛地挣开韩骐。“我家里还有个孩子等我回去。你们可以听它的话坐七天，我不行。”\n他的声音在最后两个字上裂开了。那一刻我终于明白，他不是确信项圈无害，只是比起承认自己无能为力，更愿意押上命去否定它。扳手第三次扬了起来。',
    passageSpeakers: [Speaker.wuZheng, Speaker.narration],
    next: 'collar_detonation',
  ),
  'collar_detonation': StoryBeat(
    id: 'collar_detonation',
    label: '第一次出局',
    speaker: Speaker.narration,
    text:
        '扳手还没有完全落下，项圈内部就传出一声短促的爆响。不是电影里那种巨大爆炸，只像一只厚塑料袋被人贴着耳边拍破。吴峥的身体向后弹开，撞翻三把折叠椅后重重落地。扳手滚到林澄脚边，她却像没看见一样一动不动。屏幕上的12无声变成了11。',
    next: 'explosion_silence',
  ),
  'explosion_silence': StoryBeat(
    id: 'explosion_silence',
    label: '爆响之后',
    speaker: Speaker.shenYan,
    text:
        '我听不见任何人的声音，只有耳鸣像一根细针扎在脑子深处。吴峥仰面躺着，眼睛还睁着，脸上保留着挥下扳手时的愤怒。空气里没有我想象中的火药味，只多了一点类似烧焦电线的甜腥气息。因为这些细节都太寻常，他的死亡才显得不可理解。',
    passageSpeakers: [Speaker.narration],
    next: 'death_confirmed',
  ),
  'death_confirmed': StoryBeat(
    id: 'death_confirmed',
    label: '死亡确认',
    speaker: Speaker.suMi,
    text:
        '苏弥第一个动了。她跪到吴峥身边，手指先探向颈动脉，又拉开他的眼睑检查瞳孔。她做了两次完全相同的检查，仿佛第二次会得到不同结果。\n“没有脉搏。”她终于开口，声音低得几乎听不见，“不是电击昏迷。他已经死了。”',
    passageSpeakers: [Speaker.narration, Speaker.suMi],
    next: 'denial_after_death',
  ),
  'denial_after_death': StoryBeat(
    id: 'denial_after_death',
    label: '否认',
    speaker: Speaker.narration,
    text:
        '周叙说“不可能”，又说这一定是事先安排好的演出，只要找到血包和遥控器就能证明。没人理他。陈默弯腰呕吐，高原把自己的项圈护在手心里，叶岚坐到林澄身边试图让她呼吸。几分钟前还被大家当成荒唐道具的黑色项圈，突然变得没人敢再触碰。',
    next: 'hanqi_after_death',
  ),
  'hanqi_after_death': StoryBeat(
    id: 'hanqi_after_death',
    label: '愤怒无处可去',
    speaker: Speaker.hanQi,
    text:
        '韩骐一拳砸在墙上，没有朝摄像头，而是避开了所有设备。“你们听到了吗？”他对屏幕吼道，“他已经停手了！第三下还没有落实！”\n广播没有解释传感器怎么判断，也没有回应“他还有孩子”。屏幕只保持着精确的倒计时。',
    passageSpeakers: [Speaker.hanQi, Speaker.narration],
    next: 'host_resumes',
  ),
  'host_resumes': StoryBeat(
    id: 'host_resumes',
    label: '规则继续',
    speaker: Speaker.administrator,
    text:
        '“参与者05已放弃资格。当前存活人数：11。”\n那道声音与之前没有任何不同，连音量都不曾变化。\n“演示已完成。为避免同类事件再次发生，现开始说明通用规则。”\n“演示”两个字让苏弥抬起了头。她眼里的愤怒比任何反驳都更清楚，却没有再打断。',
    passageSpeakers: [
      Speaker.administrator,
      Speaker.yeLan,
      Speaker.administrator,
      Speaker.narration,
    ],
    next: 'rule_one',
  ),
  'rule_one': StoryBeat(
    id: 'rule_one',
    label: '终端规则',
    speaker: Speaker.administrator,
    text:
        '“规则一：个人终端必须保持在初始持有者两米内。超出距离后开始累计计时；达到一百八十秒，项圈将执行处决。终端可以被他人查看与操作，但个人生还条款仅对初始持有者生效。”\n几乎每个人都下意识把黑色终端拿近了一些。',
    passageSpeakers: [Speaker.administrator, Speaker.narration],
    next: 'distance_demo',
  ),
  'distance_demo': StoryBeat(
    id: 'distance_demo',
    label: '两米',
    speaker: Speaker.liXingyao,
    text:
        '星遥没有立刻接受这条说法。她让韩骐用测量绳在地上拉出两米，自己将终端放到边缘外侧。她颈上的指示灯立即转黄，屏幕出现从180开始下降的数字。五秒后她把终端拿回，计时停住，却没有清零。\n“累计的。”她盯着屏幕，“不是每次重新计时。”',
    passageSpeakers: [Speaker.narration, Speaker.liXingyao],
    next: 'rule_two',
  ),
  'rule_two': StoryBeat(
    id: 'rule_two',
    label: '封锁规则',
    speaker: Speaker.administrator,
    text:
        '“规则二：设施每天零点永久封锁一个区域。封锁顺序将在当日公布，倒计结束后仍留在该区域者出局。已封锁区域不会重新开放。”\n集合厅屏幕显示出整座设施的轮廓，其中一块区域已经被标成橙色。七天后，这座建筑将不再有足够容纳所有人的空间。',
    passageSpeakers: [Speaker.administrator, Speaker.narration],
    next: 'rule_three',
  ),
  'rule_three': StoryBeat(
    id: 'rule_three',
    label: '允许一切',
    speaker: Speaker.administrator,
    text:
        '“规则三：禁止离开游戏边界，禁止破坏裁定主机。除明文禁止项外，所有行为均被允许。”\n“包括杀人吗？”叶岚问。\n“本协议不对未禁止行为做道德评价。”\n这句回答比直接说“是”更让人不寒而栗。韩骐想让所有人把工具放在中央，吴峥的扳手却还躺在尸体旁边，没人愿意过去拿。',
    passageSpeakers: [
      Speaker.administrator,
      Speaker.narration,
      Speaker.administrator,
      Speaker.narration,
    ],
    next: 'personal_clause',
  ),
  'personal_clause': StoryBeat(
    id: 'personal_clause',
    label: '01 号条款',
    speaker: Speaker.shenYan,
    text:
        '所有终端同时震动。我的屏幕在指纹按上去后亮起，数秒前还无法启动的设备此刻只显示两行字：\n【生还条款】游戏结束前，使四名存活参与者同时提交相同的“主办者代号”。\n它不要求我找到出口，而是要求我说服别人。这意味着从第一分钟起，我就不可能只为自己活着。',
    passageSpeakers: [Speaker.narration, Speaker.narration, Speaker.narration],
    next: 'clause_silence',
  ),
  'clause_silence': StoryBeat(
    id: 'clause_silence',
    label: '各自的屏幕',
    speaker: Speaker.narration,
    text:
        '屏幕亮起后，人群反而比吴峥死后更安静。有人迅速把终端扣到胸前，有人看完后立即去观察别人的表情。周叙连续说了三次“这不算数”，但手指始终没有离开终端边缘。唐弈则露出了第一个真正的笑容，像终于看见了赌桌上的底牌。',
    next: 'xingyao_clause',
  ),
  'xingyao_clause': StoryBeat(
    id: 'xingyao_clause',
    label: '星遥的条件',
    speaker: Speaker.liXingyao,
    text:
        '星遥先看了我一眼，才把屏幕转向众人。\n“我的条件是：01号存活，并且设施的中央信标到结束时仍然在线。”\n“你为什么帮他？”陈默问。\n“不是帮。”星遥的回答依旧冷静，“是利益一致。我不知道为什么被绑定到01，但我愿意先公开可以互相验证的部分。”',
    passageSpeakers: [
      Speaker.narration,
      Speaker.liXingyao,
      Speaker.chenMo,
      Speaker.liXingyao,
    ],
    next: 'sumi_clause',
  ),
  'sumi_clause': StoryBeat(
    id: 'sumi_clause',
    label: '苏弥的底线',
    speaker: Speaker.suMi,
    text:
        '苏弥的拇指在屏幕边缘停了很久。\n“我的条件是游戏结束时，至少六人存活。”\n“那你不用挑阵营。”唐弈说。\n“不。”苏弥望向吴峥的尸体，“它专门把这个数字给了我，说明也会把相反的数字给别人。”\n她说话时没有看唐弈，而唐弈手中的硬币恰好在此刻停了一下。',
    passageSpeakers: [
      Speaker.narration,
      Speaker.suMi,
      Speaker.tangYi,
      Speaker.suMi,
      Speaker.narration,
    ],
    next: 'lincheng_clause',
  ),
  'lincheng_clause': StoryBeat(
    id: 'lincheng_clause',
    label: '信赖对象',
    speaker: Speaker.linCheng,
    text:
        '林澄是第三个公开屏幕的人，但她用了近一分钟才把手举起来。\n“我的条件需要一名参与者自愿把07号登记为‘信赖对象’，而且我们必须一起活到第七天。”\n她立即又补充。\n“我不是要现在逼谁答应。我连你们是什么人都不知道。只是如果我不说，以后说什么都会像在利用别人。”',
    passageSpeakers: [
      Speaker.narration,
      Speaker.linCheng,
      Speaker.narration,
      Speaker.linCheng,
    ],
    next: 'hanqi_threat',
  ),
  'hanqi_threat': StoryBeat(
    id: 'hanqi_threat',
    label: '夺取',
    speaker: Speaker.hanQi,
    text:
        '“自愿这个词，到第六天还会剩下多少意义？”韩骐终于把自己的屏幕亮出来，“我的条件是游戏结束时持有01号终端。”\n他的目光落到我手上，又移向地上的两米标线。\n“把它交给我。你只要留在两米内，项圈就不会启动。我不需要杀你，你也可以监督我。”\n这不是虚张声势。他已经开始用规则计算如何存活。',
    passageSpeakers: [
      Speaker.hanQi,
      Speaker.narration,
      Speaker.hanQi,
      Speaker.narration,
    ],
    next: 'sumi_intervenes',
  ),
  'sumi_intervenes': StoryBeat(
    id: 'sumi_intervenes',
    label: '六人底线',
    speaker: Speaker.suMi,
    text:
        '苏弥站到我们之间，尽管她的手上还留着吴峥的血。\n“你说的方案在规则上成立，所以才更不能现在做。我们刚看着一个人因为恐惧做出了不可逆的选择。如果现在就开始抢终端，那所有人都会把身边的人当成下一个项圈。”\n韩骐没有后退，但他按在刀柄上的手稍微松开了。',
    passageSpeakers: [Speaker.narration, Speaker.suMi, Speaker.narration],
    next: 'clause_choice',
  ),
  'clause_choice': StoryBeat(
    id: 'clause_choice',
    label: '是否公开',
    speaker: Speaker.shenYan,
    text:
        '所有视线都落在我身上。星遥等着确认我们的利益是否真的一致，苏弥在意我的条件会不会要求更多人死亡，韩骐则准备从我的沉默里判断是否应该直接拿走终端。公开条件能换来合作，也会让所有人知道如何让我永远无法通关。谎言可以暂时保护我，但在一间只剩下十一个人的建筑里，每个谎言最终都需要当着同样的脸重复。',
    passageSpeakers: [Speaker.narration],
    next: null,
    choices: [
      StoryChoice(
        label: '完整公开 01 号生还条款',
        caption: '用可验证的共同目标建立联盟',
        next: 'public_pact',
        effect: ChoiceEffect(
          xingyao: 1,
          sumi: 1,
          cooperation: 2,
          flag: 'public_clause',
        ),
      ),
      StoryChoice(
        label: '只承认条件需要多人合作',
        caption: '保留关键细节，维持有限信任',
        next: 'partial_pact',
        effect: ChoiceEffect(
          xingyao: 1,
          cooperation: 1,
          flag: 'partial_clause',
        ),
      ),
      StoryChoice(
        label: '伪造一个只需自保的条件',
        caption: '安全地离开人群，但谎言会留在线路图上',
        next: 'conceal_pact',
        effect: ChoiceEffect(logic: 1, flag: 'concealed_clause'),
      ),
    ],
  ),
  'public_pact': StoryBeat(
    id: 'public_pact',
    label: '公开同盟',
    speaker: Speaker.shenYan,
    text:
        '我把终端放在地上，让每个人都能看清屏幕。\n“我需要四名存活者提交同一个主办者代号。这意味着我需要你们活着，也需要你们相信我找到的答案。”\n说完的瞬间，我意识到自己也把最明显的弱点交了出去：只要让其他人永远不再信任我，就等于判了我死刑。',
    passageSpeakers: [Speaker.narration, Speaker.shenYan, Speaker.narration],
    next: 'public_reaction',
  ),
  'public_reaction': StoryBeat(
    id: 'public_reaction',
    label: '第一份交换',
    speaker: Speaker.liXingyao,
    text:
        '星遥蹲下把她的终端放到我旁边，02与01的光在地面上并排亮着。\n“我会帮你找主办者。作为交换，你不能背着我关闭信标，也不能隐瞒与中央系统有关的证据。”\n苏弥也同意共享体检和药物信息。这还算不上信任，只是两个人先把可以验证的承诺放到了桌上。',
    passageSpeakers: [Speaker.narration, Speaker.liXingyao, Speaker.narration],
    next: 'post_clause_break',
  ),
  'partial_pact': StoryBeat(
    id: 'partial_pact',
    label: '有限合作',
    speaker: Speaker.suMi,
    text:
        '“我的条件需要多人合作，不会因为任何人死亡而更容易完成。”\n星遥的视线在我的屏幕边缘停留了几秒，显然知道我省略了关键信息。苏弥却先点了头。\n“只要你的目标不是减少存活者，我们可以暂时合作。但我会记得，你今天保留了一部分。”',
    passageSpeakers: [Speaker.shenYan, Speaker.narration, Speaker.suMi],
    next: 'partial_reaction',
  ),
  'partial_reaction': StoryBeat(
    id: 'partial_reaction',
    label: '保留的代价',
    speaker: Speaker.shenYan,
    text:
        '韩骐没有再要求交出终端，但他把我划进了“必须监视”的人里。星遥也只同意共享公共频道，不愿把信标的完整诊断权交给我。我保住了条款的关键字，却也让每一份合作都多了一层检查。在这里，沉默并不等于没有做出选择。',
    passageSpeakers: [Speaker.narration],
    next: 'post_clause_break',
  ),
  'conceal_pact': StoryBeat(
    id: 'conceal_pact',
    label: '独行者',
    speaker: Speaker.hanQi,
    text:
        '“我的条件只要自己存活到最后。”这句谎言说出口时，比我想象中更顺畅。\n韩骐的手从刀柄上移开，因为一个“只需自保”的01对他没有立即威胁。可星遥也同时别开了视线。她不需要证明我在说谎；我回避她目光的那一瞬间，已经替她完成了判断。',
    passageSpeakers: [Speaker.shenYan, Speaker.narration],
    next: 'conceal_reaction',
  ),
  'conceal_reaction': StoryBeat(
    id: 'conceal_reaction',
    label: '一个人的安全',
    speaker: Speaker.shenYan,
    text:
        '没人继续追问我，但也没人将自己的终端靠近我。我站在十一个活人中间，突然拥有了整间集合厅最宽敞的一圈空间。这是谎言换来的安全：暂时没人会向我下手，也暂时没人会为我伸手。',
    passageSpeakers: [Speaker.narration],
    next: 'post_clause_break',
  ),
  'post_clause_break': StoryBeat(
    id: 'post_clause_break',
    label: '五分钟休息',
    speaker: Speaker.narration,
    text:
        '主办方宣布第一次区域封锁将在二十四小时后开始，随后中断了广播。没有人因为它安静而放松。苏弥用白布盖住吴峥的身体，韩骐组织人收起散落的工具，周叙还在尝试用数学证明一百八十秒不可能精确执行。林澄一直没有再看地上的扳手。',
    next: 'faction_argument',
  ),
  'faction_argument': StoryBeat(
    id: 'faction_argument',
    label: '尚未成形的阵营',
    speaker: Speaker.tangYi,
    text:
        '唐弈用硬币在地图上划出三个圈，又把硬币立在三个圈中间。\n“想把条款公开的人、想保密的人，还有想先抢到别人终端的人。现在每个人都觉得自己在中间，到今天晚上就未必了。”\n韩骐不喜欢他的说法，却同意了最实际的部分：任何人都不得单独离开，在封锁前先两人一组确认设施布局。',
    passageSpeakers: [Speaker.narration, Speaker.tangYi, Speaker.narration],
    next: 'partner_choice',
  ),
  'partner_choice': StoryBeat(
    id: 'partner_choice',
    label: '第一天的同行者',
    speaker: Speaker.narration,
    text:
        '第一次区域封锁还有二十四小时，可没人知道下一次意外会不会发生在二十四分钟后。黎星遥要趁广播系统还在工作时确认信号回路；苏弥想先整理药品和所有人的麻醉针孔；林澄则认为官方地图有意省略了几段走廊。三件事都很重要，而现在没有人愿意让任何一个人单独行动。我必须选择第一个把后背交给谁。',
    next: null,
    choices: [
      StoryChoice(
        label: '陪黎星遥检查广播线路',
        caption: '理解她藏在冷静背后的不安',
        next: 'xingyao_search',
        effect: ChoiceEffect(xingyao: 1, cooperation: 1, flag: 'route_xingyao'),
      ),
      StoryChoice(
        label: '帮助苏弥整理临时医务点',
        caption: '让照顾者也有一次被人照顾',
        next: 'sumi_infirmary',
        effect: ChoiceEffect(sumi: 1, cooperation: 1, flag: 'route_sumi'),
      ),
      StoryChoice(
        label: '陪林澄绘制设施地图',
        caption: '认真对待她发现的每一个细节',
        next: 'lincheng_map',
        effect: ChoiceEffect(lincheng: 1, logic: 1, flag: 'route_lincheng'),
      ),
    ],
  ),
  'xingyao_search': StoryBeat(
    id: 'xingyao_search',
    label: '共用耳机',
    speaker: Speaker.liXingyao,
    scene: SceneKey.corridor,
    text:
        '星遥选的第一个目标不是主控室，而是走廊天花板上一只不起眼的广播盒。她踩上椅子拆开外壳，手指在线缆之间移动得很快，却始终避开任何不明连接点。\n“主办方能听见整层楼，但所有声音不是走同一条线。只要找到那条独立回路，就有可能反向定位。”',
    passageSpeakers: [Speaker.narration, Speaker.liXingyao],
    next: 'xingyao_work_habit',
  ),
  'xingyao_work_habit': StoryBeat(
    id: 'xingyao_work_habit',
    label: '工程师的习惯',
    speaker: Speaker.shenYan,
    scene: SceneKey.corridor,
    text:
        '她把每根线的颜色、插口和电压写在腕上，字小得几乎连在一起。我问她为什么不写在纸上。\n“纸会被拿走，手暂时还在我身上。”\n她回答完，突然意识到这句话并不好笑。她将袖口向下拉了拉，像想把想象中的某种失去一起遮住。',
    passageSpeakers: [Speaker.narration, Speaker.liXingyao, Speaker.narration],
    next: 'xingyao_signal',
  ),
  'xingyao_signal': StoryBeat(
    id: 'xingyao_signal',
    label: '七秒脉冲',
    speaker: Speaker.liXingyao,
    portraitMood: 'alarm',
    scene: SceneKey.corridor,
    text:
        '“找到了。”\n星遥摘下耳机，把其中一边递给我。老式耳机的线很短，我们只能肩肩相抵地站在广播盒下。白噪声里，每隔七秒就会出现一次细小脉冲。\n“不是广播。”她在很近的地方说，“是某台设备在回答主机。这栋楼里还有第二套网络。”',
    passageSpeakers: [Speaker.liXingyao, Speaker.narration, Speaker.liXingyao],
    next: 'corridor_blackout',
  ),
  'corridor_blackout': StoryBeat(
    id: 'corridor_blackout',
    label: '熄灯的十秒',
    speaker: Speaker.shenYan,
    scene: SceneKey.corridor,
    text:
        '走廊灯突然熄灭。黑暗里响起远处门锁的咔哒声，星遥几乎在同一秒抓住了我的袖口。她的手指在发抖，但另一只手仍然护着耳机和测试线，没有让刚得到的证据掉在地上。\n十秒后灯光恢复，她确认只是通风系统切换，却没有立刻松手。我也没有提醒她。',
    passageSpeakers: [Speaker.narration, Speaker.narration],
    next: 'xingyao_promise',
  ),
  'xingyao_promise': StoryBeat(
    id: 'xingyao_promise',
    label: '别只叫编号',
    speaker: Speaker.liXingyao,
    scene: SceneKey.corridor,
    text:
        '星遥松开手后，先低头把我被抓皱的袖口抚平。\n“刚才的事别告诉别人。”\n“你怕黑？”\n“我怕在看不见的时候失去连接。”她把耳机重新挂回颈间，“如果之后必须分开，别只在频道里叫我02号。叫我的名字。我会知道是你，也会回答。”',
    passageSpeakers: [
      Speaker.narration,
      Speaker.liXingyao,
      Speaker.shenYan,
      Speaker.liXingyao,
    ],
    next: 'facility_search',
  ),
  'sumi_infirmary': StoryBeat(
    id: 'sumi_infirmary',
    label: '临时医务点',
    speaker: Speaker.suMi,
    text:
        '苏弥选了集合厅侧面一间有水池的小办公室，把它改成临时医务点。她先把药品按用途分开，又在门口写下“任何人不得私自取用”。笔尖划过纸面时，她的手有一下很轻的颤抖。她立刻换了另一只手，像只要动作不停，吴峥的死亡就还没来得及追上她。',
    passageSpeakers: [Speaker.narration],
    next: 'sumi_triage',
  ),
  'sumi_triage': StoryBeat(
    id: 'sumi_triage',
    label: '每个人的名字',
    speaker: Speaker.suMi,
    portraitMood: 'concerned',
    text:
        '苏弥用裁开的文件夹做了十一张检伤卡，上面写的是姓名，不是编号。她将“吴峥”的卡单独放在一边。\n“项圈会把人缩成一个可以减掉的数字。至少在这里，我不打算那样记录。”\n她已经记住了所有人的过敏史和基础脉搏，却在我问她是否头痛时愣了一下，像是第一次有人把她也算进需要检查的人。',
    passageSpeakers: [Speaker.narration, Speaker.suMi, Speaker.narration],
    next: 'sumi_bandage',
  ),
  'sumi_bandage': StoryBeat(
    id: 'sumi_bandage',
    label: '针孔',
    speaker: Speaker.suMi,
    text:
        '她在我手腕内侧找到麻醉针孔，用消毒棉从中心向外擦拭。凉意触到发青的皮肤时，我的手臂本能地缩了一下。\n“疼就说。”苏弥抬眼看我，“不必因为你是调查员，就把每件事都先解释成证据。人会疼，不是推理不够冷静。”\n她的指尖在我脉搏上停留了一会儿，确认正常后才移开。',
    passageSpeakers: [Speaker.narration, Speaker.suMi, Speaker.narration],
    next: 'sumi_fatigue',
  ),
  'sumi_fatigue': StoryBeat(
    id: 'sumi_fatigue',
    label: '医生也会害怕',
    speaker: Speaker.suMi,
    text:
        '我让她把自己的手伸出来。她想用“我没有外伤”敷衍，但掌心的指甲印比任何话都明显。她在检查吴峥时一直握着拳，直到现在才完全松开。\n“我当过很多次抢救失败后的家属。”她低声说，“但我没见过有人把死亡叫作‘演示’。我刚才差点不敢再确认第二次脉搏。”',
    passageSpeakers: [Speaker.narration, Speaker.suMi],
    next: 'sumi_promise',
  ),
  'sumi_promise': StoryBeat(
    id: 'sumi_promise',
    label: '互相确认',
    speaker: Speaker.suMi,
    text:
        '我没有说“你已经尽力了”。这种话在一个死去不到一小时的人身边太轻。我只是替她把最后一捲绷带放进柜子，又在检伤表末尾加上“03 / 苏弥”。\n她看着那一行字，终于露出一点很淡的笑意。\n“我每天替你确认项圈附近的皮肤状态。作为交换，你提醒我吃饭和休息。这里不能只有医生照顾所有人。”',
    passageSpeakers: [Speaker.narration, Speaker.narration, Speaker.suMi],
    next: 'facility_search',
  ),
  'lincheng_map': StoryBeat(
    id: 'lincheng_map',
    label: '手绘地图',
    speaker: Speaker.linCheng,
    scene: SceneKey.corridor,
    text:
        '林澄没有先去看屏幕上的官方地图。她站在走廊第一块地砖的边缘，用小步一段段丈量距离，每过一扇门就在纸上留下一个数字。她的地图不好看，却比主办方版本多出门锁编号、摄像头方向、管线位置和每段路所需的步数。\n“我背公式总记不住，但走过的地方只要画一次，就不会忘。”她说。',
    passageSpeakers: [Speaker.narration, Speaker.linCheng],
    next: 'lincheng_not_child',
  ),
  'lincheng_not_child': StoryBeat(
    id: 'lincheng_not_child',
    label: '不是小孩',
    speaker: Speaker.linCheng,
    scene: SceneKey.corridor,
    text:
        '我指出地图上一处被反复擦掉的路线。林澄说，那里的墙面回音不对，后面可能存在被封住的空间。\n“你信吗？”她问得很小心。\n“我信你听见了差异。结论可以一起验证。”\n她愣了一下，又低头在那处加了一颗小星号。\n“他们都说让我待在大人中间就好。但我已经十八岁了。我不想只做需要被保护的那一个。”',
    passageSpeakers: [
      Speaker.narration,
      Speaker.linCheng,
      Speaker.shenYan,
      Speaker.narration,
      Speaker.linCheng,
    ],
    next: 'lincheng_courage',
  ),
  'lincheng_courage': StoryBeat(
    id: 'lincheng_courage',
    label: '毕业之前',
    speaker: Speaker.linCheng,
    portraitMood: 'determined',
    scene: SceneKey.corridor,
    text:
        '经过一排封闭的教室时，林澄在门口停了一会儿。她说书包里还放着没有交的志愿表，父母希望她报会计，她却想学建筑。\n“昨天我最害怕的还是考不上。”她的铅笔在纸上停住，“现在想想，能为这种事烦恼真好。”\n我告诉她，七天后还来得及重新填。她没有问我是不是在安慰，只是很轻地“嗯”了一声。',
    passageSpeakers: [Speaker.narration, Speaker.linCheng, Speaker.narration],
    next: 'lincheng_startle',
  ),
  'lincheng_startle': StoryBeat(
    id: 'lincheng_startle',
    label: '扩音器的杂音',
    speaker: Speaker.shenYan,
    scene: SceneKey.corridor,
    text:
        '天花板扩音器突然爆出一下电流杂音。林澄猛地蹲下，双手护住了颈侧。纸和铅笔掉了一地。\n“不是项圈。”我先让她看我的颈侧指示灯，又把她的终端放回手里，“只是扬声器切换。先呼吸，地图我来捡。”\n她用了很久才站起来，却坚持自己把最后一张纸铺平。',
    passageSpeakers: [Speaker.narration, Speaker.shenYan, Speaker.narration],
    next: 'lincheng_promise',
  ),
  'lincheng_promise': StoryBeat(
    id: 'lincheng_promise',
    label: '青绿色发带',
    speaker: Speaker.linCheng,
    scene: SceneKey.corridor,
    text:
        '重新整理好地图后，林澄解下松散的青绿色发带，系在我的终端挂环上。\n“这条走廊的房门看起来都一样。如果停电，就把它当作返程标记。”她把结系得很牢，又用手指轻轻拉了一下，“先借给你。等我们一起出去，你再还给我。”\n她说“一起”时，声音仍然很轻，却终于没有发抖。',
    passageSpeakers: [Speaker.narration, Speaker.linCheng, Speaker.narration],
    next: 'facility_search',
  ),
  'facility_search': StoryBeat(
    id: 'facility_search',
    label: '搜索设施',
    speaker: Speaker.narration,
    scene: SceneKey.corridor,
    text:
        '各组每十分钟必须通过公共频道报告一次，没有对讲机的人则回到集合厅签名。这些规则看起来像小型救援队的作业流程，实际上每个人都在用它确认另一件事：身后的同行者有没有在等待一个独处的机会。',
    next: 'search_layout',
  ),
  'search_layout': StoryBeat(
    id: 'search_layout',
    label: '没有外界的建筑',
    speaker: Speaker.shenYan,
    scene: SceneKey.corridor,
    text:
        '这里的前身应该是一座九十年代企业研修中心。宿舍门牌、培训课表和食堂消毒记录都被刮去了公司名称，墙内却加装了新型线缆与电控锁。每一扇可能通向室外的窗都被混凝土封死，连卫生间里都没有一块能看见天光的玻璃。对方不是找到了一处监狱，而是亲手把一座普通建筑改成了监狱。',
    passageSpeakers: [Speaker.narration],
    next: 'supply_room',
  ),
  'supply_room': StoryBeat(
    id: 'supply_room',
    label: '恰好足够的物资',
    speaker: Speaker.narration,
    scene: SceneKey.corridor,
    text:
        '食堂冰柜里有足够十二人生活七天的食物，药品、饮用水和备用电池也都按人数分装好了。没有酒，没有完整刀具，却保留了可以拆成金属杆的拖把和能让人昏睡的处方药。主办方不打算让人因饥饿死去，也没有真正防止参与者伤害彼此。所谓“规则外全部允许”，并不只是一句恐吓。',
    next: 'first_alarm',
  ),
  'first_alarm': StoryBeat(
    id: 'first_alarm',
    label: '第二例死亡',
    speaker: Speaker.administrator,
    scene: SceneKey.controlRoom,
    text:
        '公共频道上原本是高原在报告设备间温度，话音到一半突然被切断。所有扬声器同时响起主办方的声音：\n“参与者10已出局。当前存活人数：10。”\n这一次没有警告、爆炸或争执。只有走廊尽头的监控室里，传来一声很轻的金属落地声。',
    passageSpeakers: [
      Speaker.narration,
      Speaker.administrator,
      Speaker.narration,
    ],
    next: 'alarm_run',
  ),
  'alarm_run': StoryBeat(
    id: 'alarm_run',
    label: '赶往监控室',
    speaker: Speaker.shenYan,
    scene: SceneKey.corridor,
    text:
        '我们沿走廊向监控室跑。其他小组的脚步从不同通道汇过来，没人再顾得保持之前小心维持的距离。韩骐在频道里连续呼叫10号，苏弥则一遍遍问是否有人看见周叙。每一次无人回答，都让那条走廊变得更长。',
    passageSpeakers: [Speaker.narration],
    next: 'body_discovery',
  ),
  'body_discovery': StoryBeat(
    id: 'body_discovery',
    label: '第二个死者',
    speaker: Speaker.narration,
    scene: SceneKey.controlRoom,
    cgId: 'cg_control_room',
    text:
        '周叙倒在监控台与机柜之间，背靠着冰冷的金属柜门。他的项圈外表完整，没有吴峥那样的烧灼痕迹，右手却死死抓着衬衫领口。印有10的终端就在他脚边，距离远不到两米。\n苏弥冲进去跪下时，所有人都不由自主地看向自己的终端。规则刚刚才被验证，现场却第一眼就与规则矛盾。',
    next: 'investigation_gate',
  ),
  'investigation_gate': StoryBeat(
    id: 'investigation_gate',
    label: '规则杀人',
    text: '',
    scene: SceneKey.controlRoom,
    next: 'after_investigation',
    phase: StoryPhase.investigation,
  ),
  'after_investigation': StoryBeat(
    id: 'after_investigation',
    label: '三项矛盾',
    speaker: Speaker.shenYan,
    scene: SceneKey.controlRoom,
    text:
        '我重新量了三次：周叙的右手与终端只相距一点四米。可项圈日志里，这个距离在三分钟前突然跳到了二十三米，并且持续了一百八十一秒。监控台下方还藏着一台本不应该通电的救生信号中继器。它的指示灯已经熄灭，外壳却还带着余温。',
    passageSpeakers: [Speaker.narration],
    next: 'crowd_suspicion',
  ),
  'crowd_suspicion': StoryBeat(
    id: 'crowd_suspicion',
    label: '每个人都有三分钟',
    speaker: Speaker.narration,
    scene: SceneKey.controlRoom,
    text:
        '“所以是主办方的设备出错了？”高原问。\n“或者是有人让它以为周叙离开了终端。”星遥说。\n这句话让所有人同时安静。从第一次警告到周叙死亡，凶手只需要三分钟。三分钟短得足以发生在任何一次去卫生间、拿水或转过走廊拐角的时候。刚才还站在一起搜索的人，开始慢慢从彼此身边退开。',
    passageSpeakers: [Speaker.gaoYuan, Speaker.liXingyao, Speaker.narration],
    next: 'tang_clause',
  ),
  'tang_clause': StoryBeat(
    id: 'tang_clause',
    label: '精确四人',
    speaker: Speaker.tangYi,
    scene: SceneKey.controlRoom,
    text:
        '唐弈在此时笑了。他没有笑得很大声，反而只是像看见某个预期中的数字那样扬起嘴角。他将终端屏幕转向众人。\n“我的生还条款是，游戏结束时必须恰好剩下四个人。现在你们知道了。如果不敢怀疑真正的凶手，就先怀疑我。这样至少会显得自己正在做事。”',
    passageSpeakers: [Speaker.narration, Speaker.tangYi],
    next: 'tang_reaction',
  ),
  'tang_reaction': StoryBeat(
    id: 'tang_reaction',
    label: '最方便的嫌疑人',
    speaker: Speaker.tangYi,
    portraitMood: 'shaken',
    scene: SceneKey.controlRoom,
    text:
        '韩骐一把抓住唐弈的衣领，将他抵到机柜上。唐弈没有反抗，硬币仍夹在指间。\n“放开他。”苏弥站到两人之间，“他的条件让他希望有人死，但不等于现场的证据已经指向他。如果条款本身就等于有罪，那我们根本不需要主办方，自己就会把对方全部杀掉。”\n韩骐最终松开了手，却没有为这个动作道歉。',
    passageSpeakers: [Speaker.narration, Speaker.suMi, Speaker.narration],
    next: 'response_choice',
  ),
  'response_choice': StoryBeat(
    id: 'response_choice',
    label: '二次分歧',
    speaker: Speaker.narration,
    scene: SceneKey.controlRoom,
    text:
        '三条线索在同一时刻分开。苏弥认为周叙的手指和项圈灼伤可以说明处决方式，必须在尸体僵硬前完成检查；星遥在频道中捕捉到了一个正向储物区移动的中继信号，对方随时可能关机；林澄则坚称停电时还有一组脚步经过了地图上不存在的备用通道。我们的人手不足以同时保护三组证据。只要现在走向其中一人，另外两人就必须独自承担结果。',
    next: null,
    choices: [
      StoryChoice(
        label: '留下帮苏弥完成检查',
        caption: '保住“至少六人存活”的合作可能',
        next: 'help_sumi',
        effect: ChoiceEffect(sumi: 1, cooperation: 1, flag: 'medical_record'),
      ),
      StoryChoice(
        label: '和星遥追踪移动信号',
        caption: '可能直接抓到操作中继器的人',
        next: 'chase_signal',
        effect: ChoiceEffect(xingyao: 1, logic: 2, flag: 'signal_trace'),
      ),
      StoryChoice(
        label: '陪林澄核对备用通道',
        caption: '她记下了停电前不属于死者的脚步声',
        next: 'help_lincheng',
        effect: ChoiceEffect(
          lincheng: 1,
          logic: 1,
          cooperation: 1,
          flag: 'student_witness',
        ),
      ),
    ],
  ),
  'help_sumi': StoryBeat(
    id: 'help_sumi',
    label: '死者留言',
    speaker: Speaker.suMi,
    scene: SceneKey.controlRoom,
    text:
        '苏弥明知周叙已经死亡，仍然按完整流程做了一次检查。死亡时间、瞳孔反应、项圈附近的灼伤位置，每一项都写在卡片上。\n“他的死亡不是项圈爆炸造成的外伤，更像是一次针对心脏的瞬时放电。规则不只有一种处决方式。”',
    passageSpeakers: [Speaker.narration, Speaker.suMi],
    next: 'sumi_exam_detail',
  ),
  'sumi_exam_detail': StoryBeat(
    id: 'sumi_exam_detail',
    label: '死者留下的字母',
    speaker: Speaker.suMi,
    scene: SceneKey.controlRoom,
    text:
        '苏弥在周叙右手掌缘发现了被汗水沾开的油性笔痕。将指节轻轻展开后，仍能辨认出一个没写完的字母R。\n“可以是Relay，也可以是某个人的名字。”她用取样袋收好证据，“我暂时只告诉你。不是因为我已经完全信任你，而是因为调查需要有一个人能把零散信息留在一起。现在你欠我一次同样重要的坦白。”',
    passageSpeakers: [Speaker.narration, Speaker.suMi],
    next: 'decrypt_gate',
  ),
  'chase_signal': StoryBeat(
    id: 'chase_signal',
    label: '空工具袋',
    speaker: Speaker.liXingyao,
    scene: SceneKey.controlRoom,
    text:
        '星遥将耳机插进终端，一边跑一边报出信号强度。移动源没有走最短路线，而是有意绕过两个摄像头。我们追到储物区时，最里面的防火门正好合上。门后只有空空的走廊，没有人影。\n“对方知道监控盲区，也知道我在用什么方法追。”星遥停下脚步，“要么他能听见我们的频道，要么他本来就在集合厅听过我说话。”',
    passageSpeakers: [Speaker.narration, Speaker.liXingyao],
    next: 'storage_trace',
  ),
  'storage_trace': StoryBeat(
    id: 'storage_trace',
    label: '空工具袋',
    speaker: Speaker.liXingyao,
    scene: SceneKey.controlRoom,
    text:
        '储物架后藏着一只空工具袋，里面留有天线接头和刚被拆下的屏蔽层。星遥把那台中继器拆成两部分，将一端连上自己的终端，屏幕上的实时距离立即变成了十八米。\n“它不需要拿走终端。”她抬头看向我，“只需要让项圈信错的信号。周叙从头到尾都没有违反两米规则。是有人替他伪造了违规。”',
    passageSpeakers: [Speaker.narration, Speaker.liXingyao],
    next: 'decrypt_gate',
  ),
  'help_lincheng': StoryBeat(
    id: 'help_lincheng',
    label: '铅笔记录',
    speaker: Speaker.linCheng,
    scene: SceneKey.corridor,
    text:
        '林澄没有直接把我带到所谓的备用通道，而是先按她当时的路线重走一遍。她在每个拐角停下，说明灯熄灭时听到的方向：周叙的皮鞋声先从监控室前经过，大约十秒后，还有一个步伐更轻的人在门外停留了十八秒。她的地图边缘记着三组很短的“嗡、嗡、嗡”，间隔与星遥发现的七秒脉冲完全一致。',
    passageSpeakers: [Speaker.narration],
    next: 'lincheng_witness',
  ),
  'lincheng_witness': StoryBeat(
    id: 'lincheng_witness',
    label: '我相信你',
    speaker: Speaker.linCheng,
    portraitMood: 'determined',
    scene: SceneKey.corridor,
    text:
        '“我只是听见了，没有看见脸。如果我公开这件事，凶手就会知道是我在停电时记了脚步。他下次会先让我闭嘴。”\n林澄反复确认自己的记录，没有为了让证言更有用而填补她不知道的部分。她手中的铅笔在发抖，笔尖却仍然准确点在十八秒的记号上。\n“但你说过会认真看我的记录。所以这一次，我也选择相信你的判断。你可以把我的名字写进证言里。”',
    passageSpeakers: [Speaker.linCheng, Speaker.narration, Speaker.linCheng],
    next: 'decrypt_gate',
  ),
  'decrypt_gate': StoryBeat(
    id: 'decrypt_gate',
    label: '伪造频道',
    text: '',
    scene: SceneKey.controlRoom,
    next: 'log_reveal',
    phase: StoryPhase.tuning,
  ),
  'log_reveal': StoryBeat(
    id: 'log_reveal',
    label: '隐藏日志',
    speaker: Speaker.shenYan,
    scene: SceneKey.controlRoom,
    text:
        '中继器在7.20 MHz附近发出不稳定的噪声。当频率精确停在小数点后两位时，屏幕终于读出被删除的连接日志：参与者10的距离信号在23:41:06被接管，转发一百八十一秒后中断。计时比处决阈值只多出一秒。这不是设备故障，也不是周叙无意中触犯规则。有人先计算好了他必须死亡的精确秒数。',
    passageSpeakers: [Speaker.narration],
    next: 'murder_realization',
  ),
  'murder_realization': StoryBeat(
    id: 'murder_realization',
    label: '规则也是凶器',
    speaker: Speaker.shenYan,
    scene: SceneKey.controlRoom,
    text:
        '我把中继器、距离日志和地面上的实际测量结果摆在一起。\n“凶手没有动项圈，也没有把终端带走。他只是伪造了一个距离，让裁定系统替自己杀人。”\n吴峥的死证明项圈可以执行规则，周叙的死则证明了更糟的事：规则不只是主办方的武器。只要找到漏洞，每个参与者都可以借用它。',
    passageSpeakers: [Speaker.narration, Speaker.shenYan, Speaker.narration],
    next: 'alliance_vote',
  ),
  'alliance_vote': StoryBeat(
    id: 'alliance_vote',
    label: '第一次表决',
    speaker: Speaker.narration,
    scene: SceneKey.controlRoom,
    text:
        '有人要求立即搜查所有人的物品，有人建议将唐弈和韩骐单独关起来，也有人坚持应该把证据交给主办方并要求它任命一名管理者。最后，十个人中只有六人同意一条最有限的原则：在弄清中继器来源之前，任何人不得单独使用通讯设备，也不得屏蔽别人的终端信号。\n这不是同盟，只是十个陌生人在恐惧中提出的第一句共同语言。',
    next: 'deduction_gate',
  ),
  'deduction_gate': StoryBeat(
    id: 'deduction_gate',
    label: '指认凶手',
    text: '',
    scene: SceneKey.controlRoom,
    next: null,
    phase: StoryPhase.deduction,
  ),
  'bad_end': StoryBeat(
    id: 'bad_end',
    label: '错误的结论',
    speaker: Speaker.shenYan,
    scene: SceneKey.controlRoom,
    text:
        '我最终把周叙的死亡解释成主动离开终端。这个答案避开了最可怕的可能：我们之中有人已经学会借规则杀人。几个人明显松了口气，甚至没有再追问中继器为什么会在断电状态下发热。\n第三天凌晨，三个区域同时出现了属于同一终端的距离信号。等我们意识到那不是系统故障，医疗区的门已经锁死，里面只剩持续三分钟的警报声。\n“你已经错过一次了。”韩骐挡在证据柜前，没有再让我靠近。此后每个人只相信自己掌握的那一小块信息，搜查组被拆散，名册上的数字一天比一天少。\n第七天，出口要求四名参与者共同提交主办者代号。大厅里明明还站着五个人，却没有任何四个人愿意在同一张确认页上签名。倒计时归零时，我终于明白，无人作证本身就是主办方准备好的处决方式。',
    passageSpeakers: [
      Speaker.narration,
      Speaker.narration,
      Speaker.hanQi,
      Speaker.narration,
    ],
    next: 'bad_end_result',
  ),
  'bad_end_result': StoryBeat(
    id: 'bad_end_result',
    label: '无人作证',
    text: '错误的安心没有结束怀疑，只让真正的凶手获得了下一次动手的时间。',
    next: null,
    phase: StoryPhase.ending,
    endingId: 'ending_silence',
  ),
  'shadow_end': StoryBeat(
    id: 'shadow_end',
    label: '各自保留',
    speaker: Speaker.shenYan,
    scene: SceneKey.controlRoom,
    text:
        '中继器的手法被我完整还原，可我仍拒绝公开自己的生还条款。唐弈没有反驳推理，只问了一个更简单的问题：“一个要求别人交出底牌的人，为什么可以继续藏着自己的牌？”\n第四天开始，所有合作都附带交换条件。药品按情报份数发放，地图被撕成三块，通讯频道每隔一小时更换一次。我们挡住了两次伪造信号，却没能阻止彼此把幸存者当成需要削减的数字。\n第六夜，韩骐为了抢回01号终端闯入封锁区。门在他身后落下时，他没有求救，只隔着玻璃看了我很久。那目光里没有愤怒，只有确认自己果然不该相信任何人的疲惫。\n出口在第七天准时打开，幸存人数恰好是四。唐弈走过我身边，将那枚一直没有抛出的硬币放进我掌心：“你找到了凶手，却替我的条件完成了剩下的工作。”',
    passageSpeakers: [
      Speaker.narration,
      Speaker.narration,
      Speaker.narration,
      Speaker.tangYi,
    ],
    next: 'shadow_end_result',
  ),
  'shadow_end_result': StoryBeat(
    id: 'shadow_end_result',
    label: '精确四人',
    text: '推理可以揭开手法，却无法替一个拒绝信任别人的人建立同盟。',
    next: null,
    phase: StoryPhase.ending,
    endingId: 'ending_four',
  ),
  'pact_end': StoryBeat(
    id: 'pact_end',
    label: '公开协议',
    speaker: Speaker.shenYan,
    scene: SceneKey.controlRoom,
    text:
        '我把隐藏日志、掌握的路线以及自己的生还条款全部投到主屏上。大厅沉默了很久。随后苏弥第一个放下终端，星遥公开频道密钥，林澄把地图原件贴上墙。秘密没有立刻消失，但独占秘密不再被视为理所当然。\n我们建立了三人交叉确认制度：任何终端离开持有者前必须由两人记录，任何新规则都要同时抄写到纸面和离线设备。第二次伪造距离发生时，十个人在四十秒内完成点名，让裁定主机无法把假信号伪装成事实。\n第六天，隐藏广播里出现了主办者撤离的杂音。没有人追出去。我们守在同一间大厅里，把十二号的空椅也留在圆圈中，因为那条被删除的记录仍然属于这场游戏。\n第七天的出口没有带来欢呼。门外是警灯、救护车和需要重复无数次的口供。叶岚说共同体不是互相信任，而是在尚未信任时，仍愿意给彼此留下验证真相的方法。我们带着这句话走进天光。',
    passageSpeakers: [
      Speaker.narration,
      Speaker.narration,
      Speaker.narration,
      Speaker.narration,
    ],
    next: 'pact_end_result',
  ),
  'pact_end_result': StoryBeat(
    id: 'pact_end_result',
    label: '临时共同体',
    text: '规则制造对立，公开而可验证的信息让幸存者第一次拥有了改写规则的力量。',
    next: null,
    phase: StoryPhase.ending,
    endingId: 'ending_pact',
  ),
  'xingyao_end': StoryBeat(
    id: 'xingyao_end',
    label: '同一频道',
    speaker: Speaker.liXingyao,
    scene: SceneKey.corridor,
    portraitMood: 'alarm',
    text:
        '第五夜，星遥在第二套网络里找到一段只持续零点七秒的回声。为了确认来源，我们背靠背坐在停电的走廊里，一个盯着项圈倒计时，一个反复校准接收器。谁也没有说困，肩膀却在不知不觉间靠在了一起。\n“以前我只相信能复现的结果。”她看着波形说，“可你每次答应回来，最后真的都会回来。这也算重复实验吧？”\n第六天，我们用那段回声反向锁定裁定主机，让所有人的距离记录恢复本地校验。主办方切断频道前，星遥将最后一份密钥同时发给了十个人。她没有再把关键答案只留在自己手里。\n出口终端在第七天确认共同证词。项圈解锁的瞬间，她先摸了摸颈侧，随后才像终于允许自己害怕一样抱住我。这个动作只持续了几秒，她却没有立刻道歉。\n走出设施后，星遥把耳机的一边塞进我手里。“外面的频道很多，但这个频率只留给你。还有，以后别再叫我02号了，沈砚。”',
    passageSpeakers: [
      Speaker.narration,
      Speaker.liXingyao,
      Speaker.narration,
      Speaker.narration,
      Speaker.liXingyao,
    ],
    next: 'xingyao_end_result',
  ),
  'xingyao_end_result': StoryBeat(
    id: 'xingyao_end_result',
    label: '同一频率',
    text: '人群散去以后，仍有一个只属于两个人的频道保持在线。',
    next: null,
    phase: StoryPhase.ending,
    endingId: 'ending_xingyao',
  ),
  'sumi_end': StoryBeat(
    id: 'sumi_end',
    label: '轮到你休息',
    speaker: Speaker.suMi,
    portraitMood: 'concerned',
    text:
        '第五天以后，临时医务点的墙上贴满了检伤记录。苏弥记得每个人服药的时间，却连续两顿忘记给自己留食物。我把她的名字补进值班表，她盯着那一行看了很久，没有像往常一样说自己没事。\n深夜换药时，她终于承认吴峥死后每次听见金属撞击都会手抖。“医生知道恐惧是什么原因，不代表身体就会听话。”\n我没有劝她坚强，只替她守完后半夜。凌晨四点，她靠在我肩上睡了二十分钟。醒来后第一句话仍是问所有人的脉搏，我便把记录板递给她，让她看见我们也记住了她的。\n第七天，苏弥最后一个离开临时医务点。出口打开时，她仍先检查我颈上的压痕。我握住她总在照顾别人的手：“这次换我陪你休息。”\n门外的晨光落在她疲惫的眼睛里。她笑了一下，没有挣开，也没有再说自己可以一个人处理。',
    passageSpeakers: [
      Speaker.narration,
      Speaker.suMi,
      Speaker.narration,
      Speaker.shenYan,
      Speaker.narration,
    ],
    next: 'sumi_end_result',
  ),
  'sumi_end_result': StoryBeat(
    id: 'sumi_end_result',
    label: '脉搏之外',
    text: '照顾不再是她一个人的职责，活下来也不再只是医学意义上的结果。',
    next: null,
    phase: StoryPhase.ending,
    endingId: 'ending_sumi',
  ),
  'lincheng_end': StoryBeat(
    id: 'lincheng_end',
    label: '地图尽头',
    speaker: Speaker.linCheng,
    scene: SceneKey.corridor,
    portraitMood: 'determined',
    text:
        '第五天，林澄在地图背面发现了被反复擦除的铅笔压痕。那是十二号曾经走过的路线，也证明集合厅并非游戏真正的起点。她害怕自己看错，拉着我把每一个转角重新量了三遍。\n备用通道开启时，扩音器再次爆出刺耳杂音。她本能地捂住项圈，却没有蹲下。几秒后，她松开手，把地图举到众人都能看见的位置：“我害怕，但路线没有变。跟着标记走。”\n那张由一个学生画出的地图带十个人绕过最后一次封锁。出口前，主机要求提交设施结构证据时，所有人都在证言人一栏写下了她的姓名，而不是07号。\n林澄走到门外后哭了很久。她说不是因为害怕，而是突然又能继续烦恼志愿表、考试和毕业典礼。我把那条青绿色发带还给她，她却摇头，又将它系回我的终端。\n“毕业典礼那天，你会来吗？”她问。我答应她，这一次不需要用编号约定，也不需要倒计时提醒。',
    passageSpeakers: [
      Speaker.narration,
      Speaker.linCheng,
      Speaker.narration,
      Speaker.narration,
      Speaker.linCheng,
    ],
    next: 'lincheng_end_result',
  ),
  'lincheng_end_result': StoryBeat(
    id: 'lincheng_end_result',
    label: '毕业约定',
    text: '地图的终点不是出口，而是她终于可以继续选择的未来。',
    next: null,
    phase: StoryPhase.ending,
    endingId: 'ending_lincheng',
  ),
};

const _routeNodeSpecs = <({String id, int stage, double lane})>[
  (id: 'game_start', stage: 0, lane: 210),
  (id: 'corridor_encounter', stage: 1, lane: 210),
  (id: 'enter_hall', stage: 2, lane: 210),
  (id: 'participant_twelve', stage: 3, lane: 210),
  (id: 'screen_boot', stage: 4, lane: 210),
  (id: 'collar_detonation', stage: 5, lane: 210),
  (id: 'rule_one', stage: 6, lane: 210),
  (id: 'clause_choice', stage: 7, lane: 210),
  (id: 'public_pact', stage: 8, lane: 40),
  (id: 'partial_pact', stage: 8, lane: 210),
  (id: 'conceal_pact', stage: 8, lane: 380),
  (id: 'partner_choice', stage: 9, lane: 210),
  (id: 'xingyao_search', stage: 10, lane: 40),
  (id: 'sumi_infirmary', stage: 10, lane: 210),
  (id: 'lincheng_map', stage: 10, lane: 380),
  (id: 'first_alarm', stage: 11, lane: 210),
  (id: 'investigation_gate', stage: 12, lane: 210),
  (id: 'response_choice', stage: 13, lane: 210),
  (id: 'chase_signal', stage: 14, lane: 40),
  (id: 'help_sumi', stage: 14, lane: 210),
  (id: 'help_lincheng', stage: 14, lane: 380),
  (id: 'decrypt_gate', stage: 15, lane: 210),
  (id: 'deduction_gate', stage: 16, lane: 210),
  (id: 'bad_end_result', stage: 17, lane: 20),
  (id: 'shadow_end_result', stage: 17, lane: 100),
  (id: 'pact_end_result', stage: 17, lane: 180),
  (id: 'xingyao_end_result', stage: 17, lane: 260),
  (id: 'sumi_end_result', stage: 17, lane: 340),
  (id: 'lincheng_end_result', stage: 17, lane: 420),
];

final routeNodes = List<RouteNode>.unmodifiable(
  _routeNodeSpecs.map(
    (spec) => RouteNode(spec.id, 40 + spec.stage * 160, spec.lane),
  ),
);

const routeConnections = <String, List<String>>{
  'game_start': ['corridor_encounter'],
  'corridor_encounter': ['enter_hall'],
  'enter_hall': ['participant_twelve'],
  'participant_twelve': ['screen_boot'],
  'screen_boot': ['collar_detonation'],
  'collar_detonation': ['rule_one'],
  'rule_one': ['clause_choice'],
  'clause_choice': ['public_pact', 'partial_pact', 'conceal_pact'],
  'public_pact': ['partner_choice'],
  'partial_pact': ['partner_choice'],
  'conceal_pact': ['partner_choice'],
  'partner_choice': ['xingyao_search', 'sumi_infirmary', 'lincheng_map'],
  'xingyao_search': ['first_alarm'],
  'sumi_infirmary': ['first_alarm'],
  'lincheng_map': ['first_alarm'],
  'first_alarm': ['investigation_gate'],
  'investigation_gate': ['response_choice'],
  'response_choice': ['help_sumi', 'chase_signal', 'help_lincheng'],
  'help_sumi': ['decrypt_gate'],
  'chase_signal': ['decrypt_gate'],
  'help_lincheng': ['decrypt_gate'],
  'decrypt_gate': ['deduction_gate'],
  'deduction_gate': [
    'bad_end_result',
    'shadow_end_result',
    'pact_end_result',
    'xingyao_end_result',
    'sumi_end_result',
    'lincheng_end_result',
  ],
};

const cgEntries = <CgEntry>[
  CgEntry(
    id: 'cg_dormitory',
    title: '没有窗的房间',
    caption: '序章 / 苏醒',
    asset: 'assets/images/scenes/dormitory_room.png',
  ),
  CgEntry(
    id: 'cg_assembly',
    title: '十二把折叠椅',
    caption: '序章 / 初次集合',
    asset: 'assets/images/scenes/assembly_hall.png',
  ),
  CgEntry(
    id: 'cg_control_room',
    title: '封闭的监控室',
    caption: '第一章 / 第二例死亡',
    asset: 'assets/images/scenes/control_room.png',
  ),
];

const endingEntries = <EndingEntry>[
  EndingEntry(
    id: 'ending_silence',
    title: '无人作证',
    subtitle: '错误的安心比怀疑更致命。',
    rank: 'BAD END',
    nodeId: 'bad_end_result',
  ),
  EndingEntry(
    id: 'ending_four',
    title: '精确四人',
    subtitle: '你找到了凶手，却没能找到同伴。',
    rank: 'END 01',
    nodeId: 'shadow_end_result',
  ),
  EndingEntry(
    id: 'ending_pact',
    title: '临时共同体',
    subtitle: '规则制造对立，信息则能重写规则。',
    rank: 'END 02',
    nodeId: 'pact_end_result',
  ),
  EndingEntry(
    id: 'ending_xingyao',
    title: '同一频率',
    subtitle: '人群散去以后，她仍会回答你的呼叫。',
    rank: 'ROUTE 02',
    nodeId: 'xingyao_end_result',
  ),
  EndingEntry(
    id: 'ending_sumi',
    title: '脉搏之外',
    subtitle: '照顾不是一个人的职责。',
    rank: 'ROUTE 03',
    nodeId: 'sumi_end_result',
  ),
  EndingEntry(
    id: 'ending_lincheng',
    title: '毕业约定',
    subtitle: '下一次见面，不再使用编号。',
    rank: 'ROUTE 07',
    nodeId: 'lincheng_end_result',
  ),
];

String speakerName(Speaker speaker) => switch (speaker) {
  Speaker.narration => '',
  Speaker.shenYan => '沈砚 / 01',
  Speaker.liXingyao => '黎星遥 / 02',
  Speaker.suMi => '苏弥 / 03',
  Speaker.hanQi => '韩骐 / 04',
  Speaker.wuZheng => '吴峥 / 05',
  Speaker.tangYi => '唐弈 / 06',
  Speaker.linCheng => '林澄 / 07',
  Speaker.chenMo => '陈默 / 08',
  Speaker.gaoYuan => '高原 / 09',
  Speaker.zhouXu => '周叙 / 10',
  Speaker.yeLan => '叶岚 / 11',
  Speaker.administrator => 'ADMINISTRATOR',
};

const portraitMoods = <Speaker, Set<String>>{
  Speaker.liXingyao: {'neutral', 'alarm'},
  Speaker.suMi: {'neutral', 'concerned'},
  Speaker.hanQi: {'neutral', 'protective'},
  Speaker.wuZheng: {'neutral', 'defiant'},
  Speaker.tangYi: {'neutral', 'shaken'},
  Speaker.linCheng: {'neutral', 'determined'},
  Speaker.chenMo: {'neutral', 'discovery'},
  Speaker.gaoYuan: {'neutral', 'inspecting'},
  Speaker.zhouXu: {'neutral', 'defensive'},
  Speaker.yeLan: {'neutral', 'intervening'},
};

String? portraitAsset(Speaker speaker, [String mood = 'neutral']) {
  final directory = switch (speaker) {
    Speaker.liXingyao => 'li_xingyao',
    Speaker.suMi => 'su_mi',
    Speaker.hanQi => 'han_qi',
    Speaker.wuZheng => 'wu_zheng',
    Speaker.tangYi => 'tang_yi',
    Speaker.linCheng => 'lin_cheng',
    Speaker.chenMo => 'chen_mo',
    Speaker.gaoYuan => 'gao_yuan',
    Speaker.zhouXu => 'zhou_xu',
    Speaker.yeLan => 'ye_lan',
    _ => null,
  };
  if (directory == null) return null;
  final resolvedMood = portraitMoods[speaker]!.contains(mood)
      ? mood
      : 'neutral';
  return 'assets/images/characters/$directory/$resolvedMood.png';
}

EndingEntry? endingById(String? id) {
  if (id == null) return null;
  for (final ending in endingEntries) {
    if (ending.id == id) return ending;
  }
  return null;
}

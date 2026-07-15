# 资源目录规范

当前游戏只从以下目录加载正式资源：

```text
assets/
├── audio/
│   ├── bgm/                 # 循环背景音乐
│   ├── sfx/                 # 界面、环境与剧情音效
│   ├── voice/               # voice/<角色ID>/<剧情节点>_<序号>.*
│   └── audio_manifest.json  # 音频用途、循环点和台词映射
├── images/
│   ├── characters/          # characters/<角色ID>/<表情或动作>.png
│   ├── items/               # items/<场景ID>/<可调查物品>.png
│   └── scenes/              # 横屏场景背景
└── archive/v1/              # 第一版未使用资源，不参与正式构建
```

## 命名规则

- 角色目录和文件名使用小写蛇形命名，例如 `li_xingyao/alarm.png`。
- 每名角色至少保留 `neutral.png`，剧情节点通过 `portraitMood` 选择差分。
- 物品图使用透明 PNG，点击范围由 UI 控制，不把热点烘焙进背景。
- BGM 使用可无缝循环的 OGG；语音与短音效优先使用 OGG，发布前统一响度。
- 旧资源只能从 `archive` 中人工迁回，不允许业务代码直接引用归档目录。

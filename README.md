# 🧰 Hermes 技能包

两个让 Hermes Agent 更好用的技能，都支持零命令行安装。

---

## 🐴 小马日报

一个带灵魂的 AI 新闻早报。不是冷冰冰的「今日要闻」，而是一个叫小马的 AI —— 每天帮你扫一圈全球新闻，挑 3 条它自己最好奇的，按自己的品味写给你。带 emoji，带颜文字，带心情反思。

### 安装（Hermes 内一句搞定）

```
帮我安装小马日报。仓库在 https://github.com/xilefu/xiaoma-daily ，把 skills/daily-news-digest 和 skills/daily-news-digest-setup 两个目录完整复制到 ~/.hermes/skills/research/ ，然后加载 daily-news-digest-setup 帮我配置。
```

> 粘贴到 Hermes 对话框 → AI 自动下载、安装、配置。全程不需要终端。

### 两种用法

| 模式 | 怎么用 | 需要什么 |
|---|---|---|
| 手动 | 在 Hermes 里说「来一份小马日报」 | 什么都不需要 |
| 自动 | 每天早上定时推送到你手机 | 配置一个推送平台 + cron |

---

## 🎙️ 采访音频转写

把采访录音（mp3/m4a/wav）转成排版好的 Word 文档，自动去掉闲聊和无效信息，标注说话人，修正术语错误，高亮关键信息。

### 安装（Hermes 内一句搞定）

```
帮我安装采访转写。仓库在 https://github.com/xilefu/xiaoma-daily ，把 skills/interview-transcription 和 skills/interview-transcription-setup 两个目录完整复制到 ~/.hermes/skills/media/ ，然后加载 interview-transcription-setup 帮我配置。
```

### 工作流

```
录音文件 → AI 转文字 → 分辨说话人 → 去掉闲聊 → 术语修正 → 标红重点 → 排版好的 Word 文档
```

全程 AI 自动处理，你只需要提供录音文件和（可选的）排版参考文档。

---

## 技能文件

```
skills/
├── daily-news-digest/              ← 小马日报 · 主技能
│   ├── SKILL.md
│   ├── references/                 ← 新闻源 + 搜索攻略
│   └── scripts/                    ← 命令行诊断工具
├── daily-news-digest-setup/        ← 小马日报 · 安装向导
│   └── SKILL.md
├── interview-transcription/        ← 采访转写 · 主技能
│   ├── SKILL.md
│   └── references/                 ← 说话人信号词 + 术语表 + 追问设计
└── interview-transcription-setup/  ← 采访转写 · 安装向导
    └── SKILL.md
```

---

## 许可

MIT License

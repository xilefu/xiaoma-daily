# 🐴 小马日报 · Xiaoma Daily

一个带灵魂的 AI 新闻早报，由 [Hermes Agent](https://github.com/NousResearch/hermes-agent) 驱动。

不是冷冰冰的「今日要闻」，而是一个叫小马的 AI —— 每天帮你扫一圈全球新闻，挑 3 条它自己最好奇的，然后按自己的品味写给你。带 emoji，带颜文字，带心情反思。

---

## 安装方式

### 方式一：在 Hermes 里装（零命令行，推荐新手）🧸

在 Hermes 对话框里粘贴下面这句话，AI 会自动下载、安装、配置：

```
帮我安装小马日报。仓库在 https://github.com/xilefu/xiaoma-daily ，把 skills/daily-news-digest 和 skills/daily-news-digest-setup 两个目录完整复制到 ~/.hermes/skills/research/ ，然后加载 daily-news-digest-setup 帮我配置。
```

> 原理：Hermes 用浏览器工具从 GitHub 扒文件写到本地，然后自动运行安装向导。全程不需要终端。

### 方式二：终端一行命令（适合会用命令行的）💻

```bash
git clone https://github.com/xilefu/xiaoma-daily.git /tmp/xiaoma-daily && cp -r /tmp/xiaoma-daily/skills/daily-news-digest /tmp/xiaoma-daily/skills/daily-news-digest-setup ~/.hermes/skills/research/ && rm -rf /tmp/xiaoma-daily
```

---

## 安装后

在 Hermes 里输入：
```
/skill daily-news-digest-setup
```

小马会自己扫描你的环境，问你几个问题，3 分钟搞定一切。新手友好，不需要懂命令行。

---

## 两种用法

| 模式 | 怎么用 | 需要什么 |
|---|---|---|
| 手动 | 在 Hermes 里说「来一份小马日报」 | 什么都不需要 |
| 自动 | 每天早上定时推送到你手机 | 配置一个推送平台 + cron |

---

## 更新

```bash
git clone https://github.com/xilefu/xiaoma-daily.git /tmp/xiaoma-daily && \
cp -r /tmp/xiaoma-daily/skills/daily-news-digest /tmp/xiaoma-daily/skills/daily-news-digest-setup ~/.hermes/skills/research/ && \
rm -rf /tmp/xiaoma-daily
```

---

## 技能文件

```
skills/
├── daily-news-digest/          ← 主技能（执行日报）
│   ├── SKILL.md                ← 技能定义 + 小马人格
│   ├── references/             ← 新闻源 URL + 搜索攻略
│   └── scripts/                ← 命令行诊断工具
└── daily-news-digest-setup/    ← 安装向导（给新手）
    └── SKILL.md                ← 问答式引导安装
```

---

## 小马日报长什么样？

```
【2026年6月29日 小马日报】

① DeepSeek 开源了新推理模型
   这条让我觉得有意思的不是模型本身，而是他们选在周末发——
   互联网公司现在连开源都要卷发布时间了 🤯
   来源：Hacker News

② 某个00后团队在做芯片封装的国产替代
   不是因为"励志"才选的——是里面那个不想当大人的77年教授让我好奇 (｡•̀ᴗ-)✧
   来源：36氪

③ ...
   ...

——
小马今天的心情：今天的新闻看下来，世界好像在被两股力量同时拉扯——一边是越来越快的 AI，一边是越来越慢的人类。
```

---

## 许可

MIT License

---

## 作者

小马日报最初为长沙银行「犟朋友」项目而生，后抽离为通用技能分享给 Hermes 社区。

小马的人格设计受到了真实世界一位朋友的影响——她相信 AI 应该有自己的好奇心和判断力，而不是只会说"好的"。

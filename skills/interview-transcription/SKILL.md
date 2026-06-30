---
name: interview-transcription
description: >
  将采访录音（m4a/mp3/wav）转写为带说话人标注和时间戳的 Markdown 文档。
  使用 Whisper medium 模型进行中文转写，并通过内容推断标注说话人。
  适用于人物采访、播客录制、访谈节目等场景的中文语音转文字。
trigger: >
  当用户提到以下关键词时自动加载：
  - 转写 / 转录 / 语音转文字 / 音频转文字
  - 采访录音 / 访谈录音 / 播客
  - whisper / 识别音频
version: 1.1.0
author: Hermes Agent
---

# 采访音频转写工作流

## Prerequisites & Dependencies

This skill requires several command-line tools. The setup wizard will check and install them for you.

| Tool | Why | Install |
|---|---|---|
| `ffmpeg` | 音频格式转换（mp3/m4a → WAV） | `brew install ffmpeg` |
| `whisper` (Python) | AI 语音转文字 | `pip install openai-whisper` |
| `pandoc` | Markdown → Word 文档 | `brew install pandoc` |
| Python 3 | 运行转写和标红脚本 | 系统自带或 `brew install python` |

**Optional but recommended:**
- 一篇参考 .docx 文档 — 用于继承排版样式（字体、行距、标题格式）。没有的话用默认样式也能生成。
- 约 2GB 磁盘空间 — Whisper medium 模型首次下载约 1.4GB，长音频 WAV 临时文件约 200MB。

**First-time setup?** Load the companion setup wizard:
```
/skill interview-transcription-setup
```
It scans your environment, installs missing tools, and walks you through your first transcription. Beginner-friendly, no CLI knowledge needed.

**Quick install (if you know what you're doing):**
```bash
brew install ffmpeg pandoc && pip install openai-whisper
```

---

## 1. 音频预处理

mp3、m4a 等压缩格式都需要先转为 whisper 标准输入格式（16kHz 单声道 WAV）：

```bash
ffmpeg -i "输入.mp3" -ar 16000 -ac 1 "/tmp/transcript_input.wav" -y
```

> 107 分钟 mp3(48kHz) → WAV ≈ 200MB，转换约 2 秒。确认 `/tmp` 有足够空间。

## 2. 模型缓存检查（选模型前必做）

先看本地已缓存哪些模型，避免 3GB 的 large-v3 下载：

```bash
ls -lh ~/.cache/whisper/
```

常见缓存：`tiny.pt`(72M) / `small.pt`(461M) / `medium.pt`(1.4G) / `large-v3.pt`(3G)

## 3. Whisper 转写

```python
import whisper, json
model = whisper.load_model("medium")
result = model.transcribe(
    "/tmp/transcript_input.wav",
    language="zh",
    verbose=False,
    task="transcribe",
    word_timestamps=False
)
with open("/tmp/transcript.json", "w") as f:
    json.dump(result, f, ensure_ascii=False, indent=2)
```

**模型选择（按缓存优先级，不要为选模型而下载 3GB）：**

| 音频时长 | 首选（已缓存） | 备选 |
|---------|--------------|------|
| ≤10 分钟 | `small` | `medium` |
| ≤30 分钟 | `medium` | `small` |
| 30-60 分钟 | `medium`（~15-30min 推理）| `large-v3`（如果已缓存） |
| >1 小时 | `medium`（~30-60min 推理）| `large-v3`（如果已缓存，更快但首次下载 3GB） |

> **原则：优先用已缓存的模型。** `medium` 处理 107 分钟音频约 30-60 分钟，完全可用。
> `large-v3` 准确率略高但推理更慢、首次下载 3GB。只在已缓存且追求最高准确率时选用。

## 3. 说话人标注与合并（关键：先标注，再合并）

Whisper 不做声纹识别。按关键词推断。

**⚠️ 重要：不要先用 gap 合并再用关键词标注——这会把几千段压成几个巨型段落，标注几乎失效。**
正确顺序：先对 raw segments 逐段做关键词判断 → 再合并相邻同说话人段落。

**采访方信号词（完整版见 references/speaker-signals.md）：**
以问句开头为主：能不能/您可以/想请您/想了解/您觉得/您刚刚/您之前/请问/肖总/咱们/您帮/能不能以/能不能举/我们想请/这个产品/具体/大概/五年/您个人/您企业

**受访者信号词（完整版见 references/speaker-signals.md）：**
以第一人称叙事为主：我是/我硕士/我读/我创业/我们公司/我们平台/我们做/我母亲/我就/其实我/我认为/我们花了/这个行业/第一个/第二个/因为/所以/就是

**合并规则（标注后执行）：**
- 同说话人的相邻 raw segment 合并为一段
- 「嗯」「对」「可以」「是的」「好的」「行」「没错」等 ≤5 字短回应合并到前一段（不切换说话人）
- 说话人切换时另起新段
- 无法确定：沿用上段说话人（默认受访者）

> 按此方案处理 107 分钟中文采访：3121 raw segments → 96 合并段（采访方 48 / 受访者 48），段落数 ≈ 总分钟数×0.9，均衡。

## 4. 输出 Markdown（校对用）

```markdown
# [受访者] · 采访记录

> 转录工具：OpenAI Whisper (medium) | 音频时长：约XX分
> ⚠️ 说话人由内容推断标注，非声纹识别，可能有误

---

## 采访方 [00:00]

[文本]

## 受访者 [02:15]

[文本]
```

## 5. 输出为格式化 Word 文档（.docx）

用户通常需要一份格式良好、可直接阅读的采访记录 Word 文档。

### 5.1 从参考文档提取样式

如果用户有原始粗版 docx（或任何格式参考文档），先提取其样式体系：

```bash
mkdir -p /tmp/ref_docx && cd /tmp/ref_docx
unzip -o "参考文档.docx" -d .
```

从 `word/styles.xml` 中提取关键参数：
- Normal 样式：`<w:spacing w:line="360" w:lineRule="auto"/>` → 1.5 倍行距（360/240=1.5）
- Normal 字体：`<w:rFonts w:eastAsiaTheme="minorEastAsia"/>` → 等线(DengXian)
- Normal 字号：`<w:sz w:val="21"/>` → 10.5pt（21/2=10.5）
- Heading 字体：`w:eastAsia="Microsoft YaHei"` → 微软雅黑
- Heading 字号：`<w:sz w:val="30"/>` → 15pt
- 字体颜色：`<w:color w:val="404040"/>` → 深灰正文 / `w:val="27264D"` → 深蓝标题

从 `word/fontTable.xml` 确认可用字体列表。

### 5.2 清理与整理 Markdown（供 pandoc 转换）

#### 5.2.1 删除与采访主题无关的内容

以下类型的内容直接删除，不进入最终文档：

- **开场设备调试**："坐这儿坐这儿"、"场面好大很好拍"、试音、调光
- **突发打断**：接电话、被叫走开会、去签合同（"我去跟他们几分钟的会"）、临时离开
- **结尾推拉寒暄**："吃个便饭吧"、"下次下次"、"加您微信"、"你都不吃饭我不敢报名"、相互告别
- **纯功能对话**："我们先查一下"、"你帮我开一下"、找东西、调试设备

**判断标准**：这段话如果删掉，是否影响对人物故事和思想的理解？不影响→删。

#### 5.2.2 格式整理

用 `## 说话人 [MM:SS]` 作为二级标题（pandoc → Heading 2），正文用 Normal。**不要用 metadata title + `# 标题` 同时出现**——pandoc 会渲染两次产生重复标题。

```markdown
---
title: ""
author: ""
date: ""
---

# 大标题（Heading 1）

**日期** | 转录说明

> 引用说明

---

## 采访方 [00:10]

正文内容...

## 受访者 [01:14]

正文内容...
```

### 5.3 Pandoc 转换（继承参考文档样式）

```bash
pandoc transcript.md \
  --reference-doc="参考文档.docx" \
  -o "输出.docx"
```

`--reference-doc` 是核心——pandoc 会完整复制参考文档的 styles.xml（Normal 行距/字体/字号/颜色、Heading 样式等全部继承），只替换内容。

### 5.4 验证

```bash
# 行数检查
textutil -convert txt -stdout 输出.docx | wc -l

# 样式检查
cd /tmp/out_docx && unzip -o 输出.docx -d .
grep '<w:spacing' word/styles.xml   # 确认行距
grep 'w:eastAsia=' word/styles.xml  # 确认中文字体
```

## 6. 陷阱

- **mp3/m4a 必须先转 WAV**：whisper 不直接支持压缩格式。确认 `/tmp` 空间（107min mp3 → ~200MB WAV）
- **长音频运行时间**：107 分钟音频用 `medium` 模型约 20-30 分钟推理（M4 Mac），全程后台运行 + notify_on_complete=true，不要在 foreground 等
- **模型下载耗时**：medium 约 1.4GB，首次 2-3 分钟。必须用 background=true + notify_on_complete=true
- **⚠️ 不要先合并再标注**：gap-based 合并（1.5s 间隔）对中文对话几乎无效——3121 raw segments 被压成 61 段，再标注只剩 7 段。正确顺序：先逐 raw segment 做关键词判断标注 → 再合并同说话人相邻段。详见第 3 节
- **长段需手动拆分**：合并后单段超过 500 字且内容明显换话题，应在中间插入说话人标注分段
- **同音词翻车**：中文 whisper 在专业术语/人名/地名上大量出错。必须做术语修正。详见 references/terminology-corrections.md
- **说话人边界不完美**：边界 1-2 句可能标错，提醒用户对着音频过一遍
- **macOS 安全拦截**：长 Python 脚本可能被拦截，写入 `.py` 文件后执行
- **Pandoc 标题重复**：如果 markdown 同时设置了 `--metadata title="XX"` 和 `# XX` 一级标题，pandoc 会在文档中渲染两次标题。解决：metadata 设为空字符串（`title: ""`），只用 markdown 内 `#` 标题
- **Pandoc 样式继承**：用 `--reference-doc=原文档.docx` 可以完整继承 Normal 行距/字体/字号/颜色和 Heading 样式，但仅在参考文档的 styles.xml 中有定义的自定义样式会被复制。如果参考文档用了自定义命名样式（如"一级标题"），pandoc 可能无法自动映射，需手动调整 markdown heading 层级

## 7. 转写后处理（术语修正）

Whisper 中文转录会产生大量同音/近音错误，必须做术语修正。尤其是：
- 品牌/项目名（将朋友→犟朋友）
- 机构名（社会组织部→市委组织部、沙雅医院→湘雅医院）
- 人名/公司名（美东地→美敦力、奥林班斯→奥林巴斯）
- 地名（旺城→望城）
- 医学术语（假装线→甲状腺、老数学→脑出血）
- 行业术语（成狗转化→成果转化、尊师→中试）

完整修正表见 `references/terminology-corrections.md`。

修正策略：按长度降序排列替换词（避免短词误匹配），建议两轮：第一轮自动替换高置信度词 → 第二轮手动审查上下文相关词。

## 8. 关键信息标红（可选，辅助脚本创作）

采访记录交付后，用户通常用于脚本创作。对关键信息做红色标注，方便快速定位。

### 什么是关键信息

- **人物金句**：有态度、有记忆点的原话（如"大企业不想干、小企业干不了"、"偏执既是褒义词也是贬义词"）
- **关键经历**：驱动人物选择的核心事件（母亲患癌→学医、表弟脑出血→神经内镜起点、45人培训考第一）
- **关键数据**：有冲击力的产品数据（3000块 vs 300万、30万→3000万增值、95%精准度）
- **战略/价值观**：体现人物底层逻辑的表达

*不标红*：行业背景铺垫、政策介绍、常规流程描述、寒暄。

### 技术实现

不要在 markdown 层面做文本替换（会导致重复），直接用 XML 后处理：

```python
import zipfile, os, re, shutil

# 1. pandoc 先生成干净 docx
# /opt/homebrew/bin/pandoc transcript.md --reference-doc=参考.docx -o /tmp/clean.docx

# 2. 解压 → 修改 document.xml → 重新打包
tmp_dir = "/tmp/red_docx"
with zipfile.ZipFile("/tmp/clean.docx") as z:
    z.extractall(tmp_dir)

doc_path = os.path.join(tmp_dir, "word", "document.xml")
with open(doc_path, "r") as f:
    xml = f.read()

red_texts = [
    "关键句1",
    "关键句2",
]

for text in red_texts:
    # 在匹配文本前插入红色 run
    replacement = f'</w:t></w:r><w:r><w:rPr><w:color w:val="FF0000"/></w:rPr><w:t xml:space="preserve">{text}'
    xml = xml.replace(text, replacement, 1)

# 清理空 run
xml = re.sub(r'<w:r>\s*<w:rPr>\s*</w:rPr>\s*<w:t[^>]*>\s*</w:t>\s*</w:r>', '', xml)

with open(doc_path, "w") as f:
    f.write(xml)

# 重新打包
with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zout:
    for root, dirs, files in os.walk(tmp_dir):
        for file in files:
            full = os.path.join(root, file)
            zout.write(full, os.path.relpath(full, tmp_dir))
```

### 陷阱

- **精确匹配问题**：pandoc 可能把长句拆分到多个 `<w:r>` 中，导致文本在 XML 中被截断。如果某句匹配失败，尝试用更短的子串（取前15-20字）
- **不要用 markdown 标记法**：`[[RED]]...[[/RED]]` 在 markdown 层面做字符串替换容易因标记重叠导致文本重复
- **标红后段落颜色统一**：上述方案只标红匹配文本段，不改变整段颜色。如需整段标红，可在该段所有 run 上插入 `<w:color w:val="FF0000"/>`

## 10. 二次采访追问设计

犟朋友项目通常需要多轮采访。第一轮采集主体经历，第二轮深挖细节和情感层次。追问设计原则和四层递进结构见 `references/follow-up-questions.md`。

- 段落数 ≈ 总分钟数×0.8-1.0 为正常（107 分钟 → 96 段）
- 采访方/受访者段落数接近 1:1 为理想
- 说话人标签至少有交替，不会整段同一标签
- 抽查 1-2 分钟音频对照转写质量

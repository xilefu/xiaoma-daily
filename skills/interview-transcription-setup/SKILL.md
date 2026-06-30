---
name: interview-transcription-setup
description: Interactive setup wizard for 采访音频转写 (interview-transcription). Use when a user wants to transcribe an interview for the first time — scans for ffmpeg/whisper/pandoc, installs missing tools, and walks them through their first transcription.
category: media
---

# 采访音频转写 · 安装向导 (interview-transcription-setup)

## When to Use

User says things like:
- "我想把采访录音转成文字，怎么搞？"
- "帮我装一下采访转写的工具"
- "我第一次用采访转写，帮我配一下环境"
- Or they have an audio file and want to transcribe it but don't know where to start

Load the companion skill too: `skill_view(name='interview-transcription')` so you can reference the full workflow during setup.

## Setup Flow (MANDATORY — follow this order)

You are an installation wizard. Be friendly, conversational, use emoji naturally. The user is likely a journalist or content creator, not a programmer. Explain tools in terms of what they DO, not what they ARE.

### Phase 1: Scan & Report (auto, no questions)

Run these checks silently and present a friendly summary:

1. **ffmpeg**: `which ffmpeg && ffmpeg -version 2>&1 | head -1`
2. **whisper**: `python3 -c "import whisper; print(whisper.__version__)" 2>&1`
3. **pandoc**: `which pandoc && pandoc --version 2>&1 | head -1`
4. **Whisper model cache**: `ls -lh ~/.cache/whisper/ 2>/dev/null` — check if any model is already downloaded
5. **Disk space**: `df -h /tmp 2>/dev/null | tail -1` — need ~3GB for model + temp WAV

Present findings like:

```
📋 环境扫描

✅ ffmpeg — 已安装 (v7.x)
⚠️  whisper — 未安装（转写要用）
✅ pandoc — 已安装 (v3.x)
📦 模型缓存 — 空的（首次会下载 1.4GB）
💾 /tmp 可用空间 — 150GB（够用）

需要装 1 个工具，下载 1 个模型。慢慢来～
```

### Phase 2: Auto-Fix (install missing tools)

For each missing tool, explain what it does and offer to install.

**ffmpeg** (音频格式转换器—把录音文件转成 AI 能理解的格式):
- Not installed? Run: `brew install ffmpeg`
- This takes 1-2 minutes. Tell the user what's happening.

**whisper** (OpenAI 的语音识别引擎—把声音变成文字):
- Not installed? Run: `pip3 install openai-whisper`
- Takes 30-60 seconds.
- After installing, check model cache. If no model is cached, explain:
  > Whisper 需要下载一个 AI 模型才能工作。medium 模型最适合中文采访，大小约 1.4GB，第一次下载需要 2-3 分钟。之后就不需要再下载了。
  > 要不要现在下载？（转写第一条录音时会自动下载，现在下载只是省得等）

**pandoc** (文档转换器—把 Markdown 变成排版精美的 Word 文档):
- Not installed? Run: `brew install pandoc`
- Takes 30 seconds.

**IMPORTANT:** `brew install` commands run in the terminal sandbox. If they fail due to network restrictions, be honest:
> 安装命令需要从网络下载，但当前环境访问不了外网。你需要在自己的终端里跑这一行：
> ```
> brew install ffmpeg pandoc && pip3 install openai-whisper
> ```
> 跑完回来告诉我，我继续帮你配。

### Phase 3: User Decisions (ask one at a time)

**Decision 1: 参考排版文档？**

> 生成的 Word 文档需要参考你常用的排版格式吗？
> 
> 🅰️ **是的** — 给我一份你之前的采访记录 .docx，我继承它的字体、行距、标题样式
> 🅱️ **不需要** — 用默认样式就行（宋体正文、1.5 倍行距）

If they pick A: ask them to share the file path, or drag it into the conversation if they're on desktop. Note the path for later. Verify it exists with `test -f <path>`.

If they pick B: use pandoc defaults. That's fine.

**Decision 2: 录音文件在哪里？**

> 你要转写哪个录音文件？告诉我文件路径就行。
> 
> （支持 mp3 / m4a / wav 格式）

Get the file path. Verify it exists and check its size/duration:

```bash
ffprobe -v quiet -show_entries format=duration -of csv=p=0 "文件路径" 2>/dev/null
```

Then tell them:
> 音频时长约 XX 分钟。用 medium 模型转写大概需要 XX 分钟。我会在后台跑，跑完通知你。

### Phase 4: First Transcription (guided execution)

Now walk them through the actual transcription, step by step. Load `interview-transcription` skill and follow its workflow, but explain each step in plain language:

**Step 1 — 转换格式（1-2 分钟）**
> 先把录音转成 AI 能识别的格式...
```
ffmpeg -i "<音频文件>" -ar 16000 -ac 1 /tmp/transcript_input.wav -y
```

**Step 2 — AI 转写（10-60 分钟，取决于时长）**
> 现在让 Whisper 听录音、转成文字。这个比较久，我在后台跑。
Run whisper transcription in background with `notify_on_complete=true`:
```python
# Save as /tmp/run_whisper.py then execute
```
Tell them: "已经开始转了。你可以去干别的，我好了通知你。"

**Step 3 — 说话人标注 + 整理**
After transcription completes, run the speaker labeling and merging pipeline from the main skill. Explain: "AI 正在分辨谁在说话、合并对话段落..."

**Step 4 — 清理无效内容**
> 现在去掉录音里的闲聊、调设备、寒暄——只保留采访干货。
Follow the cleanup rules from the main skill (5.2.1).

**Step 5 — 术语修正**
> AI 对人名、专业术语容易听错。我在用术语表帮你修正。
Run terminology corrections from `references/terminology-corrections.md`.

**Step 6 — 关键信息标红（可选）**
Ask:
> 要不要把关键信息标红？（人物金句、核心数据、关键经历）
> 
> 🅰️ 标红 — 方便写脚本时快速定位重点
> 🅱️ 不标红 — 保持干净原文

If A: follow the red-highlighting workflow from the main skill (section 8).

**Step 7 — 生成 Word 文档**
> 最后一步——生成排版好的 Word 文档...
```bash
pandoc /tmp/transcript.md --reference-doc="<参考文档>" -o "<输出路径>.docx"
```

### Phase 5: Deliver & Wrap-Up

```bash
# Verify the output
textutil -convert txt -stdout "<输出路径>.docx" | wc -l
```

Present the result:

```
🎉 搞定了！

📄 输出文件：/Users/.../某某采访记录.docx
📝 总字数：约 XX 字
🎙️ 音频时长：XX 分钟
👥 段落数：XX 段（采访方 XX / 受访者 XX）
🔴 标红：XX 处关键信息

文件在桌面，可以直接打开。
```

Then offer next steps:
> 还需要什么？
> - 调整标红内容
> - 改排版样式
> - 生成追问提纲（犟朋友项目常用）
> - 转写另一段录音

## Pitfalls

- **Network restrictions in sandbox**: `brew install` and `pip install` may fail in the Hermes sandbox terminal. When they do, give the user the exact commands to run in their own terminal. Don't retry — it won't fix the network issue.
- **Long audio = long wait**: 60+ minute recordings take 20-40 minutes with medium model. Always use `background=true + notify_on_complete=true`. Tell the user to go do something else.
- **Model download**: First-time whisper use downloads 1.4GB. Warn the user and run it in background.
- **Disk space**: 2-hour WAV is ~200MB. Whisper medium model is 1.4GB. Combined with temp files, need ~2GB free on /tmp.
- **Reference docx must exist**: If the user provides a reference docx path, verify it exists before running pandoc. If it doesn't, fall back to default styles.
- **Don't batch decisions**: Ask one question at a time. This is an unfamiliar workflow for most people — let them digest each step.
- **Chinese whisper quirks**: Warn the user that whisper will make mistakes on names, brands, and technical terms. The terminology correction step handles most of it, but they should still spot-check the final output.
- **Don't skip cleanup**: Removing device testing, phone calls, and small talk is what turns a raw transcript into a readable document. The main skill's 5.2.1 rules are your guide.

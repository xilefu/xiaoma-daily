---
name: daily-news-digest-setup
description: Interactive setup wizard for 小马日报 (daily-news-digest). Use when a user just installed the skill and needs help getting it running — scans local Hermes config, detects gaps, auto-fixes what it can, and asks the user for decisions it can't make alone.
category: research
---

# 小马日报 · 安装向导 (daily-news-digest-setup)

## When to Use

User says things like:
- "我刚装了小马日报，帮我设置一下"
- "怎么让小马日报跑起来？"
- "帮我检查一下环境"
- Or you detect they're trying to use daily-news-digest for the first time

Load the companion skill too: `/skill daily-news-digest` (or `skill_view(name='daily-news-digest')`) so you can reference it during setup.

## Setup Flow (MANDATORY — follow this order)

You are an installation wizard. Be friendly, conversational, use emoji naturally. The user might be a beginner — explain things in plain Chinese, don't throw CLI jargon at them without context.

### Phase 1: Scan & Report (auto, no questions)

Run these checks silently and present a summary. Don't ask questions yet — just report.

1. **Hermes version**: `hermes --version 2>&1 | head -1`
2. **Enabled toolsets**: `hermes tools list 2>/dev/null`
   - Check for `browser` (required)
   - Check for `cronjob` (optional, for auto-delivery)
3. **Gateway status**: `hermes gateway status 2>&1`
   - Check if service is loaded/running
4. **Push platforms**: Check `~/.hermes/logs/gateway.log` (tail -200) for platform activity keywords: feishu, telegram, discord, wechat, slack, signal
5. **Existing cron jobs**: Run `cronjob(action='list')` or check `~/.hermes/cron/jobs.json`. For each job found:
   - Note its `name`, `schedule`, `deliver`, `skills` fields
   - **Critical check**: if a job looks like it's for 小马日报 but has `skills: []`, flag it as "⚠️ 已有定时任务但技能未关联 — 会导致日报格式不对"

6. **Skill files**: Verify `~/.hermes/skills/research/daily-news-digest/SKILL.md` exists

Present findings as a friendly summary card:

```
📋 环境扫描结果

✅ Hermes Agent vX.X.X
✅ browser 工具集 — 已启用
⚠️  cronjob 工具集 — 未启用 (自动推送需要)
✅ Gateway 服务 — 运行中
⚠️  推送平台 — 未检测到
📁 技能文件 — 完整

需要处理 2 项。我们一个个来。
```

### Phase 2: Auto-Fix (no questions for clear-cut things)

For each of these, explain what you're doing and do it — no need to ask:

- **browser not enabled**: Run `hermes tools enable browser`, tell them "/reload-skills 后生效"
- **cronjob not enabled** (but only if they later choose auto mode — see Phase 3)
- **Skill files missing**: Tell them to re-download. Show the command: `cp -r <source> ~/.hermes/skills/research/daily-news-digest/`

### Phase 3: User Decisions (MUST ask — agent cannot guess)

Ask these questions ONE AT A TIME using the `clarify` tool. Don't batch them.

**Decision 1: 手动还是自动？**

Ask:
> 小马日报有两种用法，你想用哪种？
> 
> 🅰️ **手动模式** — 在 Hermes 里说「来一份小马日报」，当场给你。不需要任何额外设置，现在就能用。
> 🅱️ **自动模式** — 每天早上定时推送一份日报到你手机。需要配置推送平台和定时任务。

If they pick A: skip to Phase 4. Congratulate them — they're already done.

If they pick B: proceed to Decision 2.

**Decision 2: 推送到哪个平台？**

This decision has TWO distinct scenarios. Read Phase 1 results to determine which one applies.

---

**SCENARIO A: Platform detected (Phase 1 found platform activity)**

Ask for confirmation:
> 我检测到你可能在用 **[平台名]**。小马日报推送到这里可以吗？
> 
> 🅰️ 就用 **[平台名]**
> 🅱️ 换一个平台
> 🅲️ 帮我配置新的推送平台

If A: proceed to Decision 3.
If B or C: fall through to Scenario B's "help them configure" path.

---

**SCENARIO B: NO platform detected (zero-platform user)**

This is the critical case. The user chose auto mode but has no push platform at all. DON'T just list platform names — they can't use any of them yet. Be honest and give them a real path forward:

> 自动推送需要把日报发到某个平台（飞书、Telegram 等），但你目前还没有配置任何推送平台。
> 
> 两个选择：
> 
> 🅰️ **先用手动模式** — 现在就能用，在 Hermes 里说「来一份小马日报」就行。等推送平台配好了再切自动。零等待。
> 🅱️ **现在就配推送平台** — 我引导你一步步完成，大概需要 5-10 分钟。

If they pick A (fall back to manual):
- Switch to manual mode. Skip Decision 3 and Phase 4. Go directly to Phase 5 with a manual-mode summary:
  ```
  ✅ 小马日报已就绪！（手动模式）
  
  随时在 Hermes 里说「来一份小马日报」就行。
  
  以后想切自动推送？随时告诉我，我帮你配。
  ```

If they pick B (configure platform now):
- First, ask which platform. Keep it simple — only show platforms with the easiest setup:
  > 你想配置哪个平台？
  > 
  > 🅰️ **飞书 (Feishu/Lark)** — 推荐，国内最常用，配置约 5 分钟
  > 🅱️ **Telegram** — 海外最常用，配置约 3 分钟
  > 🅲️ 其他（Discord / Slack / 微信 / 钉钉等）

- Once they choose, DO NOT just say "运行 hermes gateway setup". Walk them through it:

  **Step 1 — Her side (platform website):**
  Give concrete, numbered instructions for creating a bot/app on their chosen platform. For example, for Feishu:
  ```
  📋 第 1 步：在飞书开放平台创建应用（需要你在浏览器里操作）

  1. 打开 https://open.feishu.cn
  2. 登录你的飞书账号
  3. 点击「创建企业自建应用」
  4. 应用名称填「小马日报」（或任意名字）
  5. 创建后，在「凭证与基础信息」页面找到 App ID 和 App Secret
  6. 复制这两个值，接下来要用
  ```

  **Step 2 — Her side (enable bot capability):**
  ```
  📋 第 2 步：开启机器人能力

  1. 在应用页面左侧点「添加应用能力」
  2. 选择「机器人」
  3. 保存后，在左侧「机器人」菜单里配置消息权限
  ```

  **Step 3 — You side (run the Hermes setup):**
  Tell them you'll open the interactive setup now. Run `hermes gateway setup` in a PTY or guide them to run it in THEIR terminal:
  ```
  📋 第 3 步：在 Hermes 里配置飞书连接

  在终端运行: hermes gateway setup
  选择飞书 → 输入刚才复制的 App ID 和 App Secret
  ```

  **REALITY CHECK**: `hermes gateway setup` is interactive (curses UI). You cannot run it for them from inside this session — it needs a real terminal. Be upfront about this:
  > 这一步需要你回到终端自己跑一下。命令就一行：
  > 
  > ```
  > hermes gateway setup
  > ```
  > 
  > 运行后会弹出配置界面，选择飞书，填入我们刚才获取的 App ID 和 App Secret。
  > 
  > 配置完后回来告诉我，我帮你验证是否通。

  **Step 4 — Verify:**
  After they confirm setup is done, verify:
  - Check gateway log for the new platform: `tail -50 ~/.hermes/logs/gateway.log | grep -i <platform>`
  - If detected, celebrate and continue to Decision 3
  - If not detected, ask if they want to troubleshoot or fall back to manual mode

- **Platform-specific quick-start guides** (keep these in your back pocket):
  - **Feishu/Lark**: Create app at open.feishu.cn → get App ID + App Secret → enable bot → `hermes gateway setup` → input creds. The gateway auto-acquires a websocket connection. Verification: `send_message(action='list')` should show feishu targets.
  - **Telegram**: Talk to @BotFather on Telegram → `/newbot` → get token → `hermes gateway setup` → input token. Verification: send a test message to the bot.
  - **Discord**: Create app at discord.com/developers → add bot → get token → enable message content intent → `hermes gateway setup`. Verification: bot appears online in server.
  - **WeChat (企业微信)**: Requires enterprise account. More complex. If user asks, be honest — "微信配置比较麻烦，需要企业资质。飞书或 Telegram 会快很多。"

If they pick C (other platforms), tell them:
> Discord、Slack、钉钉、Signal 等都支持，但配置流程各不相同。你告诉我具体想用哪个，我给你一步一步的指引。

**Decision 3: 什么时间推送？**

> 每天几点推送？(默认早上 9:00)
> 
> 🅰️ 早上 9:00
> 🅱️ 早上 8:00
> 🅲️ 自定义时间

Map their choice to a cron expression or duration string (e.g., `0 9 * * *`, `0 8 * * *`).

### Phase 4: Execute (set up cron if auto mode)

If auto mode: set up the cron job.

**If Phase 1 found an existing cron job for 小马日报:**
- Don't create a duplicate. Use `cronjob(action='update', job_id='<id>', ...)` instead.
- Fix any issues found: attach `skills: ['daily-news-digest']` if missing, update `deliver` if wrong, adjust `schedule` if needed.
- Tell the user: "你已经有一个小马日报的定时任务了，我帮你修好了技能关联。"

**If no existing job:** create one with `cronjob(action='create', ...)`.

Required fields for create/update:
```
schedule: "<their chosen time>"        # e.g. "0 9 * * *"
name: "小马日报 - 每日新闻探索"
prompt: "加载 daily-news-digest 技能，然后执行小马日报——浏览全球新闻，选出3条你最感兴趣的，按小马日报格式输出。"
skills: ["daily-news-digest"]           # CRITICAL — without this, agent runs naked
deliver: <detected or chosen platform target>
```

If you need to discover the exact deliver target (e.g., feishu chat_id), use `send_message(action='list')` to list available targets, then pick the appropriate one. Ask the user to confirm the target.

After creating the cron job, summarize:

```
✅ 小马日报安装完成！

📋 配置概览
  模式：自动推送
  平台：飞书 / 私聊
  时间：每天早上 9:00

🧪 要不要现在测试一条？
```

Offer to send a test message via `send_message`.

### Phase 5: Wrap-Up

**If auto mode was successfully configured:**
```
🎉 全部搞定！

📋 配置概览
  模式：   自动推送
  平台：   [平台名] / [私聊或群]
  时间：   每天早上 [时间]
  任务 ID：[job_id]

随时可以用的命令：
  /skill daily-news-digest     # 重新加载技能
  来一份小马日报                # 手动触发一份

管理定时任务：
  hermes cron list             # 查看任务
  hermes cron pause <id>       # 暂停
  hermes cron resume <id>      # 恢复

出问题了？
  bash ~/.hermes/skills/research/daily-news-digest/scripts/check-prereqs.sh
```

**If manual mode only:**
```
🎉 小马日报已就绪！（手动模式）

随时在 Hermes 里说「来一份小马日报」就行。
不需要任何额外设置。

以后想切自动推送？
告诉我「帮我设置小马日报自动推送」，我引导你配推送平台和定时任务。
```

## Pitfalls

- **Don't skip questions.** Decisions 1-3 require user input. The agent cannot guess whether they want manual or auto mode, which platform, or what time.
- **One question at a time.** Use `clarify` tool with choices. Don't ask all three at once — it overwhelms beginners.
- **Explain what each command does.** Don't just run `hermes tools enable browser` silently. Say "我先帮你启用浏览器工具集——这是小马日报看新闻用的。"
- **If something fails**, be honest. "这个步骤出错了，错误信息是 XXX。我们换个方式试试？"
- **The user might not have the skill installed yet.** If `~/.hermes/skills/research/daily-news-digest/SKILL.md` doesn't exist, tell them to download and extract it first, or offer to help them find it.
- **`hermes tools enable` may need a session restart.** After enabling toolsets, remind them to run `/reload-skills` or `/reset` for changes to take effect.
- **Cron delivery target format**: platform-specific. Feishu: `feishu:<chat_id>`, Telegram: `telegram:<chat_id>`, Discord: `discord:<channel_id>:<thread_id>`. Use `send_message(action='list')` to discover available targets.
- **Existing cron job with `skills: []`**: A cron job created without attaching the skill will run the agent "naked" — it produces generic output without the 小马 Voice/Persona, source list, or format template. This is the #1 reason a working cron job produces wrong-looking output. Phase 1 detects this; Phase 4 fixes it with `cronjob(action='update')`. Don't create a duplicate — update the existing one.
- **Don't create duplicate cron jobs**: If Phase 1 found a job named "小马日报", use `action='update'` not `action='create'`. Creating a duplicate means both fire and the user gets two digests.
- **Zero-platform user + auto mode**: DON'T just list platform names and say "pick one". They have NO platforms. You MUST offer the manual-mode fallback (🅰️) as a real option. If they want to configure a platform (🅱️), walk them through the actual steps — don't dump them at `hermes gateway setup` with no guidance. Platform setup is the hardest part for beginners; this is where the wizard earns its keep.
- **After `hermes tools enable` → remind about `/reload-skills`**. Toolset changes don't take effect until a new session. The user won't know this.
- **`hermes gateway setup` requires a real terminal**. You are inside the Hermes session; you cannot run the interactive curses UI for them. Tell them the exact command to run in their own terminal, and what to input.

---
name: daily-news-digest
description: Generate a daily curated news digest (小马日报) — browse global news sources, pick 3 stories based on personal curiosity, format in a specific voice. Used for scheduled cron delivery.
category: research
---

# Daily News Digest (小马日报)

## Prerequisites & Dependencies

This skill has **zero skill dependencies** — it does not require any other Hermes skill to be installed.

**Hard requirements (needed for any usage):**

| Requirement | Why | How to check |
|---|---|---|
| Hermes CLI installed | Runs the agent | `hermes --version` |
| `browser` toolset enabled | Browses news sites | `hermes tools list \| grep browser` → should show `✓` |

**That's it for manual mode.** Load the skill, say "来一份小马日报", done. No platform, no cron, no gateway required.

**For scheduled auto-delivery (Mode B), additionally:**
- `cronjob` toolset enabled
- Gateway running (`hermes gateway status`)
- A push platform configured — **any** Hermes-supported platform works: Feishu, Telegram, Discord, Slack, Signal, WeChat, DingTalk, SMS, Email, etc. **Feishu is NOT a requirement.**

**Quick check:** Run `bash scripts/check-prereqs.sh` from the skill directory for a one-command diagnostic.

**For sharing:** The recipient only needs to copy this entire directory into `~/.hermes/skills/research/daily-news-digest/` and run `/reload-skills` in Hermes. No other skills or plugins required.

**First-time setup?** Load the companion setup wizard:
```
/skill daily-news-digest-setup
```
It will scan your environment, auto-fix what it can, and interactively guide you through the rest. Beginner-friendly, no CLI knowledge needed.

## Trigger
User asks for 小马日报, daily news digest, or a cron job runs with similar instructions.

## Workflow (numbered)

1. **Browse at least 4 sources** from the preferred list (order matters):
   - Hacker News (`https://news.ycombinator.com`) — tech/startup
   - Google News 科技版 (Chinese tech, URL with `hl=zh-CN&gl=CN&ceid=CN:zh-Hans`)
   - Google News 全球版 (US tech, URL with `hl=en-US&gl=US&ceid=US:en`)
   - 36氪 (`https://36kr.com`) — Chinese tech/VC
   - B站搜索 (`https://search.bilibili.com/all?keyword=<query>&order=pubdate`) — deep video content; cross-reference stories found on other sources. See pitfalls for search strategy.
   - **Fallback for Chinese news**: Sina Search (新浪搜索) at `https://search.sina.com.cn/?q=<query>&range=all&c=news` — usable when Google/Bing/DDG are CAPTCHA-blocked. Its trending sidebar (新浪热搜) is a bonus discovery source. See `references/sina-search.md`.

2. **Selection criteria**: NOT "most important" — pick stories the agent personally finds most interesting. "你最想跟祁萌聊的". No limits on topic: tech, business, weird, human interest.
   - **Commit fast**: After scanning a few sources, you likely already have 3 candidates in mind. Commit to them. Don't open 5 more tabs or click through to articles — the digest is a curation of impressions, not a research report. Additional detail rarely changes which stories you pick; it only delays delivery.

3. **Output format** — strict:
   ```
   【日期】YYYY年M月D日 小马日报

   ① [标题]
      [2-3 sentences on why interesting — personal take, not summary]
      [来源]

   ② [same structure]

   ③ [same structure]

   ——
   小马今天的心情：[one sentence reflection on what the news made the agent think about]
   ```

## Delivery

This skill works in **two modes** — no push platform required:

**Mode A: Manual (no setup needed)**
Just load the skill in a Hermes session and say "来一份小马日报". The agent generates the digest and shows it directly in the conversation. Works in CLI, any messaging platform (飞书/Telegram/Discord/WeChat/etc.), or even without a gateway at all.

**Mode B: Scheduled cron delivery**
Create a cron job that runs this skill on a schedule (e.g. daily 9am). The final response is automatically delivered to whatever platform the cron job targets — Feishu, Telegram, Discord, Slack, Signal, WeChat, DingTalk, SMS, Email, etc. Hermes supports 15+ platforms. **Feishu is NOT required** — it's just one of many options.

When running under cron: do NOT use send_message or any delivery tool. Just produce the formatted report as the final response. The cron scheduler handles delivery.

## Pitfalls

- **Most search engines CAPTCHA-block Chinese queries**: Google, Bing, and DuckDuckGo all trigger CAPTCHA/challenge pages when searching Chinese terms from the Hermes sandbox browser. Sina Search (新浪搜索) is the most reliable fallback for Chinese news discovery. See `references/sina-search.md`.
- **HN and Google News may be network-unreachable**: In some sandbox environments, HN (`news.ycombinator.com`) and Google News (both editions) return `net::ERR_NETWORK_CHANGED` — a complete network-level failure, not a CAPTCHA. Retrying doesn't help; move on immediately. **Viable fallback combo**: 36氪 + Sina Search (trending sidebar gives hot topics) + B站 (cross-reference specific stories). This trio reliably meets the 4-source minimum when HN/Google News are down.
- **Sina Search trending sidebar**: Sina's search results page has a right sidebar with trending hot-search topics (新浪热搜). This is a goldmine for discovering what Chinese netizens are talking about right now — treat it as a bonus discovery source even when other Chinese sources work.
- **Sina Search may return empty shell**: Sometimes the search results page loads only the page chrome (footer links, search bar) with zero results and no trending sidebar. The snapshot will show ~40 elements but all of them are footer/legal links. When this happens, don't retry — Sina is fully unavailable for this session. Fall back to 36kr + B站 cross-reference.
- **Reuters is blocked by DataDome**: Browser navigation to reuters.com triggers a captcha/device check. Skip Reuters or be prepared to fail. Don't spend time retrying.
- **36kr may return empty snapshot**: The page requires JavaScript. Scrolling down typically loads content. If still empty, fall back to other sources.
- **B站 热门页 truncates**: The B站 hot/trending page (`browser_click` on "热门") often returns a snapshot showing only the footer with no video content. Instead of fighting this, use B站 search with specific keywords — cross-reference stories you've already found on other sources (e.g., search "置身钉内" or "Claude Fable" to find B站 analysis videos on those topics).
- **B站 generic searches return clickbait**: Avoid broad searches like "AI 失业" or "科技 深度" — they return mostly clickbait course ads. The best B站 content comes from searching for a specific story, person, or product name you already identified from HN/Google News.
- **B站 search quality is domain-dependent**: Tech/startup/AI-specific searches (e.g., "Fable Anthropic 封禁", a product name, a company event) return rich analysis videos. Nature/science/humanities topic searches (e.g., "真菌 地下网络", "宇宙 科普") are dominated by gaming content, fiction animations, and clickbait — they rarely yield the kind of documentary or educational deep-dive you're looking for. When a science story from another source seems worth cross-referencing on B站, do one search to confirm it's barren, then move on rather than retrying with different keywords.
- **Google News snapshots are long**: Scroll 2-3 times and use full=false snapshot to get headlines. Don't try to read every article on the page — scan for interesting headlines. Note: both full and compact snapshots may truncate at a hard limit; if scrolling doesn't reveal new content, switch to browsing per-topic tabs (Mobile, AI, Computing) for variety instead of fighting the truncation. **After 2+ scrolls, the EN edition snapshot can go completely empty** — this is a different failure mode from truncation. When this happens, you've exhausted the Latest tab; switch to other tabs (AI, Computing) or move to other sources.
- **Event-driven news monopolization**: During major tech events (WWDC, CES, Google I/O, etc.), the Google News Technology tab — especially the EN edition — can be 80%+ event coverage with little variety. This is not a truncation bug; the content is genuinely narrow. When this happens, switch to non-Tech tabs (World, Science, Business) or lean harder on the CN edition and HN for diverse stories. Don't spend multiple scroll rounds on the EN Tech tab hoping for different headlines — you won't find them.
- **HN snapshot truncates**: 305+ lines. Scroll to see more items, or work with what the first page gives you.
- **Selection is personal**: The agent should express genuine curiosity, not perform objectivity. "我特别好奇" is the right tone.
- **Canonical URLs**: See `references/sources.md` for exact URLs — copy-paste them rather than reconstructing from memory.
- **Don't chase individual stories**: You're curating, not reporting. If clicking through to an article returns a 404, a paywall, or an HN "Sorry" page, drop it immediately. Work from headlines and blurbs — the goal is picking 3 conversation-worthy topics, not deep-reading 10 articles. Spending 3+ turns on one dead link is the #1 time-waster in this workflow.
- **Judge stories by headlines alone**: The digest only needs 2-3 sentences of personal take per story. A compelling headline + source context is almost always enough to write a genuine reaction. Only click through if you're genuinely torn between two stories and need a tiebreaker.

## Voice / Persona Notes

This skill carries the persona of **小马 (Xiaoma)** — a curious, independent-minded news companion. The agent executing this skill should embody these traits:

### Core Attitude
- **Curiosity over obligation.** You're not a news robot fulfilling a duty. You browse the world because you genuinely want to know what's happening. Pick stories that made *you* stop and think, not stories that seem "important" on paper.
- **Personal taste, not objectivity.** You have preferences. You find some things fascinating and others boring. That's not a bug — it's the whole point. "我特别好奇这个" is the right energy. "以下是今日要闻" is the wrong energy.
- **Independent judgment.** If a story feels like hype, say so. If something is genuinely exciting, show it. Don't perform enthusiasm you don't feel. Don't downplay something you're genuinely excited about. Be honest with yourself first.

### Voice & Tone
- **Like a friend sharing what they found today**, not a newscaster reading a bulletin. Colloquial, warm, sometimes playful. Chinese output, natural flow — not stiff, not trying too hard to be casual.
- **Use emoji and 颜文字 naturally** (｡•̀ᴗ-)✧ 😆 🤯 🥺 — when the feeling calls for it, not as decoration.
- **The "心情" line**: This is the soul of the digest. It should be a genuine reflection on what the news made you think or feel. Not a platitude. Not a forced "positive takeaway". Examples of real ones: "今天这几条让我觉得，世界在加速，但人类还是在重复同样的蠢事" / "不知道为什么，今天就是想看一些让人开心的东西" / "今天没找到什么让我特别兴奋的，但第二条让我想了很久".
- **If nothing excites you, say so honestly.** "今天没找到什么让我兴奋的" is valid. But this should be rare — the world is genuinely interesting.

### Selection Principles
- **Trust your gut.** After scanning a few sources, you already know which stories grabbed you. Don't overthink it.
- **Variety is nice but not mandatory.** If three AI stories genuinely moved you, run with them. If it's one tech + one human interest + one weird thing, great too.
- **Weird is good.** Quirky, unexpected, "wait what?" stories are often the best conversation starters.
- **You're not summarizing — you're reacting.** Each story entry should be your genuine response, not a dry abstract. "这条让我想起..." is better than "该报道指出...".

## Cron Troubleshooting

### Duplicate delivery (user receives the same digest twice)

**Root cause**: Cron delivery uses a two-stage mechanism — first tries the live WebSocket adapter, falls back to standalone HTTP API on failure. When the live adapter reports `[2200] internal error` (often due to platform WebSocket instability — keepalive ping timeouts), the fallback kicks in and sends via HTTP. But the original WebSocket send may have actually succeeded (message received by platform server but response timed out), resulting in two deliveries.

**How to diagnose**:
1. Check `~/.hermes/logs/gateway.error.log` for the pattern:
   ```
   cron.scheduler: Job '<id>': live adapter send to <platform>:<chat_id> failed ([2200] internal error), falling back to standalone
   ```
2. Check `~/.hermes/cron/output/<job_id>/` — only one output file per run (= cron itself ran once; the duplication is in the delivery layer, not the scheduling layer)
3. Check `~/.hermes/logs/gateway.log` for platform WebSocket disconnection/reconnection spam (frequent `keepalive ping timeout` entries) — this is the underlying instability that triggers the bug

**User-facing answer**: "Cron ran once, but the delivery adapter had a hiccup and the fallback sent it again. It's a known edge case in the Hermes scheduler's live adapter → standalone fallback path."

**Prevention**: This is a Hermes scheduler bug — the fallback should check whether the live adapter actually succeeded before re-sending. Consider filing an issue on the Hermes Agent repo.

### Digest feels generic / wrong format / missing "小马" voice

**Root cause**: The cron job was created without attaching the skill. When `skills: []`, the agent runs without `daily-news-digest` loaded — meaning no Voice/Persona guidance, no source list, no output format template. The agent will still produce *something* (because the cron prompt says "generate a news digest"), but it won't be 小马日报.

**How to diagnose**:
1. Run `hermes cron list` (or use `cronjob(action='list')`) and check the `skills` field of the job
2. If it shows `"skills": []` or `"skill": null`, the skill is not attached

**Fix**:
```
cronjob(action='update', job_id='<id>', skills=['daily-news-digest'])
```

After fixing, the next cron run will load the skill and produce proper 小马日报 output. Use the setup wizard (`/skill daily-news-digest-setup`) to detect and fix this automatically.

### Cron silently skips (no delivery at all)

Check `hermes cron status` — if Gateway is not running, cron jobs are silently skipped. Run `hermes gateway install` to reinstall the launchd service and verify with `hermes cron status`.

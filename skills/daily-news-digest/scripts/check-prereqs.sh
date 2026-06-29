#!/usr/bin/env bash
# 小马日报 (daily-news-digest) — 环境预检脚本
# 用法: bash scripts/check-prereqs.sh
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

pass=0
fail=0
warn=0

skill_dir="$(cd "$(dirname "$0")/.." && pwd)"
hermes_home="${HERMES_HOME:-$HOME/.hermes}"

header() { echo ""; echo -e "${BOLD}[$1]${NC} $2"; }
ok()     { echo -e "  ${GREEN}✓${NC} $1"; pass=$((pass + 1)); }
bad()    { echo -e "  ${RED}✗${NC} $1"; echo -e "    ${YELLOW}→ $2${NC}"; fail=$((fail + 1)); }
wrn()    { echo -e "  ${YELLOW}⚠${NC} $1"; echo -e "    ${YELLOW}→ $2${NC}"; warn=$((warn + 1)); }
info()   { echo -e "  ${CYAN}ℹ${NC}  $1"; }

echo ""
echo -e "${BOLD}════════════════════════════════════════${NC}"
echo -e "${BOLD}  小马日报 环境检查${NC}"
echo -e "${BOLD}  daily-news-digest · prerequisites check${NC}"
echo -e "${BOLD}════════════════════════════════════════${NC}"

# ── 1. Hermes CLI ──
header "1" "Hermes CLI"
if command -v hermes &>/dev/null; then
    ok "hermes 命令可用"
    ver=$(hermes --version 2>&1 | head -1 || echo "?")
    info "版本: ${ver}"
else
    bad "hermes 未安装" "安装: curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash"
fi

# ── 2. 工具集 (toolsets) ──
header "2" "必需工具集"

tools_output=$(hermes tools list 2>/dev/null || echo "")

if echo "$tools_output" | grep -q '✓.*enabled.*browser'; then
    ok "browser (浏览器) — 浏览新闻网站"
else
    bad "browser 未启用" "运行: hermes tools enable browser"
fi

if echo "$tools_output" | grep -q '✓.*enabled.*cronjob'; then
    ok "cronjob (定时任务) — 自动推送"
else
    wrn "cronjob 未启用 (仅影响自动推送)" "运行: hermes tools enable cronjob"
fi

# ── 3. 文件完整性 ──
header "3" "技能文件"
for f in SKILL.md references/sources.md references/sina-search.md scripts/check-prereqs.sh; do
    if [ -f "$skill_dir/$f" ]; then
        ok "$f"
    else
        bad "$f 缺失" "请重新下载完整技能目录"
    fi
done

# ── 4. 推送目标 (可选，仅 cron 自动推送需要) ──
header "4" "推送平台 (可选 — 仅自动推送需要；手动模式无需)"

gateway_log="$hermes_home/logs/gateway.log"
platforms_found=""

if [ -f "$gateway_log" ]; then
    # 从最近的 gateway 日志里检测活跃平台
    recent_log=$(tail -200 "$gateway_log" 2>/dev/null || echo "")
    
    # 检测多种平台 (Hermes 支持 15+ 种)
    if echo "$recent_log" | grep -q "feishu"; then
        platforms_found="$platforms_found 飞书"
    fi
    if echo "$recent_log" | grep -q "telegram"; then
        platforms_found="$platforms_found Telegram"
    fi
    if echo "$recent_log" | grep -q "discord"; then
        platforms_found="$platforms_found Discord"
    fi
    if echo "$recent_log" | grep -q "wechat\|weixin"; then
        platforms_found="$platforms_found 微信"
    fi
    if echo "$recent_log" | grep -q "slack"; then
        platforms_found="$platforms_found Slack"
    fi
    if echo "$recent_log" | grep -q "signal"; then
        platforms_found="$platforms_found Signal"
    fi
fi

# 也检查 cron jobs.json 里的 deliver 字段
jobs_file="$hermes_home/cron/jobs.json"
if [ -f "$jobs_file" ]; then
    cron_platforms=$(python3 -c "
import json
with open('$jobs_file') as f:
    jobs = json.load(f)
for j in jobs:
    d = j.get('deliver', '')
    if d and ':' in d:
        print(d.split(':')[0])
" 2>/dev/null || echo "")
    if [ -n "$cron_platforms" ]; then
        platforms_found="$platforms_found (cron已配置: $cron_platforms)"
    fi
fi

if [ -n "$platforms_found" ]; then
    ok "检测到推送平台:$platforms_found"
else
    info "未检测到推送平台 — 手动模式完全不受影响"
    info "如需每天自动推送: hermes gateway setup (支持飞书/Telegram/Discord/Slack/微信等15+平台)"
fi

# ── 5. Gateway 服务 (可选) ──
header "5" "Gateway 服务 (可选 — 仅自动推送需要)"

gw_status=$(hermes gateway status 2>&1 || echo "not_installed")
if echo "$gw_status" | grep -q "service is loaded\|Service definition matches"; then
    ok "Gateway 服务已加载"
elif echo "$gw_status" | grep -q "not running\|not installed"; then
    info "Gateway 未运行 — 手动模式不受影响"
else
    info "Gateway: ${gw_status}"
fi

# ── 总结 ──
echo ""
echo -e "${BOLD}════════════════════════════════════════${NC}"
echo -e "  结果: ${GREEN}${pass} 通过${NC}  ${RED}${fail} 失败${NC}  ${YELLOW}${warn} 警告${NC}"
echo -e "${BOLD}════════════════════════════════════════${NC}"
echo ""

if [ $fail -gt 0 ]; then
    echo -e "${RED}✗ 有 ${fail} 项必须修复的问题。按上方提示修复后重新运行。${NC}"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ 所有必需项已通过！${NC}"
echo ""
echo "  【手动模式】随时可用:"
echo "    hermes → /skill daily-news-digest"
echo "    输入「来一份小马日报」"
echo ""
echo "  【自动推送模式】(可选):"
echo "    hermes gateway setup               # 配置推送平台"
echo "    hermes tools enable cronjob        # 启用定时任务"
echo "    hermes cron create '0 9 * * *'     # 创建每天早上9点的任务"
echo "    (然后在 cron 对话里填入: 加载 daily-news-digest，运行小马日报)"
echo ""
echo -e "  ${CYAN}技能目录: ${skill_dir}${NC}"
echo ""

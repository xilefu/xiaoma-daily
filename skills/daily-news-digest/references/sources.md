# Canonical Source URLs

## Primary
- **Hacker News**: `https://news.ycombinator.com`
- **Google News 科技 (Chinese)**: `https://news.google.com/topics/CAAqJggKIiBDQkFTRWdvSUwyMHZNRGRqTVhZU0FtVnVHZ0pWVXlnQVAB?hl=zh-CN&gl=CN&ceid=CN:zh-Hans`
- **Google News Tech (US)**: `https://news.google.com/topics/CAAqJggKIiBDQkFTRWdvSUwyMHZNRGRqTVhZU0FtVnVHZ0pWVXlnQVAB?hl=en-US&gl=US&ceid=US:en`

## Fallback
- **Reuters**: `https://www.reuters.com` → usually blocked by DataDome
- **36氪**: `https://36kr.com` → requires JS; scroll to load content
- **Sina Search (新浪搜索)**: `https://search.sina.com.cn/?q=<query>&range=all&c=news` → Chinese news search, usable when Google/Bing are CAPTCHA-blocked. See `references/sina-search.md` for details.
- **B站 (Bilibili)**: `https://search.bilibili.com/all?keyword=<query>&order=pubdate` → search for specific stories found on other sources. Use `order=pubdate` to surface recent coverage; fall back to `order=click` if pubdate returns too much noise. Add `&duration=4` for 30-60 min deep-dive content. Do NOT browse the homepage or hot page (truncated snapshots). Do NOT use broad generic queries (returns clickbait). Best strategy: cross-reference a story already identified from HN/Google News.

## Strategy
Always start with HN + both Google News editions (3 sources minimum). Fall back to 36kr if one of the others yields nothing. If Google News is CAPTCHA-blocked, use Sina Search for Chinese news discovery. Don't waste time on Reuters.

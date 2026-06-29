# Sina Search (新浪搜索) — Chinese News Fallback

## When to use
Google, Bing, and DuckDuckGo all trigger CAPTCHA/challenge pages when searching Chinese terms from the Hermes sandbox browser. Sina Search is a domestic Chinese search engine that consistently works without CAPTCHA.

## Search URL
```
https://search.sina.com.cn/?q=<query>&range=all&c=news
```

Parameters:
- `q`: search query (URL-encoded Chinese works)
- `c=news`: filter to news results
- `range=all`: search all time ranges

## Example
```
https://search.sina.com.cn/?q=置身钉外&range=all&c=news
```

## What it's good for
- Chinese tech/business news discovery
- Finding specific articles by title or keyword
- Getting a quick overview of coverage on a Chinese topic

## Limitations
- Results are from Sina-indexed Chinese media sources only (no international sources)
- Page uses some JavaScript — results may appear after a short delay; use `browser_snapshot` after navigating
- Not suitable for English-language searches or global news

## Strategy
Use Sina Search as a complement to (not replacement for) HN/Google News. It fills the gap when western search engines are unavailable for Chinese-language queries.

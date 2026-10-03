"""Scrape Codex usage from ChatGPT's usage settings."""

import re

from playwright.sync_api import Error, TimeoutError

# The usage page calls this endpoint itself, but when ChatGPT's API is slow the
# page cancels the request and sits on "Loading usage settings…" for minutes.
USAGE_API_JS = r"""async () => {
    try {
        const session = await fetch("/api/auth/session", {signal: AbortSignal.timeout(15000)})
            .then(r => r.json());
        if (!session.accessToken) return {loggedOut: true};
        const res = await fetch("/backend-api/wham/usage", {
            headers: {Authorization: "Bearer " + session.accessToken},
            signal: AbortSignal.timeout(20000),
        });
        if (!res.ok) return {error: "HTTP " + res.status};
        return {usage: await res.json()};
    } catch (e) {
        return {error: String(e)};
    }
}"""


def scrape_codex(page):
    """Navigate to Codex settings and extract usage metrics.

    Args:
        page: Playwright page with active ChatGPT session

    Returns:
        dict with 'metrics' list or a failure 'status'
    """
    result = _scrape_codex_api(page)
    if result:
        return result

    try:
        page.goto(
            "https://chatgpt.com/settings/usage?tab=overview",
            wait_until="domcontentloaded",
            timeout=30000,
        )
    except TimeoutError:
        # Navigation can time out while the usage content is already readable.
        pass

    # Check if redirected to login
    if "/auth/login" in page.url or "/login" in page.url:
        return {"status": "auth_expired"}

    # Wait for percentages as well as headings so hydration has finished.
    try:
        page.wait_for_function(
            r"""() => /(?:5[ -]hour|weekly)(?: usage)? limit\s[\s\S]*?\b\d+%\s*(?:remaining|left)/i
                .test(document.body?.innerText || "")""",
            timeout=10000,
        )
    except TimeoutError:
        if "/auth/login" in page.url or "/login" in page.url:
            return {"status": "auth_expired"}
        return {"status": "error", "message": "Codex usage didn't load in time. Try Refresh."}

    text = page.inner_text("body")
    metrics = _parse_codex_text(text)

    return {"metrics": metrics} if metrics else {"status": "parse_error"}


def _scrape_codex_api(page):
    """Read usage straight from the JSON API, or None to fall back to the page."""
    try:
        page.goto("https://chatgpt.com/favicon.ico", timeout=30000)
        response = page.evaluate(USAGE_API_JS)
    except Error:
        return None

    if response.get("loggedOut"):
        return {"status": "auth_expired"}

    metrics = _parse_usage_json(response.get("usage"))
    return {"metrics": metrics} if metrics else None


def _parse_usage_json(usage):
    """Convert the usage API's rate limit windows into metrics."""
    rate_limit = (usage or {}).get("rate_limit") or {}
    metrics = []

    for key in ("primary_window", "secondary_window"):
        window = rate_limit.get(key)
        if not window:
            continue

        seconds = window.get("limit_window_seconds") or 0
        timeframe = "Wk" if seconds >= 7 * 86400 else f"{round(seconds / 3600)}h"
        metrics.append({
            "label": f"General {timeframe}",
            "percent_used": round(window.get("used_percent", 0)),
            "reset_time": _format_reset(window.get("reset_after_seconds")),
        })

    return metrics


def _format_reset(seconds):
    if seconds is None:
        return ""
    days, rest = divmod(int(seconds), 86400)
    hours, rest = divmod(rest, 3600)
    minutes = rest // 60
    if days:
        return f"Resets in {days}d {hours}h"
    if hours:
        return f"Resets in {hours}h {minutes}m"
    return f"Resets in {minutes}m"


def _parse_codex_text(text):
    """Parse Codex usage text into metrics list.

    Current page format:
        Weekly limit
        Resets in 6d 23h
        99% left

    Legacy page format:
        5 hour usage limit
        100%
        remaining

        Weekly usage limit
        85%
        remaining
        Resets Apr 8, 2026 12:50 AM

        GPT-5.3-Codex-Spark 5 hour usage limit
        100%
        remaining
    """
    metrics = []
    lines = [line.strip() for line in text.splitlines() if line.strip()]

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Both current and legacy metric headings end in "limit".
        if not stripped.lower().endswith("limit"):
            continue

        label_line = stripped

        # Determine section (General vs Spark) and timeframe (5h vs Wk)
        lower = label_line.lower()
        if "spark" in lower or "gpt-5" in lower.replace(" ", ""):
            section = "Spark"
        elif "code review" in lower:
            continue  # Skip code review metric
        else:
            section = "General"

        if re.search(r"\b5[ -]hour\b", lower):
            timeframe = "5h"
        elif "weekly" in lower:
            timeframe = "Wk"
        else:
            continue

        # Look forward for the percentage (next few lines)
        percent_remaining = None
        for j in range(i + 1, min(len(lines), i + 4)):
            if lines[j].lower().endswith("limit"):
                break
            pct_match = re.search(r"^(\d+)%\s*(?:remaining|left)?$", lines[j].strip(), re.I)
            if pct_match:
                percent_remaining = int(pct_match.group(1))
                break

        if percent_remaining is None:
            continue

        percent_used = 100 - percent_remaining

        # Look forward for reset time
        reset_time = ""
        for j in range(i + 1, min(len(lines), i + 8)):
            if lines[j].lower().endswith("limit"):
                break
            reset_match = re.search(r"^[Rr]esets?\s+(.+)$", lines[j].strip())
            if reset_match:
                reset_time = f"Resets {reset_match.group(1).strip()}"
                break

        label = f"{section} {timeframe}"
        metrics.append({
            "label": label,
            "percent_used": percent_used,
            "reset_time": reset_time
        })

    return metrics

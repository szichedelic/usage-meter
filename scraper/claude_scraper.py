"""Scrape Claude Max usage from claude.ai/settings"""

import re
from datetime import datetime, timedelta

from playwright.sync_api import TimeoutError

# The page loads this endpoint itself. Model-scoped limits such as Fable are
# only in its JSON now; the page text no longer lists them.
USAGE_API_PATH = re.compile(r"/api/organizations/[^/]+/usage$")

LIMIT_LABELS = {
    "session": "Session",
    "weekly_all": "Weekly",
}


def scrape_claude(page):
    """Navigate to Claude settings and extract usage metrics.

    Args:
        page: Playwright page with active Claude session

    Returns:
        dict with 'metrics' list or 'status': 'auth_expired'
    """
    usage = None
    try:
        with page.expect_response(
            lambda r: USAGE_API_PATH.search(r.url.split("?")[0]) and r.ok,
            timeout=15000,
        ) as response_info:
            page.goto("https://claude.ai/settings/usage", timeout=30000)
        usage = response_info.value.json()
    except (TimeoutError, ValueError):
        pass

    # Check if redirected to login
    if "/login" in page.url:
        return {"status": "auth_expired"}

    metrics = _parse_usage_json(usage)
    if metrics:
        return {"metrics": metrics}

    page.wait_for_timeout(3000)

    # Wait for usage data to load
    try:
        page.wait_for_selector("text=/Plan usage limits|Your usage/", timeout=10000)
    except Exception:
        return {"status": "auth_expired"}

    # Extract metrics from the page
    metrics = []

    # Get all the usage sections
    sections = page.query_selector_all("[class*='usage'], [class*='limit'], [data-testid*='usage']")

    # Fallback: parse the visible text content
    if not sections:
        text = page.inner_text("body")
        metrics = _parse_claude_text(text)
    else:
        for section in sections:
            text = section.inner_text()
            metrics.extend(_parse_claude_text(text))

    if not metrics:
        text = page.inner_text("body")
        metrics = _parse_claude_text(text)

    return {"metrics": metrics} if metrics else {"status": "parse_error"}


def _parse_usage_json(usage):
    """Convert the usage API's limits list into metrics."""
    metrics = []

    for limit in (usage or {}).get("limits") or []:
        label = LIMIT_LABELS.get(limit.get("kind"))
        if not label:
            scope = limit.get("scope") or {}
            label = (scope.get("model") or {}).get("display_name") or scope.get("surface")
        if not label or limit.get("percent") is None:
            continue

        metrics.append({
            "label": label,
            "percent_used": round(limit["percent"]),
            "reset_time": _format_reset(limit.get("resets_at")),
        })

    return metrics


def _format_reset(resets_at):
    """Format an ISO timestamp like the page does: 'Resets Wed 1:00 AM'."""
    if not resets_at:
        return ""
    try:
        when = datetime.fromisoformat(resets_at)
    except ValueError:
        return ""
    # The API reports times like 07:59:59.56; round to the minute.
    when = (when + timedelta(seconds=30)).replace(second=0, microsecond=0)
    return "Resets " + when.astimezone().strftime("%a %-I:%M %p")


def _parse_claude_text(text):
    """Parse usage text into metrics list."""
    metrics = []
    lines = text.split("\n")

    i = 0
    while i < len(lines):
        line = lines[i].strip()

        pct_match = re.search(r"(\d+)%\s*used", line)
        if pct_match:
            percent = int(pct_match.group(1))
            label, label_idx = _find_label(lines, i)

            if label:
                metrics.append({
                    "label": label,
                    "percent_used": percent,
                    "reset_time": _find_reset_time(lines, label_idx, i)
                })
        i += 1

    return metrics


def _find_label(lines, current_idx):
    """Look backwards from current index to find a label and its line index."""
    label_patterns = {
        "Current session": "Session",
        "All models": "Weekly",
        "Fable": "Fable",
        "This week": "Weekly",
        "Sonnet only": "Sonnet",
        "Sonnet": "Sonnet",
    }

    for j in range(current_idx, max(-1, current_idx - 7), -1):
        line = lines[j].strip()
        for pattern, short_label in label_patterns.items():
            if pattern.lower() in line.lower():
                return short_label, j

    return None, None


def _find_reset_time(lines, label_idx, pct_idx):
    """Find the reset line belonging to this metric.

    Newer layouts put it between the label and the percentage; older ones
    put it right after the percentage.
    """
    after = []
    for j in range(pct_idx + 1, min(len(lines), pct_idx + 3)):
        if "% used" in lines[j] or _find_label(lines, j)[1] == j:
            break
        after.append(j)

    for j in list(range(label_idx, pct_idx)) + after:
        reset_match = re.search(r"\bResets?\s+(.+)$", lines[j].strip())
        if reset_match:
            return f"Resets {reset_match.group(1).strip()}"
    return ""

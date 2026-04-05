"""Scrape Claude Max usage from claude.ai/settings"""

import re


def scrape_claude(page):
    """Navigate to Claude settings and extract usage metrics.

    Args:
        page: Playwright page with active Claude session

    Returns:
        dict with 'metrics' list or 'status': 'auth_expired'
    """
    page.goto("https://claude.ai/settings/usage", timeout=30000)
    page.wait_for_timeout(3000)

    # Check if redirected to login
    if "/login" in page.url:
        return {"status": "auth_expired"}

    # Wait for usage data to load
    try:
        page.wait_for_selector("text=Plan usage limits", timeout=10000)
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
            label = _find_label(lines, i)
            reset_time = _find_reset_time(lines, i)

            if label:
                metrics.append({
                    "label": label,
                    "percent_used": percent,
                    "reset_time": reset_time or ""
                })
        i += 1

    return metrics


def _find_label(lines, current_idx):
    """Look backwards from current index to find a label."""
    label_patterns = {
        "Current session": "Session",
        "All models": "Weekly",
        "Sonnet only": "Sonnet",
        "Sonnet": "Sonnet",
    }

    for j in range(max(0, current_idx - 6), current_idx + 1):
        line = lines[j].strip()
        for pattern, short_label in label_patterns.items():
            if pattern.lower() in line.lower():
                return short_label

    return None


def _find_reset_time(lines, current_idx):
    """Look near current index for reset time."""
    for j in range(max(0, current_idx - 4), min(len(lines), current_idx + 3)):
        line = lines[j].strip()
        reset_match = re.search(r"[Rr]esets?\s+in\s+(.+?)$", line)
        if reset_match:
            return f"Resets in {reset_match.group(1)}"
        reset_match2 = re.search(r"[Rr]esets?\s+([\w\s\d:]+)", line)
        if reset_match2:
            return f"Resets {reset_match2.group(1).strip()}"
    return ""

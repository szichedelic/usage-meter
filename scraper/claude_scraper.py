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

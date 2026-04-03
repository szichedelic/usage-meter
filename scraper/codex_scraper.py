"""Scrape Codex usage from chatgpt.com settings."""

import re


def scrape_codex(page):
    """Navigate to ChatGPT settings and extract Codex usage metrics.

    Args:
        page: Playwright page with active ChatGPT session

    Returns:
        dict with 'metrics' list or 'status': 'auth_expired'
    """
    page.goto("https://chatgpt.com/#settings/Usage", timeout=30000)
    page.wait_for_timeout(3000)

    # Check if redirected to login
    if "/auth/login" in page.url:
        return {"status": "auth_expired"}

    # Wait for usage data
    try:
        page.wait_for_selector("text=usage limit", timeout=10000)
    except Exception:
        return {"status": "auth_expired"}

    text = page.inner_text("body")
    metrics = _parse_codex_text(text)

    return {"metrics": metrics} if metrics else {"status": "parse_error"}


def _parse_codex_text(text):
    """Parse Codex usage text into metrics list."""
    metrics = []
    lines = text.split("\n")

    current_section = ""

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Detect section headers
        if "general usage" in stripped.lower():
            current_section = "General"
        elif "codex-spark" in stripped.lower() or "codex spark" in stripped.lower():
            current_section = "Spark"

        # Look for "X% left" patterns
        pct_match = re.search(r"(\d+)%\s*left", stripped)
        if pct_match:
            percent_left = int(pct_match.group(1))
            percent_used = 100 - percent_left

            # Determine timeframe
            timeframe = ""
            for j in range(max(0, i - 2), i + 1):
                check = lines[j].strip().lower()
                if "5 hour" in check or "5-hour" in check:
                    timeframe = "5h"
                elif "weekly" in check:
                    timeframe = "Wk"

            # Find reset time
            reset_time = ""
            for j in range(max(0, i - 2), min(len(lines), i + 3)):
                reset_match = re.search(r"[Rr]esets?\s+(.+?)$", lines[j].strip())
                if reset_match:
                    reset_time = f"Resets {reset_match.group(1).strip()}"
                    break

            label = f"{current_section} {timeframe}".strip()
            if label and timeframe:
                metrics.append({
                    "label": label,
                    "percent_used": percent_used,
                    "reset_time": reset_time
                })

    return metrics

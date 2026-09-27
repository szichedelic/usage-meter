"""Scrape Codex usage from chatgpt.com/codex/cloud/settings/usage."""

import re


def scrape_codex(page):
    """Navigate to Codex settings and extract usage metrics.

    Args:
        page: Playwright page with active ChatGPT session

    Returns:
        dict with 'metrics' list or 'status': 'auth_expired'
    """
    page.goto("https://chatgpt.com/codex/cloud/settings/usage", timeout=30000)
    page.wait_for_timeout(5000)

    # Check if redirected to login
    if "/auth/login" in page.url or "/login" in page.url:
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
    """Parse Codex usage text into metrics list.

    Actual page format:
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
    lines = text.split("\n")

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Match lines ending in "usage limit"
        if not stripped.lower().endswith("usage limit"):
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

        if "5 hour" in lower:
            timeframe = "5h"
        elif "weekly" in lower:
            timeframe = "Wk"
        else:
            continue

        # Look forward for the percentage (next few lines)
        percent_remaining = None
        for j in range(i + 1, min(len(lines), i + 4)):
            pct_match = re.search(r"^(\d+)%$", lines[j].strip())
            if pct_match:
                percent_remaining = int(pct_match.group(1))
                break

        if percent_remaining is None:
            continue

        percent_used = 100 - percent_remaining

        # Look forward for reset time
        reset_time = ""
        for j in range(i + 1, min(len(lines), i + 8)):
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

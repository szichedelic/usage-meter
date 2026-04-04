#!/usr/bin/env python3
"""UsageMeter scraper — fetches usage data from Claude and Codex web dashboards."""

import argparse
import json
import os
import sys

# Ensure scraper modules are importable regardless of working directory
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from camoufox.sync_api import Camoufox

PROFILE_DIR = os.path.expanduser("~/.usage-meter/profiles")


def login(services=None):
    """Launch visible browser for user to log in."""
    os.makedirs(PROFILE_DIR, exist_ok=True)

    if services is None:
        services = ["claude", "codex"]

    with Camoufox(persistent_context=True, user_data_dir=PROFILE_DIR, headless=False) as context:
        page = context.pages[0] if context.pages else context.new_page()

        if "claude" in services:
            page.goto("https://claude.ai/login")
            input("Log into Claude, then press Enter here to continue...")

        if "codex" in services:
            page.goto("https://chatgpt.com/auth/login")
            input("Log into ChatGPT/Codex, then press Enter here to continue...")

        page.close()

    print(json.dumps({"status": "login_complete"}))


def scrape():
    """Headless scrape of both services."""
    from claude_scraper import scrape_claude
    from codex_scraper import scrape_codex

    result = {"claude": None, "codex": None}

    if not os.path.exists(PROFILE_DIR):
        print(json.dumps({"error": "No saved profile. Run with --login first."}))
        sys.exit(1)

    with Camoufox(persistent_context=True, user_data_dir=PROFILE_DIR, headless=True) as context:
        page = context.pages[0] if context.pages else context.new_page()

        try:
            result["claude"] = scrape_claude(page)
        except Exception as e:
            result["claude"] = {"status": "error", "message": str(e)}

        try:
            result["codex"] = scrape_codex(page)
        except Exception as e:
            result["codex"] = {"status": "error", "message": str(e)}

        page.close()

    print(json.dumps(result))


def main():
    parser = argparse.ArgumentParser(description="UsageMeter scraper")
    parser.add_argument("--login", action="store_true", help="Launch browser for login")
    parser.add_argument("--login-claude", action="store_true", help="Login to Claude only")
    parser.add_argument("--login-codex", action="store_true", help="Login to Codex only")
    parser.add_argument("--headless", action="store_true", help="Run headless scrape (default)")
    args = parser.parse_args()

    if args.login:
        login()
    elif args.login_claude:
        login(["claude"])
    elif args.login_codex:
        login(["codex"])
    else:
        scrape()


if __name__ == "__main__":
    main()

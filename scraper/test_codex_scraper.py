import unittest
from unittest.mock import Mock

from playwright.sync_api import Error, TimeoutError

from codex_scraper import _parse_codex_text, scrape_codex



class ScrapeCodexTests(unittest.TestCase):
    def setUp(self):
        self.page = Mock()
        self.page.url = "https://chatgpt.com/settings/usage?tab=overview"
        self.page.inner_text.return_value = "Weekly limit\nResets in 6d 21h\n96% left"

    def test_reads_usage_after_navigation_timeout(self):
        self.page.goto.side_effect = TimeoutError("Page.goto: Timeout 30000ms exceeded")

        self.assertEqual(
            scrape_codex(self.page),
            {"metrics": [{"label": "General Wk", "percent_used": 4, "reset_time": "Resets in 6d 21h"}]},
        )

    def test_slow_usage_is_reported_as_a_refresh_error(self):
        self.page.wait_for_function.side_effect = TimeoutError("Usage didn't arrive")

        result = scrape_codex(self.page)

        self.assertEqual(result["status"], "error")
        self.assertIn("Refresh", result["message"])

    def test_detects_login_redirect_after_navigation_timeout(self):
        self.page.goto.side_effect = TimeoutError("Page.goto timed out")
        self.page.url = "https://chatgpt.com/auth/login"

        self.assertEqual(scrape_codex(self.page), {"status": "auth_expired"})

    def test_detects_login_redirect_while_waiting_for_usage(self):
        def redirect(*args, **kwargs):
            self.page.url = "https://chatgpt.com/auth/login"
            raise TimeoutError("Usage didn't arrive")

        self.page.wait_for_function.side_effect = redirect

        self.assertEqual(scrape_codex(self.page), {"status": "auth_expired"})

    def test_does_not_suppress_other_navigation_failures(self):
        self.page.goto.side_effect = Error("Network unavailable")

        with self.assertRaises(Error):
            scrape_codex(self.page)


class ParseCodexTextTests(unittest.TestCase):
    def test_parses_shared_plan_usage(self):
        text = """Plan limits
Shared across Codex, Work, Workspace Agents, and ChatGPT for Excel.
Weekly limit
Resets in 6d 23h
99% left
Credits
62,500 credits remaining
Usage limit resets
Full reset
Expires October 22"""

        self.assertEqual(
            _parse_codex_text(text),
            [{"label": "General Wk", "percent_used": 1, "reset_time": "Resets in 6d 23h"}],
        )

    def test_preserves_legacy_usage_metrics(self):
        text = """5 hour usage limit
100%
remaining
Weekly usage limit
85%
remaining
Resets Apr 8, 2026 12:50 AM
GPT-5.3-Codex-Spark 5 hour usage limit
70%
remaining
Code review weekly usage limit
50%
remaining"""

        metrics = _parse_codex_text(text)

        self.assertEqual(
            [(metric["label"], metric["percent_used"]) for metric in metrics],
            [("General 5h", 0), ("General Wk", 15), ("Spark 5h", 30)],
        )
        self.assertEqual(metrics[0]["reset_time"], "")
        self.assertEqual(metrics[1]["reset_time"], "Resets Apr 8, 2026 12:50 AM")

    def test_parses_inline_remaining_percentage(self):
        self.assertEqual(
            _parse_codex_text("5-hour limit\n0% remaining"),
            [{"label": "General 5h", "percent_used": 100, "reset_time": ""}],
        )

    def test_parses_blank_lines_between_page_elements(self):
        self.assertEqual(
            _parse_codex_text("Weekly limit\n\nResets in 6d 21h\n\n96% left"),
            [{"label": "General Wk", "percent_used": 4, "reset_time": "Resets in 6d 21h"}],
        )

    def test_does_not_borrow_percentage_from_the_next_limit(self):
        self.assertEqual(
            _parse_codex_text("Weekly limit\n5-hour limit\n40% remaining"),
            [{"label": "General 5h", "percent_used": 60, "reset_time": ""}],
        )


if __name__ == "__main__":
    unittest.main()

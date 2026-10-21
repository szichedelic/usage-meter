import unittest

from claude_scraper import _parse_claude_text, _parse_usage_json


class ParseUsageJsonTests(unittest.TestCase):
    def test_includes_model_scoped_weekly_limit(self):
        usage = {"limits": [
            {"kind": "session", "percent": 4, "resets_at": None, "scope": None},
            {"kind": "weekly_all", "percent": 59, "resets_at": None, "scope": None},
            {"kind": "weekly_scoped", "percent": 60, "resets_at": None,
             "scope": {"model": {"id": None, "display_name": "Fable"}, "surface": None}},
        ]}

        self.assertEqual(
            _parse_usage_json(usage),
            [
                {"label": "Session", "percent_used": 4, "reset_time": ""},
                {"label": "Weekly", "percent_used": 59, "reset_time": ""},
                {"label": "Fable", "percent_used": 60, "reset_time": ""},
            ],
        )

    def test_rounds_reset_time_to_the_minute(self):
        usage = {"limits": [{"kind": "session", "percent": 4,
                             "resets_at": "2026-10-21T07:59:59.568677+00:00"}]}

        reset = _parse_usage_json(usage)[0]["reset_time"]

        self.assertTrue(reset.startswith("Resets "))
        self.assertTrue(reset.endswith(":00 AM") or reset.endswith(":00 PM"))

    def test_missing_usage_returns_no_metrics(self):
        self.assertEqual(_parse_usage_json(None), [])


class ParseClaudeTextTests(unittest.TestCase):
    def test_labels_adjacent_usage_categories(self):
        text = """Current session
3% used
Resets in 4 hr 27 min
All models
28% used
Resets Wed 11:00 AM
Fable usage
34% used
Resets Wed 11:00 AM"""

        metrics = _parse_claude_text(text)

        self.assertEqual(
            [metric["label"] for metric in metrics],
            ["Session", "Weekly", "Fable"],
        )

    def test_parses_your_usage_layout(self):
        text = """Your usage
Max (20x)
On track. You should reach Wednesday’s reset with room to spare.

Current session
Resets at 6:00 PM
0% used
This week
Resets Wednesday 11:00 AM
10% used
Fable this week
Separate weekly limit for Fable · Resets Wednesday 11:00 AM
8% used
Resets"""

        metrics = _parse_claude_text(text)

        self.assertEqual(
            metrics,
            [
                {"label": "Session", "percent_used": 0, "reset_time": "Resets at 6:00 PM"},
                {"label": "Weekly", "percent_used": 10, "reset_time": "Resets Wednesday 11:00 AM"},
                {"label": "Fable", "percent_used": 8, "reset_time": "Resets Wednesday 11:00 AM"},
            ],
        )

    def test_reset_time_after_percentage(self):
        text = """Current session
3% used
Resets in 4 hr 27 min
All models
28% used
Resets Wed 11:00 AM"""

        metrics = _parse_claude_text(text)

        self.assertEqual(
            [metric["reset_time"] for metric in metrics],
            ["Resets in 4 hr 27 min", "Resets Wed 11:00 AM"],
        )


if __name__ == "__main__":
    unittest.main()

import unittest

from claude_scraper import _parse_claude_text


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


if __name__ == "__main__":
    unittest.main()

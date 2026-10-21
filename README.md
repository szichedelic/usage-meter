# UsageMeter

A macOS menu bar app that shows your Claude Max and Codex plan usage.

It shows:

- Claude session, weekly, and model-specific limits (for example, Fable)
- Codex weekly limits
- Claude peak hours
- A notification when a limit goes above your threshold

## How it works

Claude and ChatGPT do not give a public API for plan usage. A Python scraper
opens the usage pages in a headless [Camoufox](https://camoufox.com) browser.
It reads the usage data and prints JSON. The Swift app runs the scraper on a
timer and shows the result.

Your login session stays in a local browser profile at `~/.usage-meter/profiles`.
The scraper sends no data to other services.

## Requirements

- macOS 14 or later
- Python 3.10 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Setup

1. Install the scraper. This makes a virtual environment at `~/.usage-meter/venv`:

   ```sh
   ./scripts/setup-scraper.sh
   ```

2. Log in to Claude and ChatGPT. A browser window opens. Log in, then push Enter in the terminal:

   ```sh
   ~/.usage-meter/venv/bin/python scraper/scraper.py --login
   ```

3. Make the Xcode project and open it:

   ```sh
   cd UsageMeter && xcodegen && open UsageMeter.xcodeproj
   ```

4. Build and run the `UsageMeter` scheme.

If a session expires, click **Re-login** in the menu.

## Tests

```sh
cd scraper && ~/.usage-meter/venv/bin/python -m unittest
```

Run the Swift tests from Xcode with the `UsageMeterTests` target.

## Limits

The scraper reads private web pages and APIs. When Claude or ChatGPT change
these pages, the scraper can stop working until it is updated.

## License

[MIT](LICENSE)

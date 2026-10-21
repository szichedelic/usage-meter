# UsageMeter

A macOS menu bar app that shows your Claude Max and Codex plan usage.

It shows:

- Claude session, weekly, and model-specific weekly limits (for example, Fable)
- Codex 5-hour and weekly limits
- Claude peak hours (Monday to Friday, 5:00 to 11:00 AM Pacific time)
- A notification when a limit gets to the warning level (80%) or the critical level (95%)

## How it works

Claude and ChatGPT do not give a public API for plan usage. A Python scraper
opens the usage pages in a headless [Camoufox](https://camoufox.com) browser.
It reads the usage data and prints JSON. The Swift app runs the scraper every
10 minutes and shows the result.

Your login session stays in a local browser profile at `~/.usage-meter/profiles`.
The scraper sends no data to other services.

## Requirements

- macOS 14 or later
- Python 3.10 or later
- Xcode
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Setup

1. Clone the repo:

   ```sh
   git clone https://github.com/szichedelic/usage-meter.git
   cd usage-meter
   ```

   The build saves the path of the scraper into the app. If you move the
   repo, build the app again.

2. Install the scraper. This makes a virtual environment at `~/.usage-meter/venv`:

   ```sh
   ./scripts/setup-scraper.sh
   ```

3. Log in to Claude and ChatGPT. The first run downloads the Camoufox browser.
   A browser window opens. Log in to each service, then push Enter in the terminal:

   ```sh
   ~/.usage-meter/venv/bin/python scraper/scraper.py --login
   ```

   To log in to one service only, use `--login-claude` or `--login-codex`.

4. Make the Xcode project and open it:

   ```sh
   cd UsageMeter && xcodegen && open UsageMeter.xcodeproj
   ```

5. Build and run the `UsageMeter` scheme. The app shows in the menu bar, not in the Dock.

## Usage

- Click the menu bar icon to see your usage. Click **Refresh** to get new data now.
- If a session expires, click **Re-login** in the menu. A Terminal window opens with the login command.
- In **Settings**, you can change:
  - The poll interval (5, 10, 15, or 30 minutes)
  - The warning and critical thresholds
  - Launch at login
  - Re-login for each service

## Tests

```sh
cd scraper && ~/.usage-meter/venv/bin/python -m unittest
```

Run the Swift tests in Xcode with the `UsageMeterTests` target.

## Limits

The scraper reads private web pages and APIs. When Claude or ChatGPT change
these pages, the scraper can stop working until it is updated.

## License

[MIT](LICENSE)

# Data Source Spike Results

## Claude Code CLI

### Attempted approaches

| Invocation | Result |
|---|---|
| `claude status` | No `status` subcommand exists |
| `claude -p "/status"` | "Unknown skill: status" — `/status` is a built-in CLI command, not a skill |
| `claude -p "/usage"` | "Unknown skill: usage" — same issue |

### Available subcommands
`agents`, `auth`, `auto-mode`, `doctor`, `install`, `mcp`, `plugin`, `setup-token`, `update`

No `status`, `usage`, or `cost` subcommand.

### Local files
- `~/.claude/projects/<path>/<session-id>.jsonl` — conversation logs with per-message token counts (`usage.input_tokens`, `usage.output_tokens`). This is per-session token accounting, NOT subscription quota data.
- No file found containing subscription quota percentages, reset times, or rolling window data.

### Conclusion
**No programmatic way to get Claude Max subscription quota data.** The `/status` and `/usage` commands only work inside an interactive REPL session and cannot be invoked non-interactively.

**Remaining option:** Reverse-engineer the web API. The claude.ai usage page (Settings > Usage) fetches quota data from Anthropic's backend. We need to:
1. Open browser dev tools on claude.ai/settings (usage section)
2. Inspect the Network tab to find the API endpoint(s) that return quota data
3. Use the same auth cookies/tokens to call those endpoints from the app

---

## Codex CLI

### Attempted approaches

| Invocation | Result |
|---|---|
| `codex status` | No `status` subcommand exists |

### Available subcommands
`exec`, `review`, `login`, `logout`, `mcp`, `mcp-server`, `app-server`, `app`, `completion`, `sandbox`, `debug`, `apply`, `resume`, `fork`, `cloud`, `features`

No `status`, `usage`, or `quota` subcommand.

### Local files
- `~/.codex/.codex-global-state.json` — workspace/UI state, no usage data
- `~/.codex/logs_1.sqlite` — session logs database, likely per-session data
- `~/.codex/state_5.sqlite` — state database, worth investigating further
- No file found containing subscription quota percentages or reset times.

### Conclusion
**No programmatic way to get Codex subscription quota data from the CLI.** Same situation as Claude.

**Remaining option:** Same as Claude — reverse-engineer the chatgpt.com usage page API endpoints.

---

## Recommended Approach: Web Dashboard API Scraping

Since neither CLI exposes usage data programmatically, the app should:

1. **Discover the actual API endpoints** by inspecting Network tab on:
   - claude.ai Settings > Usage page
   - chatgpt.com Codex usage page
2. **Authenticate** using existing browser session cookies or OAuth tokens stored locally
3. **Call those endpoints** directly from the Swift app via URLSession

### Action needed from user
Open both usage pages in a browser, open DevTools Network tab, and capture:
- The URL of the API request(s) that return usage data
- The response JSON format
- The auth headers used (cookies, bearer token, etc.)

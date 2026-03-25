# Rails Scripts

To use these in your Rails apps simply copy them to your `bin` folder.

---

## Hatchbox

## Option 1: Zsh Function
A shell function you source in your `~/.zshrc`. App configs (name and SSH target) are defined directly in the script, so you can manage multiple apps from anywhere without a `.env` file.

We recommend placing the file in `~/.config/hatchbox/hatchbox.zsh` and sourcing it from your `~/.zshrc`:

```zsh
source ~/.config/hatchbox/hatchbox.zsh
```

Usage:
- `hatchbox myapp` — Open a plain SSH session
- `hatchbox myapp console` — Start a Rails console
- `hatchbox myapp current` — Open a shell in the current release directory
- `hatchbox myapp logs server` — Tail server logs

## Option 2: Bin Script
A convenience wrapper for SSH-ing into [Hatchbox](https://www.hatchbox.io)-deployed Rails apps. Supports opening a plain SSH session, launching a Rails console, opening a shell in the current release directory, and tailing systemd journal logs.

Configuration is via a `.env` file in your project root:

| Variable | Description |
|---|---|
| `SSH_APP_NAME` | **(required)** App path on the server |

Connection is resolved using **one** of the following (first takes precedence):

| Option | Variables needed |
|---|---|
| SSH config alias | `SSH_HOST_ALIAS` (matches a host in `~/.ssh/config`) |
| Direct host | `SSH_HOST` (connects as `deploy@SSH_HOST`) |

Usage:
- `bin/hatchbox` — Open a plain SSH session
- `bin/hatchbox console` — Start a Rails console
- `bin/hatchbox current` — Open a shell in the current release directory
- `bin/hatchbox logs server` — Tail server logs
- `bin/hatchbox logs solid_queue` — Tail queue worker logs

---

### Telegram Deploy Notification
A Rake task (`telegram:deploy_notify`) that sends a Telegram message after each deploy with the branch name, short commit SHA, and commit message. It fetches the latest push activity from the GitHub API and posts a formatted notification via the Telegram Bot API.

Requires these environment variables:

| Variable | Description |
|---|---|
| `TELEGRAM_BOT_TOKEN` | Telegram bot API token |
| `TELEGRAM_CHAT_ID` | Target chat/channel ID |
| `GITHUB_TOKEN` | GitHub personal access token |
| `GITHUB_REPO` | Repository in `owner/repo` format |

Usage:
- `bin/rails telegram:deploy_notify`

---

### Tidy
This script runs multiple code quality tools:
- JavaScript & CSS ([Prettier](https://prettier.io) + [Import Sorting](https://github.com/trivago/prettier-plugin-sort-imports)) - Formats JS and CSS files
- HTML+ERB ([Herb Formatter](https://github.com/marcoroth/herb)) - Formats HTML+ERB templates
- HTML+ERB ([Herb Linter](https://github.com/marcoroth/herb)) - Lints HTML+ERB templates

Useful for [importmaps](https://github.com/rails/importmap-rails) projects that skip Node/npm — all tools run as standalone binaries with no build step required.


Usage:
- `bin/tidy` Check mode (no changes)
- `bin/tidy --fix` Fix mode (format and auto-fix)

All tools run in parallel. Output is displayed sequentially in headers.

---

For VScode users:

You could have this run automatically on save by adding it to your commands when using [vscode-runonsave](https://github.com/emeraldwalk/vscode-runonsave). Not the fastest but good enough if you want it to run automatically.

```json
 "emeraldwalk.runonsave": {
    "commands": [
      {
        "match": "\\.(js|css|html|erb)$",
        "cmd": "bin/tidy --fix",
      },
    ]
  },
```
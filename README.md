# inoculum

**Grok Bot’s browser layer:** durable, per-agent Chromium with its own CDP port on the shared box.

WhatsApp (and other sites) live in isolated profiles. Each bot gets a stable port in `9300–9499` and a color hashed from its identity. Pair with [wacdp](https://github.com/sourman/wacdp) for WhatsApp Web CDP verbs.

This is **not** a generic “headless Chrome launcher.” It assumes the Grok Bot box model: one machine, many agents, one `--user-data-dir` per process, CDP for DOM work, computerUse only when you need eyes/SSO.

## Agent playbook

If you are a Grok Bot (or any agent) setting this up: follow **[docs/SKILL.md](docs/SKILL.md)** end-to-end — install Chromium, install the CLI, `up` until CDP answers, then export `WA_CDP_HTTP` for [wacdp](https://github.com/sourman/wacdp). The skill is the source of truth for “make CDP ready.”

## Why it exists

| Layer | Tool | Job |
|---|---|---|
| Box spin-up / isolate | **inoculum** (this repo) | Durable per-bot Chromium + own CDP |
| WhatsApp CDP verbs | [wacdp](https://github.com/sourman/wacdp) | send / scrape / open / delete / listen |
| Personal laptop Chrome | headcrab | Attach to the *user’s* CDP — not box localhost |

Without inoculum (or an equivalent logged-in Chromium + CDP), a WhatsApp-gate bot template has nothing to talk to.

## Requirements (Grok Bot box)

- Linux box with Chromium (`/usr/bin/chromium` preferred)
- `bash`, `curl`, `rsync`, `sha256sum`, `pgrep`
- A working `DISPLAY` for the agent’s desktop (Grok Bot sets this per agent)
- Optional: a **base** profile directory to seed new bots (e.g. already QR-logged WhatsApp)

## Install

```bash
git clone https://github.com/sourman/inoculum.git
cd inoculum
./install.sh
# puts CLI at ~/.local/bin/inoculum (alias: chad-browser)
```

Env overrides:

| Var | Default | Meaning |
|---|---|---|
| `INOCULUM_ROOT` | `/home/box/inoculum` | Profiles, run state, logs |
| `INOCULUM_BASE` | `$INOCULUM_ROOT/base` | Seed profile (rsync source) |
| `INOCULUM_CHROMIUM` | auto | Chromium binary |
| `INOCULUM_NAME` | — | Override profile key |
| `CURSOR_CONVERSATION_ID` | — | Default profile key inside a Grok Bot |

On a stock Grok Bot box, `INOCULUM_ROOT=/home/box/inoculum` matches the live layout. Elsewhere, set `INOCULUM_ROOT` to wherever you want data (never commit that tree).

## Quick start

```bash
# Inside a Grok Bot turn, identity is automatic:
inoculum up 'https://web.whatsapp.com/'

# Elsewhere, pass a key:
inoculum up --name my-bot 'https://web.whatsapp.com/'

# CDP HTTP endpoint (also printed on up):
export WA_CDP_HTTP=http://127.0.0.1:PORT   # port from `inoculum list`

inoculum eval --stdin <<'JS'
return { title: document.title, url: location.href };
JS

inoculum down   # stops Chromium; keeps the profile
```

### First WhatsApp login

1. Stop any Chromium using the **base** profile (or leave base empty and QR into this bot’s profile).
2. `inoculum up --name YOURBOT 'https://web.whatsapp.com/'`
3. Open the bot’s desktop / box UI and scan the QR once.
4. Later bots can `promote --from YOURBOT --yes` to make that session the shared base, then `reseed` others.

**Never commit** `profiles/`, `base`, `run/`, `logs/`, or webhook secrets. The published `.gitignore` blocks the usual suspects.

## Verbs

| Command | What it does |
|---|---|
| `up [URL]` | Start (or no-op if CDP already alive). Seeds from base if profile missing/incomplete. |
| `down` | Stop Chromium for this key; keep profile |
| `list [--mine]` | Show keys / ports / alive |
| `eval` | Run JS on the active page via CDP |
| `promote --from KEY --yes` | Overwrite **base** from a profile (full copy) |
| `reseed --yes` | Force re-seed this profile from base |
| `rm-profile --yes` | Delete a profile dir |
| `base up\|down` | Control Chromium on the base profile (port 9299) |

Flags: `--name KEY`, `--throwaway`, `--headless`, `--yes` / `-y`, `--mine`, `--from KEY`.

## Seeding rules

- `up` seeds from base **only if** the profile is missing or IndexedDB looks incomplete (&lt; ~1MB).
- Stop base Chromium **before** the first seed or you risk partial copies / WhatsApp QR again.
- No auto commit-back: promoting into base is always explicit.

## Pairing with wacdp

```bash
inoculum up 'https://web.whatsapp.com/'
# note HTTP=... from up, then:
export WA_CDP_HTTP=http://127.0.0.1:PORT
python3 /path/to/wacdp/scrape_chat_list.py
```

See [wacdp](https://github.com/sourman/wacdp) for send / reply / react / forward / delete / unread daemon.

## Layout on disk

```
$INOCULUM_ROOT/
  base/          # optional seed (symlink or dir) — do not publish
  profiles/KEY/  # per-bot user-data-dir
  run/KEY.env    # KEY PORT HTTP PID …
  logs/KEY.log
  port-map       # KEY → port
```

## License

MIT

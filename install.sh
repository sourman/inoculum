#!/usr/bin/env bash
# Install inoculum CLI onto a Grok Bot box (or any Linux host with Chromium + CDP).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="${INOCULUM_BIN:-$HOME/.local/bin}"
mkdir -p "$DEST" "${INOCULUM_ROOT:-$HOME/inoculum}"/{profiles,run,logs}
install -m 0755 "$ROOT/bin/inoculum" "$DEST/inoculum"
# Ensure DEST is on PATH for this shell hint
case ":$PATH:" in
  *":$DEST:"*) ;;
  *) echo "inoculum: add $DEST to PATH (e.g. export PATH=\"$DEST:\$PATH\")" >&2 ;;
esac
echo "inoculum: installed → $DEST/inoculum"
echo "inoculum: data root → ${INOCULUM_ROOT:-$HOME/inoculum} (override with INOCULUM_ROOT)"
"$DEST/inoculum" --help 2>/dev/null || "$DEST/inoculum" 2>&1 | head -20 || true

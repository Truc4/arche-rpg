#!/usr/bin/env bash
# Test suite for arche-rpg. Run against any arche build:
#   ARCHE=/path/to/arche ARCHE_REPO=/path/to/arche-checkout ./run_tests.sh
# ARCHE defaults to `arche` on PATH; ARCHE_REPO defaults to ../arche (its extras + stdlib are the gfx
# device + module roots). No copy/submodule — the arche repo is referenced via ARCHE_PATH.
set -euo pipefail
ARCHE="${ARCHE:-arche}"
ARCHE_REPO="${ARCHE_REPO:-../arche}"
GFX="${GFX_BACKEND:-x11}"   # headless CI uses the x11 backend under Xvfb
export ARCHE_PATH="$ARCHE_REPO/extras:$ARCHE_REPO/stdlib"
cd "$(dirname "$0")"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT

# Build with the chosen gfx backend (the committed arche.toml selects wayland for a desktop session).
restore() { mv "$T/arche.toml.bak" arche.toml 2>/dev/null || true; }
cp arche.toml "$T/arche.toml.bak"; trap 'restore; rm -rf "$T"' EXIT
sed -i "s/^gfx = \".*\"/gfx = \"$GFX\"/" arche.toml

echo "==> build app ($GFX)"
"$ARCHE" build rpg.arche -o "$T/rpg" >/dev/null

echo "==> unit tests"
"$ARCHE" build physics_test.arche -o "$T/phys" >/dev/null
"$T/phys" | grep -q "ok" || { echo "FAIL physics_test"; exit 1; }
echo "  ok physics_test.arche"

echo "==> headless smoke"
if command -v xvfb-run >/dev/null; then
  rc=0; xvfb-run -a timeout 2 "$T/rpg" >/dev/null 2>&1 || rc=$?
  # 124 = ran the full 2s then SIGTERM (good — it looped without crashing); 0 = clean exit.
  [ "$rc" = 124 ] || [ "$rc" = 0 ] || { echo "FAIL: rpg crashed (rc=$rc)"; exit 1; }
  echo "  ok ran headless ($([ "$rc" = 124 ] && echo looping || echo exited))"
else
  echo "  (xvfb-run not available — skipped smoke, build covers compile)"
fi

echo "PASS (arche-rpg)"

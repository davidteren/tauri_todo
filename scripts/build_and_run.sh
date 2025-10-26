#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Ensure we run from project root (directory with mix.exs)
if [[ ! -f "mix.exs" ]]; then
  echo -e "${RED}Error:${NC} This script must be run from the project root (where mix.exs is located)."
  echo "Current dir: $(pwd)"
  exit 1
fi

# Check required tools
command -v mix >/dev/null 2>&1 || { echo -e "${RED}mix not found. Install Elixir.${NC}"; exit 1; }
command -v npx >/dev/null 2>&1 || { echo -e "${RED}npx not found. Install Node.js/npm.${NC}"; exit 1; }

# Step 0: Clean all build artifacts and kill running processes
echo -e "${GREEN}==> Cleaning build artifacts and killing processes${NC}"
killall -9 TodoErr app beam.smp epmd 2>/dev/null || true
epmd -kill 2>/dev/null || true
sleep 1

echo -e "${YELLOW}  - Removing Elixir release${NC}"
rm -rf _build/prod/rel/todo_err

echo -e "${YELLOW}  - Removing static assets${NC}"
rm -rf priv/static/assets

echo -e "${YELLOW}  - Removing Tauri build cache${NC}"
rm -rf src-tauri/target/release

echo -e "${YELLOW}  - Cleaning Cargo cache${NC}"
cd src-tauri && cargo clean && cd ..

echo -e "${YELLOW}  - Clearing Tauri webview cache${NC}"
# Clear macOS webview cache for the app
rm -rf ~/Library/Caches/com.todoerr.desktop 2>/dev/null || true
rm -rf ~/Library/WebKit/com.todoerr.desktop 2>/dev/null || true

# Step 1: Build fresh assets
echo -e "${GREEN}==> Building fresh assets${NC}"
MIX_ENV=prod mix assets.deploy

# Step 2: Build Elixir release
echo -e "${GREEN}==> Building Elixir release (prod)${NC}"
MIX_ENV=prod mix release --overwrite

REL_DIR="_build/prod/rel/todo_err"
ERTS_BIN_GLOB="${REL_DIR}/erts-*/bin"

if [[ ! -d "$REL_DIR" ]]; then
  echo -e "${RED}Error:${NC} Release directory not found at $REL_DIR"
  exit 1
fi

# Step 3: Fix permissions
echo -e "${GREEN}==> Fixing release permissions${NC}"
chmod -R a+r "$REL_DIR"
chmod +x "$REL_DIR/bin/todo_err" || true

# Make all binaries in ERTS bin executable (if exists)
shopt -s nullglob
erlang_bins=( $ERTS_BIN_GLOB/* )
if [[ ${#erlang_bins[@]} -gt 0 ]]; then
  chmod +x $ERTS_BIN_GLOB/* || true
  if [[ -f $ERTS_BIN_GLOB/erl_child_setup ]]; then
    chmod +x $ERTS_BIN_GLOB/erl_child_setup || true
  fi
else
  echo -e "${YELLOW}Warning:${NC} No ERTS bin directory found under $REL_DIR (this is unexpected)."
fi
shopt -u nullglob

# Step 4: Build Tauri app
if [[ ! -d "src-tauri" ]]; then
  echo -e "${RED}Error:${NC} src-tauri directory not found. Are you in the project root?"
  exit 1
fi

echo -e "${GREEN}==> Building Tauri app${NC}"
pushd src-tauri >/dev/null

# Build with Tauri (cache already cleaned above)
npx tauri build

APP_PATH="target/release/bundle/macos/TodoErr.app"
DMG_PATH="target/release/bundle/dmg" # directory

if [[ -d "$APP_PATH" ]]; then
  echo -e "${GREEN}==> Built app bundle:${NC} $APP_PATH"
else
  echo -e "${RED}Error:${NC} App bundle not found at $APP_PATH"
  popd >/dev/null
  exit 1
fi

# Step 5: Post-bundle - copy Elixir release into app bundle
echo -e "${GREEN}==> Running post-bundle script${NC}"
popd >/dev/null
./scripts/post_bundle.sh "src-tauri/$APP_PATH"
pushd src-tauri >/dev/null

# Step 6: Launch the app (optional)
if [[ "${1:-}" == "--no-open" ]]; then
  echo -e "${YELLOW}Skipping app launch (--no-open)${NC}"
else
  echo -e "${GREEN}==> Launching app${NC}"
  open "$APP_PATH" || true
fi

if [[ -d "$DMG_PATH" ]]; then
  echo -e "${GREEN}==> DMG output directory:${NC} $DMG_PATH"
fi

popd >/dev/null

echo -e "${GREEN}All done!${NC}"
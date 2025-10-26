#!/usr/bin/env bash
set -euo pipefail

# Post-bundle script to copy Elixir release into the app bundle
# This runs after Tauri creates the bundle

BUNDLE_PATH="$1"
echo "Post-bundle: Copying Elixir release to $BUNDLE_PATH"

# Get the project root (parent of scripts dir)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Source and destination paths
RELEASE_SRC="$PROJECT_ROOT/_build/prod/rel/todo_err"
RESOURCES_DIR="$BUNDLE_PATH/Contents/Resources"

if [[ ! -d "$RELEASE_SRC" ]]; then
    echo "ERROR: Elixir release not found at $RELEASE_SRC"
    exit 1
fi

# Copy the entire release directory
echo "Copying release from $RELEASE_SRC to $RESOURCES_DIR/todo_err"
cp -R "$RELEASE_SRC" "$RESOURCES_DIR/todo_err"

# Ensure executable permissions
chmod -R a+r "$RESOURCES_DIR/todo_err"
chmod +x "$RESOURCES_DIR/todo_err/bin/todo_err" 2>/dev/null || true

# Make BEAM binaries executable
if [[ -d "$RESOURCES_DIR/todo_err/erts-"* ]]; then
    chmod +x "$RESOURCES_DIR"/todo_err/erts-*/bin/* 2>/dev/null || true
fi

echo "Post-bundle: Elixir release copied successfully"

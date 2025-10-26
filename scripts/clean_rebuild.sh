#!/bin/bash
set -e

echo "==> Killing all running instances..."
killall -9 TodoErr beam.smp epmd 2>/dev/null || true
epmd -kill 2>/dev/null || true
sleep 2

echo "==> Cleaning build artifacts..."
rm -rf _build/prod/rel/todo_err
rm -rf priv/static/assets
rm -rf src-tauri/target/release

echo "==> Building fresh assets..."
MIX_ENV=prod mix assets.deploy

echo "==> Building fresh Elixir release..."
MIX_ENV=prod mix release --overwrite

echo "==> Fixing permissions..."
chmod +x _build/prod/rel/todo_err/erts-*/bin/*

echo "==> Building Tauri app..."
cd src-tauri
cargo build --release
cd ..

echo "==> Bundling app..."
cd src-tauri
npx tauri build
cd ..

echo "==> Running post-bundle script..."
./scripts/post_bundle.sh

echo "==> Done! App is at: src-tauri/target/release/bundle/macos/TodoErr.app"

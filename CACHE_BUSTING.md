# Cache Busting Strategy

This document explains how TodoErr handles caching to ensure fresh builds.

## Problem

When building the Tauri desktop app, several types of caching can cause old code/styling to persist:

1. **Elixir Release Cache** - Old compiled BEAM files
2. **Static Assets Cache** - Old JavaScript/CSS files
3. **Tauri Build Cache** - Cached Rust binaries
4. **Cargo Cache** - Cached Rust dependencies
5. **Webview Cache** - Browser cache in the Tauri webview

## Solution

The `scripts/build_and_run.sh` script now implements comprehensive cache busting:

### 1. Process Cleanup
```bash
killall -9 TodoErr app beam.smp epmd
epmd -kill
```
Kills all running instances to avoid Erlang node name conflicts.

### 2. Build Artifact Removal
```bash
rm -rf _build/prod/rel/todo_err
rm -rf priv/static/assets
rm -rf src-tauri/target/release
```
Removes all compiled artifacts from previous builds.

### 3. Cargo Cache Cleaning
```bash
cd src-tauri && cargo clean && cd ..
```
Clears Rust/Cargo build cache completely.

### 4. Webview Cache Clearing
```bash
rm -rf ~/Library/Caches/com.todoerr.desktop
rm -rf ~/Library/WebKit/com.todoerr.desktop
```
Removes macOS webview cache directories.

### 5. Fresh Asset Build
```bash
MIX_ENV=prod mix assets.deploy
```
Rebuilds all assets from scratch, generating new hashed filenames.

### 6. Asset Digestion

Phoenix automatically generates hashed filenames for assets:
- `app.css` → `app-9f3a503dac8bdf055bc512c756407c00.css`
- `app.js` → `app-6e89a6b5ce894aeabb2dae8255aac82a.js`

These hashes change whenever the content changes, providing automatic cache busting.

## Usage

Simply run the build script:

```bash
./scripts/build_and_run.sh
```

Or without opening the app:

```bash
./scripts/build_and_run.sh --no-open
```

## Benefits

- ✅ **No stale code** - Every build is completely fresh
- ✅ **No manual cleanup** - Script handles everything automatically
- ✅ **Consistent builds** - Same process every time
- ✅ **Fast debugging** - No confusion about which version is running
- ✅ **Automatic cache busting** - Asset hashes change with content

## Technical Details

### Why Kill Processes?

Erlang nodes can conflict if multiple instances try to use the same node name. Killing all processes ensures a clean slate.

### Why Clean Cargo Cache?

Cargo can cache compiled Rust code that references old paths or configurations. A full clean ensures the Tauri app is rebuilt with current settings.

### Why Clear Webview Cache?

The Tauri webview (based on WebKit on macOS) can cache HTTP responses. Clearing this cache ensures the webview loads fresh assets from the Phoenix server.

### Asset Digestion vs Cache Clearing

While asset digestion (hashed filenames) provides cache busting, we still clear caches because:
1. The HTML that references the assets could be cached
2. Development iterations are faster with a clean slate
3. It prevents edge cases where old and new versions conflict

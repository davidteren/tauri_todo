# TodoErr Build Commands

## Quick Build & Run

```bash
# 1. Build Elixir release
MIX_ENV=prod mix release --overwrite

# 2. Fix permissions (important!)
chmod -R a+r _build/prod/rel/todo_err
chmod +x _build/prod/rel/todo_err/bin/todo_err
chmod +x _build/prod/rel/todo_err/erts-*/bin/*

# 3. Build Tauri app
cd src-tauri
npx tauri build

# 4. Run the app
open target/release/bundle/macos/TodoErr.app
```

## Alternative: One-liner

```bash
MIX_ENV=prod mix release --overwrite && \
chmod -R a+r _build/prod/rel/todo_err && \
chmod +x _build/prod/rel/todo_err/bin/todo_err && \
chmod +x _build/prod/rel/todo_err/erts-*/bin/* && \
cd src-tauri && \
npx tauri build && \
open target/release/bundle/macos/TodoErr.app
```

## Build Output Locations

- **App Bundle:** `src-tauri/target/release/bundle/macos/TodoErr.app`
- **DMG Installer:** `src-tauri/target/release/bundle/dmg/TodoErr_0.1.0_aarch64.dmg`

## Development Mode

```bash
# Terminal 1: Start Phoenix
mix phx.server

# Terminal 2: Start Tauri dev
cd src-tauri
npx tauri dev
```

## Troubleshooting

### Permission Denied Error
If you get "Permission denied (os error 13)" during build:
```bash
chmod -R a+r _build/prod/rel/todo_err
chmod +x _build/prod/rel/todo_err/bin/todo_err
chmod +x _build/prod/rel/todo_err/erts-*/bin/*
```

### Clean Build
```bash
# Clean Elixir build
rm -rf _build

# Clean Tauri build
cd src-tauri
cargo clean
```

## Prerequisites

- Elixir 1.17+ with Erlang/OTP 27+
- Rust 1.77.2+
- Node.js 18+
- Tauri CLI: `npm install -g @tauri-apps/cli`

---

*Last tested: October 26, 2025*
# Getting Started with TodoErr

A desktop todo application built with Phoenix LiveView and Tauri.

## Prerequisites

- **Elixir** 1.17+ with Erlang/OTP 27+
- **Rust** 1.77.2+ (for Tauri)
- **Node.js** 18+ (for build tools)
- **macOS** (primary platform)

## Quick Start - Web Development

```bash
# Install dependencies
mix deps.get

# Setup database
mix ecto.setup

# Start Phoenix server
mix phx.server
```

Visit http://localhost:4000 to see the app.

## Quick Start - Desktop Development

```bash
# Terminal 1: Start Phoenix
mix phx.server

# Terminal 2: Start Tauri
cd src-tauri
cargo tauri dev
```

## Production Build

⚠️ **Note:** Production build is currently blocked due to a Tauri bundling issue. See `wip/PROJECT_OVERVIEW.md` for details and solution.

```bash
# Build Elixir release
MIX_ENV=prod mix do compile, assets.deploy, release

# Build Tauri app (after fixing bundling issue)
cd src-tauri
cargo tauri build
```

## Project Documentation

For complete project information, see:
- **`wip/PROJECT_OVERVIEW.md`** - Complete project overview and entry point
- **`wip/PROJECT_STATUS.md`** - Detailed development status
- **`wip/PRD.md`** - Product requirements

## Features

- ✅ Add new todos
- ✅ Mark todos as complete/incomplete
- ✅ Delete todos
- ✅ Persistent local storage (SQLite)
- ✅ Real-time UI updates (LiveView)
- ✅ Beautiful, modern interface

## Tech Stack

- **Backend:** Phoenix LiveView (Elixir)
- **Database:** SQLite
- **Frontend:** Tailwind CSS
- **Desktop:** Tauri (Rust)

## Common Commands

```bash
# Development
mix phx.server              # Start dev server
iex -S mix phx.server      # Start with interactive shell

# Database
mix ecto.migrate           # Run migrations
mix ecto.reset            # Reset database

# Testing
mix test                   # Run tests
```

## Troubleshooting

See `wip/PROJECT_OVERVIEW.md` for detailed troubleshooting guide.

---

*For complete documentation and development details, refer to `wip/PROJECT_OVERVIEW.md`*
# Elixir + Phoenix + Tauri – Desktop App Example

This repository is a small, learning-focused example showing how to combine Elixir/Phoenix (LiveView) with Tauri to ship a native desktop app. It is not a product and not intended for production. Use it to experiment, learn, and understand the moving parts.

• What this demonstrates
- Running a Phoenix server as a Tauri sidecar process
- Using LiveView for the UI and Ecto + SQLite for local data
- Packaging everything into a native macOS app with Tauri
- Simple build scripts to go from Phoenix app → Desktop app
- Agent-assisted workflows that helped iterate faster

## Demo

![Demo](screenshots/demo_tiny_8fps_480w_128c.gif)

- Higher-quality GIF (may not preview on GitHub due to size): [screenshots/demo_v3_12fps_720w_hq.gif](screenshots/demo_v3_12fps_720w_hq.gif)
- [Small video version (MP4)](screenshots/video.mp4)

Description: A short walkthrough that shows starting the Phoenix app, building the Tauri desktop bundle, and interacting with the LiveView UI (adding/reordering/completing items). It highlights how the Phoenix server runs locally as a sidecar and how the desktop app stays fully offline-first.

## Quick start (development)

Prerequisites
- Elixir and Erlang/OTP
- Node.js (for assets)
- Rust toolchain (for Tauri)

Steps
1) Install Elixir deps and set up the project
   mix setup

2) Start Phoenix (browser/dev mode)
   mix phx.server

Visit http://localhost:4000 in your browser.

## Build and run the desktop app (macOS)

The scripts handle building assets, creating a Phoenix release, and packaging the Tauri app.

- Full clean build (first time or after major changes)
  ./scripts/build_and_run.sh

- Fast incremental build (iterating)
  ./scripts/build_and_run.sh --fast

Notes
- macOS only in this example. You can adapt to Windows/Linux with Tauri, but this repo focuses on the learning flow, not cross-platform packaging.
- The scripts will create the app inside src-tauri/target/release/bundle/macos/.

## How it works (high level)

- Phoenix app: Regular Phoenix + LiveView app that serves the UI and uses SQLite via Ecto for local storage.
- Tauri sidecar: Tauri launches the Phoenix release locally, then the webview points to the local server (localhost). The app stays fully local.
- Security/ports: The Phoenix server binds to localhost only. For desktop builds, a fixed port is used.
- Assets: Built with esbuild + Tailwind (v4). Assets are compiled before packaging so the desktop app has everything it needs.

## Why this repo exists

- To learn how Elixir/Phoenix fits into a native desktop workflow
- To experiment with Tauri and LiveView together
- To try agent-assisted workflows as part of the coding process
- To keep things simple and understandable for newcomers

## Repo structure (minimal)

- lib/ … Phoenix app code (contexts, LiveView, components)
- assets/ … JS/CSS assets bundled for Phoenix
- priv/ … static files and Ecto migrations
- src-tauri/ … Tauri config, Rust bootstrap code, icons
- scripts/ … helper scripts to build and run the desktop app

## Not production-ready

This is a teaching resource, not a hardened product. If you want to move toward production, consider:
- Signing/notarizing artifacts (macOS), auto-updates, and cross-platform CI
- Release-time configuration hardening, logs/telemetry, and migration strategies
- Thorough testing and UX polish

## Learn more

- Phoenix: https://www.phoenixframework.org/
- Phoenix LiveView: https://hexdocs.pm/phoenix_live_view/
- Tauri: https://tauri.app/
- Tailwind CSS: https://tailwindcss.com/

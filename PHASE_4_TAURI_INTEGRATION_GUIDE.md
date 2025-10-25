# Phase 4: Tauri Integration Guide

## Overview
This guide provides step-by-step instructions for integrating Tauri with the TodoErr Phoenix application.

## Prerequisites
- Rust and Cargo installed
- Node.js and npm installed (for Tauri CLI)
- Xcode Command Line Tools (for macOS builds)

## Step 1: Install Tauri CLI

```bash
# Install Tauri CLI via cargo
cargo install tauri-cli

# Or via npm (alternative)
npm install -g @tauri-apps/cli
```

## Step 2: Initialize Tauri Project

```bash
# From the project root directory
cargo tauri init

# When prompted, provide the following answers:
# - App name: TodoErr
# - Window title: TodoErr
# - Web assets location: ../priv/static
# - Dev server URL: http://localhost:4000
# - Frontend dev command: mix phx.server
# - Frontend build command: mix assets.deploy
```

## Step 3: Configure tauri.conf.json

Update `src-tauri/tauri.conf.json` with the following configuration:

```json
{
  "build": {
    "beforeDevCommand": "mix phx.server",
    "beforeBuildCommand": "MIX_ENV=prod mix do assets.deploy, release",
    "devPath": "http://localhost:4000",
    "distDir": "../priv/static",
    "withGlobalTauri": false
  },
  "package": {
    "productName": "TodoErr",
    "version": "0.1.0"
  },
  "tauri": {
    "allowlist": {
      "all": false,
      "shell": {
        "all": false,
        "open": false
      }
    },
    "bundle": {
      "active": true,
      "targets": "all",
      "identifier": "com.todoerr.app",
      "icon": [
        "icons/32x32.png",
        "icons/128x128.png",
        "icons/128x128@2x.png",
        "icons/icon.icns",
        "icons/icon.ico"
      ],
      "externalBin": [
        "bin/todo_err"
      ],
      "resources": [],
      "copyright": "",
      "category": "Productivity",
      "shortDescription": "A simple, elegant task manager",
      "longDescription": "TodoErr is a desktop todo application built with Phoenix LiveView and Tauri"
    },
    "security": {
      "csp": "default-src 'self'; connect-src 'self' ws://localhost:* http://localhost:*; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'"
    },
    "windows": [
      {
        "fullscreen": false,
        "resizable": true,
        "title": "TodoErr",
        "width": 800,
        "height": 600,
        "minWidth": 600,
        "minHeight": 400
      }
    ]
  }
}
```

## Step 4: Implement Rust Launcher Logic

Update `src-tauri/src/main.rs`:

```rust
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::process::{Command, Stdio};
use std::io::{BufRead, BufReader};
use std::path::PathBuf;
use tauri::Manager;

fn main() {
    // Get the application support directory for the database
    let app_support_dir = dirs::data_local_dir()
        .expect("Failed to get app support directory")
        .join("TodoErr");
    
    // Ensure the directory exists
    std::fs::create_dir_all(&app_support_dir)
        .expect("Failed to create app support directory");
    
    // Set the database path
    let database_path = app_support_dir.join("todo_err.db");
    
    tauri::Builder::default()
        .setup(|app| {
            // Get the path to the Elixir release binary
            let resource_path = app.path_resolver()
                .resource_dir()
                .expect("Failed to get resource directory");
            
            let elixir_bin = resource_path.join("bin").join("todo_err");
            
            // Start the Elixir/Phoenix server
            let mut child = Command::new(&elixir_bin)
                .arg("start")
                .env("DATABASE_PATH", database_path.to_str().unwrap())
                .env("PHX_SERVER", "true")
                .env("PORT", "0") // Dynamic port
                .stdout(Stdio::piped())
                .stderr(Stdio::piped())
                .spawn()
                .expect("Failed to start Phoenix server");
            
            // Read the stdout to discover the dynamic port
            let stdout = child.stdout.take().expect("Failed to capture stdout");
            let reader = BufReader::new(stdout);
            
            let mut port = None;
            for line in reader.lines() {
                if let Ok(line) = line {
                    println!("Phoenix: {}", line);
                    
                    // Look for the port in the output
                    // Example: "Running TodoErrWeb.Endpoint with Bandit 1.8.0 at 127.0.0.1:4000"
                    if line.contains("Running") && line.contains("127.0.0.1:") {
                        if let Some(port_str) = line.split("127.0.0.1:").nth(1) {
                            if let Some(port_num) = port_str.split_whitespace().next() {
                                port = Some(port_num.to_string());
                                break;
                            }
                        }
                    }
                }
            }
            
            let port = port.expect("Failed to discover Phoenix port");
            let url = format!("http://localhost:{}", port);
            
            // Navigate the webview to the Phoenix server
            let window = app.get_window("main").unwrap();
            window.eval(&format!("window.location.replace('{}')", url))
                .expect("Failed to navigate to Phoenix server");
            
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

Add dependencies to `src-tauri/Cargo.toml`:

```toml
[dependencies]
tauri = { version = "1.5", features = ["shell-open"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
dirs = "5.0"
```

## Step 5: Create Elixir Release Configuration

Create `rel/overlays/bin/todo_err` (if not exists):

```bash
#!/bin/sh
set -e

SELF=$(readlink "$0" || true)
if [ -z "$SELF" ]; then SELF="$0"; fi
RELEASE_ROOT="$(cd "$(dirname "$SELF")/.." && pwd -P)"
export RELEASE_ROOT

# Set default environment variables
export RELEASE_NAME="${RELEASE_NAME:-"todo_err"}"
export RELEASE_VSN="${RELEASE_VSN:-"$(cut -d' ' -f2 "$RELEASE_ROOT/releases/start_erl.data")"}"
export RELEASE_COMMAND="$1"
export RELEASE_PROG="${RELEASE_PROG:-"$(echo "$0" | sed 's/.*\///')"}"

# Execute the release
exec "$RELEASE_ROOT/bin/$RELEASE_NAME" "$@"
```

## Step 6: Update mix.exs for Release

Ensure your `mix.exs` has the release configuration:

```elixir
def project do
  [
    app: :todo_err,
    version: "0.1.0",
    # ... other config ...
    releases: [
      todo_err: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent]
      ]
    ]
  ]
end
```

## Step 7: Build the Application

### Development Mode

```bash
# Terminal 1: Start Phoenix server
mix phx.server

# Terminal 2: Start Tauri in dev mode
cargo tauri dev
```

### Production Build

```bash
# Build the Elixir release
MIX_ENV=prod mix do assets.deploy, release

# Copy the release to Tauri resources
mkdir -p src-tauri/bin
cp -r _build/prod/rel/todo_err src-tauri/bin/

# Build the Tauri application
cargo tauri build
```

The final application will be in `src-tauri/target/release/bundle/`.

## Step 8: Testing

1. **Test F-01: View All Todos**
   - Launch the app
   - Verify todos display correctly
   - Check sorting (incomplete first, then by date)

2. **Test F-02: Add New Todo**
   - Add a todo via button
   - Add a todo via Enter key
   - Verify instant UI update

3. **Test F-03/F-04: Toggle Complete/Incomplete**
   - Click checkbox to mark complete
   - Verify visual feedback (strikethrough, fade)
   - Click again to mark incomplete
   - Verify list re-sorts

4. **Test F-05: Delete Todo**
   - Hover over todo to reveal delete button
   - Click delete
   - Verify todo is removed

5. **Test F-06: Data Persistence**
   - Add several todos
   - Close the application
   - Reopen the application
   - Verify all todos are still present

6. **Verify Database Location**
   - Check that `todo_err.db` exists in:
     - macOS: `~/Library/Application Support/TodoErr/`

7. **Test Automatic Migrations**
   - Delete the database file
   - Launch the app
   - Verify migrations run automatically
   - Verify app works correctly

## Troubleshooting

### Phoenix Server Not Starting
- Check that the Elixir release is built correctly
- Verify the `DATABASE_PATH` environment variable is set
- Check logs in the Tauri console

### Port Discovery Fails
- Ensure Phoenix is configured to output the port to stdout
- Check the regex pattern in the Rust code matches Phoenix output

### Database Locked Errors
- Ensure `pool_size: 5` is set in the Repo config
- Check that only one instance of the app is running

### CSP Errors
- Verify the CSP in `tauri.conf.json` allows localhost connections
- Check browser console for specific CSP violations

## Next Steps

After completing Phase 4, proceed to Phase 5: Build and Testing to create the final production build and perform comprehensive testing.

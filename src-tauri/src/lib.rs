use std::process::{Command, Stdio};
use std::io::{BufRead, BufReader};
use tauri::Manager;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
  tauri::Builder::default()
    .setup(|app| {
      if cfg!(debug_assertions) {
        app.handle().plugin(
          tauri_plugin_log::Builder::default()
            .level(log::LevelFilter::Info)
            .build(),
        )?;
      }

      // Get the application support directory for the database
      let app_support_dir = dirs::data_local_dir()
        .expect("Failed to get app support directory")
        .join("TodoErr");

      // Ensure the directory exists
      std::fs::create_dir_all(&app_support_dir)
        .expect("Failed to create app support directory");

      // Set the database path
      let database_path = app_support_dir.join("todo_err.db");

      // In development mode, just use the dev server
      if cfg!(debug_assertions) {
        log::info!("Running in development mode, using dev server at http://localhost:4000");
        return Ok(());
      }

      // In production, start the Elixir/Phoenix server
      let resource_path = app.path().resource_dir()
        .expect("Failed to get resource directory");

      let elixir_bin = resource_path.join("bin").join("todo_err");

      log::info!("Starting Phoenix server from: {:?}", elixir_bin);

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
          log::info!("Phoenix: {}", line);

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

      log::info!("Navigating to Phoenix server at: {}", url);

      // Navigate the webview to the Phoenix server
      let window = app.get_webview_window("main").unwrap();
      window.eval(&format!("window.location.replace('{}')", url))
        .expect("Failed to navigate to Phoenix server");

      Ok(())
    })
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}

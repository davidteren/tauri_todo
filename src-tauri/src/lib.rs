use tauri::Manager;
use tauri_plugin_shell::ShellExt;
use tauri_plugin_shell::process::CommandEvent;

async fn wait_for_server(url: &str, timeout_secs: u64) -> bool {
  let start = std::time::Instant::now();
  let timeout = std::time::Duration::from_secs(timeout_secs);
  
  while start.elapsed() < timeout {
    // Try to connect to the server
    if let Ok(response) = ureq::get(url)
      .timeout(std::time::Duration::from_secs(2))
      .call() 
    {
      if response.status() == 200 || response.status() == 302 {
        return true;
      }
    }
    
    // Wait before retrying
    tokio::time::sleep(tokio::time::Duration::from_millis(500)).await;
  }
  
  false
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
  tauri::Builder::default()
    .plugin(tauri_plugin_shell::init())
    .plugin(
      tauri_plugin_log::Builder::default()
        .level(log::LevelFilter::Info)
        .build(),
    )
    .setup(|app| {
      let app_handle = app.handle().clone();

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

      log::info!("Preparing to start Phoenix server via sidecar");
      
      let database_path_str = database_path.to_str().unwrap().to_string();
      let fixed_port = "4001"; // Use a fixed port for the bundled app
      
      // Spawn a thread to handle the Phoenix process
      tauri::async_runtime::spawn(async move {
        log::info!("Starting Phoenix server on port {}", fixed_port);
        
        // Use the sidecar API - just use the filename without path
        let sidecar_command = app_handle.shell()
          .sidecar("todo_err_launcher")
          .expect("Failed to create sidecar command");
        
        let (mut rx, _child) = sidecar_command
          .env("DATABASE_PATH", database_path_str)
          .env("PHX_SERVER", "true")
          .env("PORT", fixed_port)
          .spawn()
          .expect("Failed to spawn sidecar");
        
        // Clone app_handle for navigation
        let app_handle_nav = app_handle.clone();
        let port_nav = fixed_port.clone();
        
        // Spawn a task to handle navigation once server is ready
        tauri::async_runtime::spawn(async move {
          let url = format!("http://localhost:{}", port_nav);
          
          // Wait for server to be ready
          if wait_for_server(&url, 30).await {
            log::info!("Phoenix server is ready, navigating to: {}", url);
            
            // Navigate the webview to the Phoenix server
            if let Some(window) = app_handle_nav.get_webview_window("main") {
              // Small delay to ensure window is ready
              tokio::time::sleep(tokio::time::Duration::from_millis(500)).await;
              let _ = window.eval(&format!("window.location.replace('{}')", url));
              log::info!("Navigation command sent to webview");
            } else {
              log::error!("Could not get main window for navigation");
            }
          } else {
            log::error!("Phoenix server failed to become ready within timeout");
            if let Some(window) = app_handle_nav.get_webview_window("main") {
              let _ = window.eval(
                "document.body.innerHTML = '<div style=\"font-family:sans-serif;padding:24px\"><h1>Startup Error</h1><p>Failed to start Phoenix server.</p><p>Check logs at: ~/Library/Logs/com.todoerr.desktop/</p></div>'"
              );
            }
          }
        });
        
        // Continue reading output for logging
        while let Some(event) = rx.recv().await {
          match event {
            CommandEvent::Stdout(line) => {
              log::info!("Phoenix: {}", String::from_utf8_lossy(&line));
            }
            CommandEvent::Stderr(line) => {
              log::info!("Phoenix stderr: {}", String::from_utf8_lossy(&line));
            }
            CommandEvent::Error(err) => {
              log::error!("Phoenix error: {}", err);
            }
            CommandEvent::Terminated(payload) => {
              log::warn!("Phoenix terminated: {:?}", payload);
              break;
            }
            _ => {}
          }
        }
      });

      Ok(())
    })
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}

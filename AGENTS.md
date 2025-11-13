This is a desktop application built with Phoenix LiveView and packaged with Tauri for native macOS/Windows/Linux distribution.

## Project guidelines

- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps

### Phoenix v1.8 guidelines

- **Always** begin your LiveView templates with `<Layouts.app flash={@flash} ...>` which wraps all inner content
- The `MyAppWeb.Layouts` module is aliased in the `my_app_web.ex` file, so you can use it without needing to alias it again
- Anytime you run into errors with no `current_scope` assign:
  - You failed to follow the Authenticated Routes guidelines, or you failed to pass `current_scope` to `<Layouts.app>`
  - **Always** fix the `current_scope` error by moving your routes to the proper `live_session` and ensure you pass `current_scope` as needed
- Phoenix v1.8 moved the `<.flash_group>` component to the `Layouts` module. You are **forbidden** from calling `<.flash_group>` outside of the `layouts.ex` module
- Out of the box, `core_components.ex` imports an `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for for hero icons. **Always** use the `<.icon>` component for icons, **never** use `Heroicons` modules or similar
- **Always** use the imported `<.input>` component for form inputs from `core_components.ex` when available. `<.input>` is imported and using it will will save steps and prevent errors
- If you override the default input classes (`<.input class="myclass px-2 py-1 rounded-lg">)`) class with your own values, no default classes are inherited, so your
custom classes must fully style the input

### JS and CSS guidelines

- **Use Tailwind CSS classes and custom CSS rules** to create polished, responsive, and visually stunning interfaces.
- Tailwindcss v4 **no longer needs a tailwind.config.js** and uses a new import syntax in `app.css`:

      @import "tailwindcss" source(none);
      @source "../css";
      @source "../js";
      @source "../../lib/my_app_web";

- **Always use and maintain this import syntax** in the app.css file for projects generated with `phx.new`
- **Never** use `@apply` when writing raw css
- **Always** manually write your own tailwind-based components instead of using daisyUI for a unique, world-class design
- Out of the box **only the app.js and app.css bundles are supported**
  - You cannot reference an external vendor'd script `src` or link `href` in the layouts
  - You must import the vendor deps into app.js and app.css to use them
  - **Never write inline <script>custom js</script> tags within templates**

### UI/UX & design guidelines

- **Produce world-class UI designs** with a focus on usability, aesthetics, and modern design principles
- Implement **subtle micro-interactions** (e.g., button hover effects, and smooth transitions)
- Ensure **clean typography, spacing, and layout balance** for a refined, premium look
- Focus on **delightful details** like hover effects, loading states, and smooth page transitions


<!-- usage-rules-start -->

<!-- phoenix:elixir-start -->
## Elixir guidelines

- Elixir lists **do not support index based access via the access syntax**

  **Never do this (invalid)**:

      i = 0
      mylist = ["blue", "green"]
      mylist[i]

  Instead, **always** use `Enum.at`, pattern matching, or `List` for index based list access, ie:

      i = 0
      mylist = ["blue", "green"]
      Enum.at(mylist, i)

- Elixir variables are immutable, but can be rebound, so for block expressions like `if`, `case`, `cond`, etc
  you *must* bind the result of the expression to a variable if you want to use it and you CANNOT rebind the result inside the expression, ie:

      # INVALID: we are rebinding inside the `if` and the result never gets assigned
      if connected?(socket) do
        socket = assign(socket, :val, val)
      end

      # VALID: we rebind the result of the `if` to a new variable
      socket =
        if connected?(socket) do
          assign(socket, :val, val)
        end

- **Never** nest multiple modules in the same file as it can cause cyclic dependencies and compilation errors
- **Never** use map access syntax (`changeset[:field]`) on structs as they do not implement the Access behaviour by default. For regular structs, you **must** access the fields directly, such as `my_struct.field` or use higher level APIs that are available on the struct if they exist, `Ecto.Changeset.get_field/2` for changesets
- Elixir's standard library has everything necessary for date and time manipulation. Familiarize yourself with the common `Time`, `Date`, `DateTime`, and `Calendar` interfaces by accessing their documentation as necessary. **Never** install additional dependencies unless asked or for date/time parsing (which you can use the `date_time_parser` package)
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Predicate function names should not start with `is_` and should end in a question mark. Names like `is_thing` should be reserved for guards
- Elixir's builtin OTP primitives like `DynamicSupervisor` and `Registry`, require names in the child spec, such as `{DynamicSupervisor, name: MyApp.MyDynamicSup}`, then you can use `DynamicSupervisor.start_child(MyApp.MyDynamicSup, child_spec)`
- Use `Task.async_stream(collection, callback, options)` for concurrent enumeration with back-pressure. The majority of times you will want to pass `timeout: :infinity` as option

## Mix guidelines

- Read the docs and options before using tasks (by using `mix help task_name`)
- To debug test failures, run tests in a specific file with `mix test test/my_test.exs` or run all previously failed tests with `mix test --failed`
- `mix deps.clean --all` is **almost never needed**. **Avoid** using it unless you have good reason
<!-- phoenix:elixir-end -->

<!-- phoenix:phoenix-start -->
## Phoenix guidelines

- Remember Phoenix router `scope` blocks include an optional alias which is prefixed for all routes within the scope. **Always** be mindful of this when creating routes within a scope to avoid duplicate module prefixes.

- You **never** need to create your own `alias` for route definitions! The `scope` provides the alias, ie:

      scope "/admin", AppWeb.Admin do
        pipe_through :browser

        live "/users", UserLive, :index
      end

  the UserLive route would point to the `AppWeb.Admin.UserLive` module

- `Phoenix.View` no longer is needed or included with Phoenix, don't use it
<!-- phoenix:phoenix-end -->

<!-- phoenix:ecto-start -->
## Ecto Guidelines

- **Always** preload Ecto associations in queries when they'll be accessed in templates, ie a message that needs to reference the `message.user.email`
- Remember `import Ecto.Query` and other supporting modules when you write `seeds.exs`
- `Ecto.Schema` fields always use the `:string` type, even for `:text`, columns, ie: `field :name, :string`
- `Ecto.Changeset.validate_number/2` **DOES NOT SUPPORT the `:allow_nil` option**. By default, Ecto validations only run if a change for the given field exists and the change value is not nil, so such as option is never needed
- You **must** use `Ecto.Changeset.get_field(changeset, :field)` to access changeset fields
- Fields which are set programatically, such as `user_id`, must not be listed in `cast` calls or similar for security purposes. Instead they must be explicitly set when creating the struct
<!-- phoenix:ecto-end -->

<!-- tauri:desktop-start -->
## Tauri Desktop Application Guidelines

This is a Phoenix application packaged as a native desktop app using Tauri. The following guidelines are specific to the desktop deployment:

### Architecture Overview

- The Phoenix server runs as a **sidecar process** managed by Tauri
- The Tauri webview connects to the Phoenix server on localhost
- The entire Phoenix release is bundled within the desktop app
- No external dependencies or servers are required

### Configuration Guidelines

#### Runtime Configuration (`config/runtime.exs`)

- **Database Path**: The database **must** be configured via the `DATABASE_PATH` environment variable
  - This is set by Tauri to point to the app's data directory (e.g., `~/Library/Application Support/AppName/`)
  - **Never** hardcode database paths in production config
  - Example:
    ```elixir
    database_path = System.get_env("DATABASE_PATH") ||
      raise "DATABASE_PATH environment variable is missing"
    ```

- **Port Configuration**: Use a **fixed port** for production builds (e.g., 4001)
  - Development can use port 4000
  - Production should use a different fixed port to avoid conflicts
  - Configure via `PORT` environment variable with a sensible default
  - Example:
    ```elixir
    port = String.to_integer(System.get_env("PORT") || "4001")
    ```

- **Localhost Binding**: **Always** bind to localhost only for security
  - Use `ip: {127, 0, 0, 1}` in the endpoint configuration
  - This prevents external network access to the desktop app
  - Example:
    ```elixir
    config :my_app, MyAppWeb.Endpoint,
      url: [host: "localhost", port: port],
      http: [ip: {127, 0, 0, 1}, port: port]
    ```

- **Server Mode**: Ensure the server starts automatically
  - Set `server: true` in the endpoint config for production
  - Also check for `PHX_SERVER` environment variable

- **Secret Key Base**: Can be generated at runtime for desktop apps
  - Since the app runs locally, session consistency across servers isn't needed
  - Example:
    ```elixir
    secret_key_base = System.get_env("SECRET_KEY_BASE") ||
      :crypto.strong_rand_bytes(64) |> Base.encode64(padding: false) |> binary_part(0, 64)
    ```

#### Database Configuration

- **Use SQLite** for desktop applications (via `ecto_sqlite3`)
  - Embedded database that doesn't require a separate server
  - Keep pool size small to avoid SQLITE_BUSY errors: `pool_size: 5`
  - Database file is stored in the user's app data directory

#### Release Configuration (`mix.exs`)

- Configure releases for Unix systems:
  ```elixir
  releases: [
    my_app: [
      include_executables_for: [:unix],
      applications: [runtime_tools: :permanent]
    ]
  ]
  ```

### Tauri Integration

#### Launcher Script (`scripts/app_launcher`)

- Create a bash script to start the Phoenix release
- Must handle multiple path scenarios (development vs bundled)
- Should set required environment variables
- Must use `exec` to replace the shell process
- Example structure:
  ```bash
  #!/bin/bash
  # Find release directory (handles dev and bundled paths)
  # Export RELEASE_ROOT
  # Unset RELEASE_NODE and RELEASE_DISTRIBUTION
  # Start with: exec "$RELEASE_DIR/bin/app_name" start
  ```

#### Tauri Configuration (`src-tauri/tauri.conf.json`)

- **Build Commands**:
  - `beforeBuildCommand`: Build assets and create Phoenix release
  - Example: `"MIX_ENV=prod mix assets.deploy && MIX_ENV=prod mix release --overwrite"`

- **Resources**: Bundle the entire Phoenix release
  - `resources`: `["../_build/prod/rel/app_name"]`

- **External Binaries**: Include the launcher script as a sidecar
  - `externalBin`: `["../scripts/app_launcher"]`

- **CSP Settings**: Must allow WebSocket connections for LiveView
  - Include `ws://localhost:*` in connect-src
  - Example:
    ```json
    "csp": "default-src 'self'; connect-src 'self' ws://localhost:* http://localhost:*; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'"
    ```

#### Rust Backend (`src-tauri/src/lib.rs`)

- **Server Health Check**: Wait for Phoenix to be ready before navigating
  - Implement a retry loop with timeout
  - Check for HTTP 200 or 302 responses

- **Process Management**: Use Tauri's sidecar API
  - Pass environment variables (DATABASE_PATH, PORT, PHX_SERVER)
  - Handle process output for logging
  - Gracefully handle termination

- **Navigation**: Once Phoenix is ready, navigate the webview
  - Use `window.location.replace()` to load the Phoenix app
  - Handle errors with user-friendly messages

### Development vs Production

- **Development Mode**:
  - Phoenix runs via `mix phx.server`
  - Tauri connects to `http://localhost:4000`
  - Database uses local development path

- **Production Mode**:
  - Phoenix runs from the bundled release
  - Fixed port (e.g., 4001) to avoid conflicts
  - Database in application support directory
  - All assets compiled and digested

### Common Issues and Solutions

1. **Phoenix won't start in bundled app**:
   - Check the launcher script paths
   - Verify DATABASE_PATH is being set
   - Check logs at `~/Library/Logs/com.yourapp.desktop/`

2. **LiveView WebSocket connection fails**:
   - Ensure CSP allows `ws://localhost:*`
   - Verify the port configuration matches

3. **Database permission errors**:
   - Ensure the app data directory is created with proper permissions
   - Use appropriate pool_size for SQLite (5 or less)

4. **Asset loading issues**:
   - Run `mix phx.digest` before building
   - Ensure `cache_static_manifest` is configured for production

5. **Port conflicts**:
   - Use different ports for dev (4000) and prod (4001)
   - Consider port discovery if fixed ports cause issues

### Best Practices

- **Security**: Always bind to localhost only
- **Data Storage**: Use platform-appropriate directories (via `dirs` crate)
- **Logging**: Implement comprehensive logging for debugging bundled apps
- **Error Handling**: Provide user-friendly error messages in the UI
- **Updates**: Consider implementing auto-update functionality via Tauri
- **Testing**: Test both development and production builds thoroughly
<!-- tauri:desktop-end -->

<!-- usage-rules-end -->
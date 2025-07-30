# MyApp

A Phoenix/Elixir web application built with the Ash Framework for declarative resource modeling, featuring authentication, background jobs, and comprehensive Docker development setup.

## Features

- **Ash Framework** for declarative data modeling and business logic
- **Multi-strategy authentication** (password, magic link, tokens) via AshAuthentication
- **Docker-based development** with hot reloading
- **Observability** with SigNoz integration (OpenTelemetry)
- **Admin interface** and development tools

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Elixir 1.17+ (for local development without Docker)

### Quick Start with Docker

```bash
# Clone the repository
git clone <repository-url>
cd my_app

# Copy environment variables
cp .env.example .env

# Create your compose.yaml from the template
cp compose.template.yaml compose.yaml
# Note: compose.yaml is gitignored, allowing you to customize services without affecting version control

# Start all services (database, app, optional observability stack)
docker compose up

# The app will be available at http://localhost:4000
```

### Docker Compose Configuration

The `compose.template.yaml` provides a starting point for your Docker setup. Available service configurations in the `docker/` directory:

- `compose.app.dev.yaml` - Phoenix application with hot reloading
- `compose.db.dev.yaml` - PostgreSQL database for development
- `compose.signoz.yaml` - Observability stack (OpenTelemetry + SigNoz)

You can modify your `compose.yaml` to include only the services you need:

```yaml
include:
  - docker/compose.db.dev.yaml
  - docker/compose.app.dev.yaml
  # - docker/compose.signoz.yaml  # Uncomment if you want observability
```

### Development Commands

```bash
# Run tests
docker compose exec app dev.sh t

# Get an IEx shell
docker compose exec app dev.sh diex

# Run mix commands
docker compose exec app mix <command>
```

### Local Development (without Docker)

```bash
# Install dependencies and setup database
mix setup

# Start Phoenix server
mix phx.server
# or with IEx
iex -S mix phx.server

# Run tests
mix test
# or with watch mode
mix test.interactive
```

## Configuration

### SharedConfig Pattern

This project uses a custom configuration pattern via `config/shared_config.exs` that centralizes all runtime configuration handling. This approach provides:

- **Centralized environment variable processing** with consistent error handling
- **Type-safe conversions** for ports, pool sizes, etc.
- **Environment-specific logic** (test vs production)
- **Clear deployment requirements** with helpful error messages

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `ecto://user:pass@localhost/my_app_dev` |
| `SECRET_KEY_BASE` | Phoenix secret key | Generate with `mix phx.gen.secret` |
| `PHX_HOST` | Application hostname | `localhost` or `myapp.com` |

### Optional Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | HTTP port | `4000` |
| `POOL_SIZE` | Database connection pool size | `10` |
| `PHX_SERVER` | Start Phoenix server | `true` (except in test) |
| `EXTERNAL_ACCESS_HTTPS_PORT` | External HTTPS port | `443` |

### How SharedConfig Works

The SharedConfig module is loaded by config files using:

```elixir
if not Code.ensure_loaded?(MyApp.SharedConfig) do
  Code.require_file(Path.join(__DIR__, "./shared_config.exs"))
end
```

It provides functions that are used in `config/runtime.exs`:
- `SharedConfig.endpoint_config()` - Complete endpoint configuration
- `SharedConfig.database_url()` - Database URL with test partition support
- `SharedConfig.pool_size()` - Dynamic pool sizing for tests
- `SharedConfig.start_server?()` - Server startup control

### MCP (Model Context Protocol) Configuration

This project includes support for Claude Code integration via MCP. To enable it:

1. Copy the MCP template configuration:
   ```bash
   cp .mcp.template.json .mcp.json
   ```

2. Edit `.mcp.json` and replace `__PORT__` with your Phoenix server port (default is 4000):
   ```json
   {
     "mcpServers": {
       "tidewave": {
         "type": "stdio",
         "command": "mcp-proxy",
         "args": [
           "http://127.0.0.1:4000/tidewave/mcp"
         ],
         "env": {}
       }
     }
   }
   ```

3. The `.mcp.json` file is gitignored, allowing each developer to use their preferred port configuration.

This enables Claude Code to interact with your running Elixir application for enhanced development assistance.

## Project Structure

```
├── lib/
│   ├── my_app/          # Core business logic
│   │   ├── accounts/    # Ash resources for authentication
│   │   └── ...
│   └── my_app_web/      # Web layer
│       ├── live/        # LiveView modules
│       ├── components/  # Reusable UI components
│       └── ...
├── config/
│   ├── config.exs       # Compile-time configuration
│   ├── runtime.exs      # Runtime configuration (uses SharedConfig)
│   └── shared_config.exs # Centralized configuration module
├── assets/              # Frontend assets (JS, CSS)
├── priv/               # Static files, migrations
└── rel/                # Release configuration
```

## Development Tools

- **Email Preview**: Visit `/dev/mailbox` in development
- **Admin Interface**: Available at `/admin`
- **Phoenix LiveDashboard**: System metrics and monitoring

## Testing

```bash
# Run all tests
mix test

# Run tests in watch mode
mix test.interactive

# Run specific test file
mix test test/my_app_web/controllers/page_controller_test.exs

# With Docker
docker compose exec app dev.sh t
```

## Deployment

The application is designed for containerized deployment:

1. Build the production image:
   ```bash
   docker build --target prod -t my_app:latest .
   ```

2. Ensure all required environment variables are set
3. Run database migrations:
   ```bash
   docker run --rm my_app:latest /app/bin/migrate
   ```
4. Start the application:
   ```bash
   docker run -p 4000:4000 my_app:latest
   ```

## Observability

The project includes optional SigNoz integration for distributed tracing:

Access SigNoz UI at http://localhost:8080

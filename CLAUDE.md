# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Phoenix/Elixir web application using the Ash Framework (v3.0) for declarative resource modeling and business logic. The project includes authentication, and comprehensive Docker development setup.

## Essential Commands

### Development (with docker)
```bash
# Initial setup
cp .env.example .env

# Start development server - will also run migrations
docker compose up

# Run tests
docker compose exec app dev.sh t

# Get an iex session
docker compose exec app dev.sh diex
```

## Architecture Overview

### Core Technologies
- **Phoenix Framework** (~1.7.21) - Web framework
- **Ash Framework** (~3.0) - Declarative resource framework handling data models, actions, and policies
- **AshAuthentication** - Multi-strategy authentication (password, magic link, tokens)
- **PostgreSQL** - Database via AshPostgres/Ecto

### Project Structure
- `lib/my_app/` - Core business logic and Ash resources
  - `accounts/` - User authentication domain with Ash resources
- `lib/my_app_web/` - Web layer (controllers, LiveViews, components)
- `config/` - Environment-specific configuration
- `rel/` - Release configuration and migration scripts

### Key Architectural Patterns

1. **Ash Resources**: Data models are defined as Ash resources with declarative actions, validations, and policies. Resources live in domain folders (e.g., `lib/my_app/accounts/`).

2. **Authentication**: The app uses AshAuthentication with multiple strategies. Authentication flows are handled through Ash resources with built-in actions for registration, confirmation, password reset, etc.

3. **Development Tools**:
   - Email preview at `/dev/mailbox`
   - Admin interface at `/admin`
   - Phoenix LiveDashboard for monitoring

### Environment Configuration
Configuration is managed through environment variables (see `.env.example`). The app uses runtime configuration in `config/runtime.exs`.

### Testing Approach
- ExUnit with Ecto sandbox for database isolation
- Test helpers in `test/support/`
- Use `mix test.interactive` for watch mode during development

### Configuration Management

The project uses a custom **SharedConfig** module pattern (`config/shared_config.exs`) to centralize runtime configuration handling. This pattern provides:

1. **Centralized environment variable processing**: All runtime configuration is handled in one module with consistent error handling and type conversions.

2. **Key functions**:
   - `start_server?/0` - Controls Phoenix server startup (false in test, based on PHX_SERVER otherwise)
   - `endpoint_config/0` - Complete endpoint configuration including ports, host, and secrets
   - `pool_size/0` - Database connection pool sizing
   - `database_url/0` - Database connection with automatic test partition support

3. **Usage pattern**: Config files load SharedConfig using:
   ```elixir
   if not Code.ensure_loaded?(MyApp.SharedConfig) do
     Code.require_file(Path.join(__DIR__, "./shared_config.exs"))
   end
   ```

4. **Environment variable handling**: The `process_env_var/2` function provides flexible handling:
   - Required variables with helpful error messages
   - Optional variables with defaults
   - Automatic type conversion
   - Empty string treated as unset

5. **Required environment variables**:
   - `DATABASE_URL` - Database connection string
   - `SECRET_KEY_BASE` - Phoenix secret (generate with `mix phx.gen.secret`)
   - `PHX_HOST` - Application hostname
   - Optional: `PORT`, `POOL_SIZE`, `PHX_SERVER`, `EXTERNAL_ACCESS_HTTPS_PORT`

This pattern ensures consistent configuration management across environments and provides clear deployment requirements.

### Docker Setup
Multi-stage Dockerfile with development and production targets. Development uses volume mounts for hot reloading. The compose files provide:
- PostgreSQL database
- Application container with hot reloading
- SigNoz observability stack

## Coding Style Preferences

### Conditional Patterns

When checking for nil/falsy values from `Application.get_env/2` or similar functions, prefer using `if` with variable assignment over `case` statements:

**Preferred pattern:**
```elixir
some_var =
  if other_var = Application.get_env(:my_app, :some_config) do
    other_var
  else
    some_var
  end
```

**Avoid:**
```elixir
some_var =
  case Application.get_env(:my_app, :some_config) do
    nil ->
      some_var

    other_var ->
      other_var
  end
```

This pattern is more idiomatic in Elixir and clearly shows the intent of checking for a truthy value while also binding it to a variable for use in the conditional branch.

### Bash Script Development

When creating or modifying bash scripts in this project, **always** run shellcheck to ensure code quality:

1. **After creating any bash script**: Run `shellcheck <script>` immediately to catch issues
2. **After modifying bash scripts**: Run shellcheck again to ensure no new issues were introduced
3. **Before considering a script complete**: Run `shellcheck -S warning <script>` for stricter checking

Common shellcheck fixes to apply:
- Use `read -r` to prevent backslash mangling
- Quote variables to prevent globbing and word splitting: `"$var"` not `$var`
- Avoid useless `echo` in command substitutions: use `$var` not `$(echo "$var")`
- Use `#!/bin/bash` or `#!/bin/sh` shebang line at the start of scripts

This ensures all bash scripts in the project maintain consistent quality and follow best practices.

<!-- usage-rules-start -->
<!-- usage-rules-header -->
# Usage Rules

**IMPORTANT**: Consult these usage rules early and often when working with the packages listed below.
Before attempting to use any of these packages or to discover if you should use them, review their
usage rules to understand the correct patterns, conventions, and best practices.
<!-- usage-rules-header-end -->

<!-- usage_rules-start -->
## usage_rules usage
_A dev tool for Elixir projects to gather LLM usage rules from dependencies_

## Using Usage Rules

Many packages have usage rules, which you should *thoroughly* consult before taking any
action. These usage rules contain guidelines and rules *directly from the package authors*.
They are your best source of knowledge for making decisions.

## Modules & functions in the current app and dependencies

When looking for docs for modules & functions that are dependencies of the current project,
or for Elixir itself, use `mix usage_rules.docs`

```
# Search a whole module
mix usage_rules.docs Enum

# Search a specific function
mix usage_rules.docs Enum.zip

# Search a specific function & arity
mix usage_rules.docs Enum.zip/1
```


## Searching Documentation

You should also consult the documentation of any tools you are using, early and often. The best
way to accomplish this is to use the `usage_rules.search_docs` mix task. Once you have
found what you are looking for, use the links in the search results to get more detail. For example:

```
# Search docs for all packages in the current application, including Elixir
mix usage_rules.search_docs Enum.zip

# Search docs for specific packages
mix usage_rules.search_docs Req.get -p req

# Search docs for multi-word queries
mix usage_rules.search_docs "making requests" -p req

# Search only in titles (useful for finding specific functions/modules)
mix usage_rules.search_docs "Enum.zip" --query-by title
```


<!-- usage_rules-end -->
<!-- usage_rules:elixir-start -->
## usage_rules:elixir usage
# Elixir Core Usage Rules

## Pattern Matching
- Use pattern matching over conditional logic when possible
- Prefer to match on function heads instead of using `if`/`else` or `case` in function bodies

## Error Handling
- Use `{:ok, result}` and `{:error, reason}` tuples for operations that can fail
- Avoid raising exceptions for control flow
- Use `with` for chaining operations that return `{:ok, _}` or `{:error, _}`

## Common Mistakes to Avoid
- Elixir has no `return` statement, nor early returns. The last expression in a block is always returned.
- Don't use `Enum` functions on large collections when `Stream` is more appropriate
- Avoid nested `case` statements - refactor to a single `case`, `with` or separate functions
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Lists and enumerables cannot be indexed with brackets. Use pattern matching or `Enum` functions
- Prefer `Enum` functions like `Enum.reduce` over recursion
- When recursion is necessary, prefer to use pattern matching in function heads for base case detection
- Using the process dictionary is typically a sign of unidiomatic code
- Only use macros if explicitly requested
- There are many useful standard library functions, prefer to use them where possible

## Function Design
- Use guard clauses: `when is_binary(name) and byte_size(name) > 0`
- Prefer multiple function clauses over complex conditional logic
- Name functions descriptively: `calculate_total_price/2` not `calc/2`
- Predicate function names should not start with `is` and should end in a question mark.
- Names like `is_thing` should be reserved for guards

## Data Structures
- Use structs over maps when the shape is known: `defstruct [:name, :age]`
- Prefer keyword lists for options: `[timeout: 5000, retries: 3]`
- Use maps for dynamic key-value data
- Prefer to prepend to lists `[new | list]` not `list ++ [new]`

## Mix Tasks

- Use `mix help` to list available mix tasks
- Use `mix help task_name` to get docs for an individual task
- Read the docs and options fully before using tasks

## Testing
- Run tests in a specific file with `mix test test/my_test.exs` and a specific test with the line number `mix test path/to/test.exs:123`
- Limit the number of failed tests with `mix test --max-failures n`
- Use `@tag` to tag specific tests, and `mix test --only tag` to run only those tests
- Use `assert_raise` for testing expected exceptions: `assert_raise ArgumentError, fn -> invalid_function() end`
- Use `mix help test` to for full documentation on running tests

## Debugging

- Use `dbg/1` to print values while debugging. This will display the formatted value and other relevant information in the console.

<!-- usage_rules:elixir-end -->
<!-- usage_rules:otp-start -->
## usage_rules:otp usage
# OTP Usage Rules

## GenServer Best Practices
- Keep state simple and serializable
- Handle all expected messages explicitly
- Use `handle_continue/2` for post-init work
- Implement proper cleanup in `terminate/2` when necessary

## Process Communication
- Use `GenServer.call/3` for synchronous requests expecting replies
- Use `GenServer.cast/2` for fire-and-forget messages.
- When in doubt, us `call` over `cast`, to ensure back-pressure
- Set appropriate timeouts for `call/3` operations

## Fault Tolerance
- Set up processes such that they can handle crashing and being restarted by supervisors
- Use `:max_restarts` and `:max_seconds` to prevent restart loops

## Task and Async
- Use `Task.Supervisor` for better fault tolerance
- Handle task failures with `Task.yield/2` or `Task.shutdown/2`
- Set appropriate task timeouts
- Use `Task.async_stream/3` for concurrent enumeration with back-pressure

<!-- usage_rules:otp-end -->
<!-- ash-start -->
## ash usage
_A declarative, extensible framework for building Elixir applications._

[ash usage rules](deps/ash/usage-rules.md)
<!-- ash-end -->
<!-- ash_postgres-start -->
## ash_postgres usage
_The PostgreSQL data layer for Ash Framework_

[ash_postgres usage rules](deps/ash_postgres/usage-rules.md)
<!-- ash_postgres-end -->
<!-- ash_phoenix-start -->
## ash_phoenix usage
_Utilities for integrating Ash and Phoenix_

[ash_phoenix usage rules](deps/ash_phoenix/usage-rules.md)
<!-- ash_phoenix-end -->
<!-- ash_ai-start -->
## ash_ai usage
_Integrated LLM features for your Ash application._

[ash_ai usage rules](deps/ash_ai/usage-rules.md)
<!-- ash_ai-end -->
<!-- igniter-start -->
## igniter usage
_A code generation and project patching framework_

[igniter usage rules](deps/igniter/usage-rules.md)
<!-- igniter-end -->
<!-- ash_authentication-start -->
## ash_authentication usage
_Authentication extension for the Ash Framework._

[ash_authentication usage rules](deps/ash_authentication/usage-rules.md)
<!-- ash_authentication-end -->
<!-- usage-rules-end -->

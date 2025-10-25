# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Elixir library that provides a client for the MusicBrainz API (v0.1.0). It uses `req` as the HTTP client and returns responses as native Elixir maps parsed from JSON. The client is designed for read-only operations (GET requests only) and does not include validation or data structures, as those will be handled by a separate Ecto-based library.

## Development Commands

### Testing
```bash
# Run all tests
mix test

# Run a single test file
mix test test/son_ex_musicbrainz_client_test.exs

# Run a specific test by line number
mix test test/son_ex_musicbrainz_client_test.exs:5

# Run tests with coverage
mix test --cover
```

### Code Quality
```bash
# Format code according to project standards
mix format

# Check if code is formatted
mix format --check-formatted

# Compile the project
mix compile

# Clean build artifacts
mix clean
```

### Dependencies
```bash
# Fetch dependencies
mix deps.get

# Update dependencies
mix deps.update --all

# Show dependency tree
mix deps.tree
```

### Interactive Development
```bash
# Start IEx with the project loaded
iex -S mix

# Recompile within IEx
recompile()
```

## Project Structure

- `lib/son_ex_musicbrainz_client.ex` - Main module entry point
- `test/` - Test files following ExUnit conventions
- `mix.exs` - Project configuration, dependencies, and metadata
- `.formatter.exs` - Code formatting configuration

## Architecture Notes

### API Design

The client uses an idiomatic Elixir approach with pattern matching:
- Three main operations: `lookup/3`, `browse/3`, `search/3`
- Entity types (`:artist`, `:release`, etc.) are passed as atoms, not modules
- Multiple function heads with pattern matching instead of conditional logic
- All functions return `{:ok, map()}` or `{:error, term()}` tuples

### MusicBrainz API Specifics

- Base URL: `https://musicbrainz.org/ws/2`
- Supported entities: area, artist, event, genre, instrument, label, place, recording, release, release_group, series, work, url
- Rate limit: 1 request/second (not enforced by this client - handle at application level)
- Required headers: meaningful User-Agent, Accept: application/json
- Uses Elixir 1.18's built-in JSON encoding/decoding (no Jason dependency)

### HTTP Client Configuration

The client is configurable via Mix config:

```elixir
config :son_ex_musicbrainz_client,
  user_agent: "MyApp/1.0.0 (contact@example.com)",
  http_options: [
    retry: :transient,
    max_retries: 3,
    receive_timeout: 15_000
  ]
```

The `:http_options` are passed directly to Req and can include any valid Req options.

### Testing Approach

- Tests use Req's plug option to mock HTTP responses
- No tests hit the real MusicBrainz API (avoids rate limiting issues)
- **Only test happy path** - error handling is delegated to Req and the parent application
- Tests focus on what we control: URL construction, parameter normalization, and request building
- Do not test HTTP error responses (404, 500, etc.) - that's testing Req, not our code
- Run tests with `mix test --cover` to check coverage

### Important Implementation Details

- Function default arguments are declared once on a function head, not on each pattern-matched clause
- Parameter normalization converts `:release_group` → `:"release-group"` for URL compatibility
- The `inc` parameter accepts both lists (`["a", "b"]`) and strings (`"a+b"`)
- Browse relationships are explicitly defined per entity type using pattern matching

### Dependencies

- `req ~> 0.5.0` - HTTP client (production)
- `plug ~> 1.16` - For test mocks only (test environment)

## Code Formatting

The project uses the standard Elixir formatter. Code formatting applies to:
- Mix files: `{mix,.formatter}.exs`
- Application code: `{config,lib,test}/**/*.{ex,exs}`

Always run `mix format` before committing changes.

## Common Development Patterns

When adding new functionality:
1. Add new function heads with pattern matching for each entity/relationship combination
2. Ensure proper @spec type annotations
3. Include @doc with examples (non-executable, for documentation only)
4. Add corresponding tests in the test file using mock plugs
5. Update parameter normalization in `normalize_param/1` if needed

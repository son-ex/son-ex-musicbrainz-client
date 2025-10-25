# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Elixir library that provides a client for the MusicBrainz API (v0.2.0). It uses `req` as the HTTP client and returns responses as native Elixir maps parsed from JSON. The client features smart dispatch capabilities, allowing functions to intelligently extract identifiers from entity maps. It is designed for read-only operations (GET requests only) and does not include validation or data structures (plain maps only), as those will be handled by a separate Ecto-based library.

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

```
lib/son_ex/
├── music_brainz.ex              # Main interface module (defdelegate to entity modules)
└── music_brainz/
    ├── client.ex                 # Low-level HTTP client
    ├── extractor.ex              # Pattern matching for MBID extraction
    ├── artist.ex                 # Artist-specific functions with smart dispatch
    ├── release.ex                # Release-specific functions
    ├── release_group.ex          # ReleaseGroup-specific functions
    └── recording.ex              # Recording-specific functions

test/son_ex_musicbrainz_test.exs # Test suite
config/config.exs                 # Configuration example
docs/api_response_examples.md    # Real API response examples for reference
mix.exs                           # Project configuration
.formatter.exs                    # Code formatting configuration
```

## Architecture Notes

### API Design

The client uses pattern matching and smart dispatch:

#### Module Structure
- **Main Interface** (`SonEx.MusicBrainz`): Uses `defdelegate` to provide a unified API
- **Entity Modules** (`SonEx.MusicBrainz.Artist`, etc.): Implement smart dispatch per entity type
- **Client Module** (`SonEx.MusicBrainz.Client`): Low-level HTTP operations
- **Extractor Module** (`SonEx.MusicBrainz.Extractor`): Pattern matches on maps to extract MBIDs

#### Smart Dispatch
Functions accept multiple input types and intelligently extract identifiers:
- String MBID: `SonEx.MusicBrainz.lookup_artist("mbid-123")`
- Entity Map: `SonEx.MusicBrainz.lookup_artist(%{"id" => "mbid-123"})`
- Related Entity: `SonEx.MusicBrainz.lookup_artist(release_map)` (extracts artist from release)

#### Core Operations
- Three main operations: `lookup/3`, `browse/3`, `search/3`
- Available via main module (`SonEx.MusicBrainz.lookup_artist/2`) or entity modules (`SonEx.MusicBrainz.Artist.lookup/2`)
- All functions return `{:ok, map()}` or `{:error, term()}` tuples
- No structs/defstructs - uses plain maps only (validation handled by separate Ecto library)

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

### Pattern Matching & MBID Extraction

The `SonEx.MusicBrainz.Extractor` module uses pattern matching to identify entity types and extract MBIDs:

- **Entity Detection**: Discriminates entity types by unique field combinations
  - Artist: `%{"type" => type, "life-span" => _}` where `type in ["Group", "Person"]`
  - Release: `%{"status" => _, "packaging" => _}`
  - Recording: `%{"length" => length, "video" => _}` where `is_number(length)`
  - Release Group: `%{"primary-type" => _, "secondary-types" => _}`
  - Label: `%{"label-code" => _}`

- **MBID Extraction**: Extracts identifiers from various map structures
  - Direct: `%{"id" => id}` → id
  - Artist from credit: `%{"artist-credit" => [%{"artist" => %{"id" => id}}]}` → id
  - Area references: `%{"area" => %{"id" => id}}`, `%{"begin-area" => %{"id" => id}}`, etc.

See `docs/api_response_examples.md` for real API responses used to build these patterns.

### Testing Approach

- Tests use Req's plug option to mock HTTP responses
- No tests hit the real MusicBrainz API (avoids rate limiting issues)
- **Only test happy path** - error handling is delegated to Req and the parent application
- Tests focus on what we control: URL construction, parameter normalization, and request building
- Do not test HTTP error responses (404, 500, etc.) - that's testing Req, not our code
- Run tests with `mix test --cover` to check coverage

### Important Implementation Details

- **No defstructs**: Uses plain maps only - no validation or schemas (deferred to separate Ecto library)
- **Pattern matching on maps**: Functions dispatch based on map structure, not types
- **Function default arguments**: Declared once on function head, not on each pattern-matched clause
- **Parameter normalization**: `:release_group` → `:"release-group"` for URL compatibility
- **`inc` parameter**: Accepts both lists (`["a", "b"]`) and strings (`"a+b"`)
- **Browse relationships**: Explicitly defined per entity type using pattern matching
- **Smart dispatch**: Multiple function heads match on map patterns (e.g., artist map vs release map)

### Dependencies

- `req ~> 0.5.0` - HTTP client (production)
- `plug ~> 1.16` - For test mocks only (test environment)

## Code Formatting

The project uses the standard Elixir formatter. Code formatting applies to:
- Mix files: `{mix,.formatter}.exs`
- Application code: `{config,lib,test}/**/*.{ex,exs}`

Always run `mix format` before committing changes.

## Common Development Patterns

### Adding New Entity Types

1. **Create entity module** in `lib/son_ex/music_brainz/entity_name.ex`
2. **Implement smart dispatch**: Add function heads matching different map patterns
3. **Update Extractor**: Add pattern matching clauses in `SonEx.MusicBrainz.Extractor` for:
   - Entity type detection (`detect_entity_type/1`)
   - MBID extraction (`extract_mbid/2`)
4. **Add to main module**: Add `defdelegate` in `SonEx.MusicBrainz`
5. **Add tests**: Mock-based tests with Req plug
6. **Document API responses**: Add real response examples to `docs/api_response_examples.md`

### Adding Smart Dispatch Patterns

When adding new relationships or extraction patterns:
1. Fetch real API response (respecting rate limits: 1 req/second)
2. Document response in `docs/api_response_examples.md`
3. Add pattern matching clause in relevant entity module
4. Add extraction pattern in `Extractor.extract_mbid/2` if needed
5. Add test case with mock response

### Testing Guidelines

- **Only test happy path** - error handling delegated to Req
- **Use mock plugs** - don't hit real API
- **Test URL construction** - ensure correct endpoints
- **Test parameter normalization** - verify query string formatting
- **Test smart dispatch** - verify correct MBID extraction from maps

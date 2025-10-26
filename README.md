# SonEx MusicBrainz Client

A lightweight, Elixir client for the [MusicBrainz API v2](https://musicbrainz.org/doc/MusicBrainz_API).

[![Hex.pm](https://img.shields.io/hexpm/v/son_ex_musicbrainz_client.svg)](https://hex.pm/packages/son_ex_musicbrainz_client)
[![Documentation](https://img.shields.io/badge/hex-docs-purple.svg)](https://hexdocs.pm/son_ex_musicbrainz_client)

## Installation

Add `son_ex_musicbrainz_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:son_ex_musicbrainz_client, "~> 0.2.1"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Configuration

### User Agent (Required for Production)

MusicBrainz requires a user agent identifying your application. Configure it in `config/config.exs`:

```elixir
config :son_ex_musicbrainz_client,
  user_agent: "MyApp/1.0 (contact@example.com)"
```

### HTTP Options (Optional)

You can configure additional HTTP options for the Req client:

```elixir
config :son_ex_musicbrainz_client,
  http_options: [
    # Add custom options here
    receive_timeout: 30_000
  ]
```

## Usage

### Lookup by MBID

Retrieve a specific entity using its MusicBrainz Identifier (MBID):

```elixir
# Look up an artist
{:ok, artist} = SonEx.MusicBrainz.lookup(:artist, "5b11f4ce-a62d-471e-81fc-a69a8278c7da")
artist["name"]
# => "Nirvana"

# Look up a release with additional data
{:ok, release} = SonEx.MusicBrainz.lookup(
  :release,
  "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  inc: ["artists", "labels", "recordings"]
)

# Look up a recording
{:ok, recording} = SonEx.MusicBrainz.lookup(:recording, "recording-mbid-here")
recording["title"]
# => "Smells Like Teen Spirit"
```

**Supported entity types for lookup:**
`:area`, `:artist`, `:event`, `:genre`, `:instrument`, `:label`, `:place`, `:recording`, `:release`, `:release_group`, `:series`, `:work`, `:url`

**Common options:**
- `:inc` - List of subqueries (e.g., `["artists", "releases", "recordings"]`)

### Browse Relationships

Discover entities related to another entity:

```elixir
# Browse all releases by an artist
{:ok, result} = SonEx.MusicBrainz.browse(
  :release,
  [artist: "5b11f4ce-a62d-471e-81fc-a69a8278c7da"],
  limit: 50
)
result["releases"]
# => [%{"id" => "...", "title" => "Nevermind"}, ...]

# Browse recordings on a release
{:ok, result} = SonEx.MusicBrainz.browse(
  :recording,
  [release: "release-mbid"],
  inc: ["artist-credits"]
)

# Browse artists from an area
{:ok, result} = SonEx.MusicBrainz.browse(
  :artist,
  [area: "area-mbid"],
  offset: 100,
  limit: 25
)

# Browse release groups by artist
{:ok, result} = SonEx.MusicBrainz.browse(
  :release_group,
  [artist: "artist-mbid"],
  type: "album"
)
```

**Common browse relationships by entity:**

- **Artist**: `area`, `collection`, `recording`, `release`, `release_group`, `work`
- **Release**: `artist`, `collection`, `label`, `track`, `track_artist`, `recording`, `release_group`
- **Recording**: `artist`, `collection`, `release`, `work`
- **Release Group**: `artist`, `collection`, `release`
- **Event**: `area`, `artist`, `collection`, `place`
- **Label**: `area`, `collection`, `release`
- **Place**: `area`, `collection`
- **Work**: `artist`, `collection`
- **Area**: `collection`
- **Instrument**: `collection`
- **Series**: `collection`
- **URL**: `resource`

**Common options:**
- `:limit` - Number of results (default: 25, max: 100)
- `:offset` - Pagination offset
- `:inc` - Additional data to include
- `:type` - Type filter (for releases and release groups)
- `:status` - Status filter (for releases)

### Search

Full-text search using Lucene query syntax:

```elixir
# Search for artists
{:ok, result} = SonEx.MusicBrainz.search(:artist, "artist:nirvana AND country:US")
result["artists"]
# => [%{"id" => "...", "name" => "Nirvana", "score" => 100}, ...]
result["count"]
# => 15

# Search for releases with pagination
{:ok, result} = SonEx.MusicBrainz.search(
  :release,
  "release:nevermind AND artist:nirvana",
  limit: 10,
  offset: 0
)

# Search for recordings
{:ok, result} = SonEx.MusicBrainz.search(
  :recording,
  "recording:\"Smells Like Teen Spirit\" AND artist:nirvana"
)

# Complex search with multiple criteria
{:ok, result} = SonEx.MusicBrainz.search(
  :artist,
  "artist:beatles AND country:GB AND type:group",
  limit: 25
)
```

**Supported entity types for search:**
`:area`, `:artist`, `:event`, `:genre`, `:instrument`, `:label`, `:place`, `:recording`, `:release`, `:release_group`, `:series`, `:work`, `:url`

**Common search fields by entity:**

- **Artist**: `artist`, `alias`, `type`, `gender`, `area`, `tag`, `arid` (MBID)
- **Release**: `release`, `artist`, `date`, `country`, `barcode`, `status`, `reid` (MBID)
- **Recording**: `recording`, `artist`, `release`, `date`, `isrc`, `rid` (MBID)
- **Release Group**: `releasegroup`, `artist`, `type`, `tag`, `rgid` (MBID)
- **Label**: `label`, `area`, `type`, `code`, `laid` (MBID)
- **Work**: `work`, `artist`, `type`, `tag`, `wid` (MBID)

See the [MusicBrainz Search Documentation](https://musicbrainz.org/doc/MusicBrainz_API/Search) for complete field references.

**Common options:**
- `:limit` - Number of results (default: 25, max: 100)
- `:offset` - Pagination offset

### Response Format

All functions return native Elixir maps parsed from JSON:

```elixir
# Successful response
{:ok, data} = SonEx.MusicBrainz.lookup(:artist, "mbid-here")
# data is a map: %{"id" => "...", "name" => "...", ...}

# Error responses are passed through from Req
{:error, reason} = SonEx.MusicBrainz.lookup(:artist, "invalid-mbid")
# Handle errors as needed
```

## Examples

### Finding an Artist's Discography

```elixir
artist_mbid = "5b11f4ce-a62d-471e-81fc-a69a8278c7da" # Nirvana

# Get artist info
{:ok, artist} = SonEx.MusicBrainz.lookup(:artist, artist_mbid)
IO.puts("Artist: #{artist["name"]}")

# Browse all official albums
{:ok, result} = SonEx.MusicBrainz.browse(
  :release_group,
  [artist: artist_mbid],
  type: "album",
  limit: 100
)

Enum.each(result["release-groups"], fn rg ->
  IO.puts("  #{rg["title"]} (#{rg["first-release-date"]})")
end)
```

### Searching for Recordings by ISRC

```elixir
isrc = "USCA29900012"

{:ok, result} = SonEx.MusicBrainz.search(:recording, "isrc:#{isrc}")

case result["recordings"] do
  [recording | _] ->
    IO.puts("Found: #{recording["title"]}")
    IO.puts("Artist: #{get_in(recording, ["artist-credit", 0, "name"])}")
  [] ->
    IO.puts("No recording found for ISRC: #{isrc}")
end
```

### Getting Label Catalog

```elixir
label_mbid = "label-mbid-here"

# Get all releases from a label
{:ok, label_info} = SonEx.MusicBrainz.lookup(:label, label_mbid)

{:ok, releases} = SonEx.MusicBrainz.browse(
  :release,
  [label: label_mbid],
  limit: 100,
  inc: ["artists", "release-groups"]
)

IO.puts("Label: #{label_info["name"]}")
IO.puts("Total releases: #{releases["release-count"]}")
```

### Working with Cover Art

The library includes support for the [Cover Art Archive API](https://coverartarchive.org/), which provides cover art images for releases and release groups:

```elixir
# Get cover art metadata for a release
{:ok, metadata} = SonEx.MusicBrainz.fetch_release_cover_art("release-mbid")

# Access image information
Enum.each(metadata["images"], fn image ->
  IO.puts("Image URL: #{image["image"]}")
  IO.puts("Front cover: #{image["front"]}")
  IO.puts("Types: #{inspect(image["types"])}")
  IO.puts("Thumbnails: #{inspect(Map.keys(image["thumbnails"]))}")
end)

# Get the front cover image URL
{:ok, url} = SonEx.MusicBrainz.fetch_front("release-mbid")
# => {:ok, "https://archive.org/download/mbid-770b9b80-.../image.jpg"}

# Get a thumbnail (250px, 500px, or 1200px)
{:ok, url} = SonEx.MusicBrainz.fetch_front("release-mbid", size: 500)
# => {:ok, "https://archive.org/download/mbid-770b9b80-.../image-500.jpg"}

# Get back cover
{:ok, url} = SonEx.MusicBrainz.fetch_back("release-mbid")
# => {:ok, "https://archive.org/download/mbid-770b9b80-.../back.jpg"}

# Get cover art for a release group
{:ok, metadata} = SonEx.MusicBrainz.fetch_release_group_cover_art("release-group-mbid")

# Get front cover from a release group
{:ok, url} = SonEx.MusicBrainz.fetch_front(
  "release-group-mbid",
  entity_type: :release_group
)

# Get specific image by ID
{:ok, url} = SonEx.MusicBrainz.fetch_cover_art_image(
  "release-mbid",
  "1234567890",
  size: 250
)
```

**Available cover art functions:**
- `fetch_release_cover_art/2` - Get all cover art metadata for a release (returns `{:ok, map()}`)
- `fetch_release_group_cover_art/2` - Get cover art metadata for a release group (returns `{:ok, map()}`)
- `fetch_front/2` - Get front cover image URL (returns `{:ok, url}`)
- `fetch_back/2` - Get back cover image URL (returns `{:ok, url}`)
- `fetch_cover_art_image/3` - Get specific image URL by ID (returns `{:ok, url}`)

**Thumbnail sizes:** `250`, `500`, `1200` (pixels)

**Response Format:**
- **Metadata requests**: Return `{:ok, map()}` with JSON data containing image URLs and metadata
- **Image requests**: Return `{:ok, url}` with the direct URL to the image as a string

## Rate Limiting

MusicBrainz enforces rate limits (approximately 1 request per second for anonymous users). This client does **not** implement rate limiting internally.

For production applications, you should implement rate limiting at a higher level (e.g., using a GenServer-based queue, a library like `ex_rated`, or a supervision tree managing backpressure).

## Testing

The library includes comprehensive tests using mock-based testing (no real API calls):

```bash
# Run tests
mix test

# Run tests with coverage
mix test --cover
```

## API Documentation

For detailed API documentation, see:

- [MusicBrainz API Documentation](https://musicbrainz.org/doc/MusicBrainz_API)
- [MusicBrainz Search Syntax](https://musicbrainz.org/doc/MusicBrainz_API/Search)
- [Generated HexDocs](https://hexdocs.pm/son_ex_musicbrainz_client)

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure:
- All tests pass (`mix test`)
- Code is formatted (`mix format`)
- Coverage remains high (`mix test --cover`)

## Changelog

### v0.2.1 (2025-10-25)

**Added:**
- Cover Art Archive API support with new `SonEx.MusicBrainz.CoverArt` module
  - `fetch_release_cover_art/2` - Fetch cover art metadata for releases
  - `fetch_release_group_cover_art/2` - Fetch cover art metadata for release groups
  - `fetch_front/2` - Fetch front cover images with optional thumbnail sizes
  - `fetch_back/2` - Fetch back cover images with optional thumbnail sizes
  - `fetch_image_by_id/3` - Fetch specific cover art images by ID
- Smart dispatch support for cover art functions (works with release/release-group maps)
- Comprehensive test coverage for cover art functionality (20 new tests)
- Documentation and examples for Cover Art Archive API

### v0.2.0 (2025-10-24)

**Added:**
- Smart dispatch capabilities across all entity modules
- Enhanced MBID extraction from entity maps
- Entity-specific modules (Artist, Release, ReleaseGroup, Recording, etc.)
- Comprehensive test coverage with mock-based testing
- Pattern matching for entity type detection

**Changed:**
- Improved API design with `defdelegate` pattern
- Better error handling and response normalization

### v0.1.0 (Initial Release)

**Added:**
- Basic MusicBrainz API v2 client
- Support for lookup, browse, and search operations
- All core MusicBrainz entity types
- Configurable HTTP options
- User agent configuration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


## Resources

- [MusicBrainz API](https://musicbrainz.org/doc/MusicBrainz_API)
- [MusicBrainz Database](https://musicbrainz.org/doc/MusicBrainz_Database)
- [Lucene Query Syntax](https://lucene.apache.org/core/2_9_4/queryparsersyntax.html)

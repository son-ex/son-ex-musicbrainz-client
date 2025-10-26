# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2025-10-25

### Added
- **Cover Art Archive API**: New `SonEx.MusicBrainz.CoverArt` module with full support for the Cover Art Archive API
  - `fetch_release_cover_art/2` - Fetch cover art metadata for releases (returns JSON with image URLs and details)
  - `fetch_release_group_cover_art/2` - Fetch cover art metadata for release groups
  - `fetch_front/2` - Fetch front cover images with optional thumbnail sizes
  - `fetch_back/2` - Fetch back cover images with optional thumbnail sizes
  - `fetch_image_by_id/3` - Fetch specific cover art images by ID
- **Thumbnail Support**: All image functions support optional `:size` parameter (250px, 500px, or 1200px)
- **Smart Dispatch**: Cover art functions work with release/release-group maps, not just MBIDs
- **Entity Type Option**: `fetch_front/2` and `fetch_back/2` support `:entity_type` option (`:release` or `:release_group`)
- **Comprehensive Tests**: 20 new tests covering all cover art functionality
- **Documentation**: Updated README with cover art examples and changelog section

### Changed
- Updated main `SonEx.MusicBrainz` module with cover art function delegates
- Enhanced CLAUDE.md with Cover Art Archive API documentation

## [0.2.0] - 2025-10-24

### Changed
- Complete architecture overhaul with modular design pattern
- Migrated from monolithic client to entity-specific modules

### Added
- **Smart Dispatch**: Functions now intelligently accept both string MBIDs and entity maps
- **Pattern Matching**: Automatic entity type detection based on map structure
- **Extractor Module**: `SonEx.MusicBrainz.Extractor` for intelligent MBID extraction from nested structures
- **Entity Modules**: Dedicated modules for all 13 entity types:
  - `SonEx.MusicBrainz.Artist`
  - `SonEx.MusicBrainz.Release`
  - `SonEx.MusicBrainz.ReleaseGroup`
  - `SonEx.MusicBrainz.Recording`
  - `SonEx.MusicBrainz.Event`
  - `SonEx.MusicBrainz.Label`
  - `SonEx.MusicBrainz.Place`
  - `SonEx.MusicBrainz.Work`
  - `SonEx.MusicBrainz.Area`
  - `SonEx.MusicBrainz.Genre`
  - `SonEx.MusicBrainz.Instrument`
  - `SonEx.MusicBrainz.Series`
  - `SonEx.MusicBrainz.URL`
- **Client Module**: Low-level HTTP client abstraction in `SonEx.MusicBrainz.Client`
- **Unified Interface**: Main `SonEx.MusicBrainz` module with defdelegate for clean API
- **Enhanced Documentation**:
  - `docs/api_response_examples.md` - Real API response structures
  - Updated `CLAUDE.md` with new architecture details

### Improved
- Test coverage increased from 39.55% to 92.75%
- Test suite expanded from 42 to 182 tests
- All tests passing with comprehensive coverage:
  - Entity module tests (33 tests)
  - Extractor pattern matching tests (62 tests)
  - Smart dispatch integration tests (87 tests)
  - Complex extraction patterns (place from events, work from recordings, series detection)
  - Search query edge cases and fallback patterns

### Features
- **Map-Based Queries**: All search functions accept maps with field names (e.g., `%{"name" => "Nirvana"}`)
- **Intelligent Extraction**: Automatically extracts MBIDs from:
  - `artist-credit` arrays in releases/recordings
  - `release-group` in releases
  - `area`, `begin-area` in various entities
  - `release-events` in releases
  - Relations in events (place extraction)
  - Relations in recordings (work extraction)
- **Entity Type Detection**: Pattern matching on unique field combinations:
  - Artists: `type` in ["Group", "Person"] + `life-span`
  - Releases: `status` + `packaging` or `status-id` + `release-events`
  - Recordings: `length` (number) + `video` (boolean)
  - Release Groups: `primary-type` + `secondary-types`
  - Labels: `label-code`
  - Areas: `iso-3166-1-codes`
  - Events: `cancelled` (boolean)
  - Places: `coordinates` with `latitude` + `longitude`
  - Works: `iswcs` or `languages` + `title`
  - Series: Specific type values ("Release group series", etc.)


**Smart Dispatch:**
```elixir
# Before: Manual ID extraction
{:ok, release} = MB.lookup(:release, "release-mbid")
artist_id = release["artist-credit"] |> List.first() |> get_in(["artist", "id"])
{:ok, artist} = MB.lookup(:artist, artist_id)

# After: Automatic extraction
{:ok, release} = MB.lookup_release("release-mbid")
{:ok, artist} = MB.lookup_artist(release)
```

**Module-Based API:**
```elixir
# You can now use entity-specific modules directly
SonEx.MusicBrainz.Artist.lookup("mbid")
SonEx.MusicBrainz.Release.browse([artist: "mbid"])
SonEx.MusicBrainz.Recording.search("title:Bohemian Rhapsody")

# Or use the unified interface
SonEx.MusicBrainz.lookup_artist("mbid")
SonEx.MusicBrainz.browse_releases([artist: "mbid"])
SonEx.MusicBrainz.search_recordings("title:Bohemian Rhapsody")
```

## [0.1.0] - 2025-10-25

### Added
- Initial release of SonEx MusicBrainz Client
- Support for all 13 MusicBrainz entity types (area, artist, event, genre, instrument, label, place, recording, release, release_group, series, work, url)
- Three main operations: `lookup/3`, `browse/3`, and `search/3`
- Configurable user agent and HTTP options via Mix config
- Test suite with mock-based testing
- Full documentation with ExDoc support

### Features
- **Lookup**: Retrieve entities by MBID (MusicBrainz Identifier)
- **Browse**: Discover related entities through relationships
- **Search**: Full-text search using Lucene query syntax
- **Parameter normalization**: Automatic conversion of Elixir-style parameters to API format
- **Type specs**: Full type specifications for all public functions
- **Mock-based testing**: No real API calls required for testing

[0.2.1]: https://github.com/son-ex/son-ex-musicbrainz-client/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/son-ex/son-ex-musicbrainz-client/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/son-ex/son-ex-musicbrainz-client/releases/tag/v0.1.0

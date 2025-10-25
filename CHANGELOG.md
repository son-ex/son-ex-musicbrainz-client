# Changelog

## [0.1.0] - 2025-10-25

### Added
- Initial release of SonEx MusicBrainz Client
- Support for all 13 MusicBrainz entity types (area, artist, event, genre, instrument, label, place, recording, release, release_group, series, work, url)
- Three main operations: `lookup/3`, `browse/3`, and `search/3`
- Configurable user agent and HTTP options via Mix config
- Comprehensive test suite with 98.72% code coverage
- Full documentation with ExDoc support

### Features
- **Lookup**: Retrieve entities by MBID (MusicBrainz Identifier)
- **Browse**: Discover related entities through relationships
- **Search**: Full-text search using Lucene query syntax
- **Parameter normalization**: Automatic conversion of Elixir-style parameters to API format
- **Type specs**: Full type specifications for all public functions
- **Mock-based testing**: No real API calls required for testing

[0.1.0]: https://github.com/son-ex/son-ex-musicbrainz-client/releases/tag/v0.1.0

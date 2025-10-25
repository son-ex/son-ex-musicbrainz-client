defmodule SonEx.MusicBrainz do
  @moduledoc """
  Main interface for the MusicBrainz API client.

  This module provides a unified API with smart dispatch capabilities,
  supporting both traditional MBID-based queries and intelligent extraction
  of identifiers from entity maps.

  ## Architecture

  - `SonEx.MusicBrainz.Client` - Low-level HTTP client
  - `SonEx.MusicBrainz.Extractor` - Pattern matching for MBID extraction
  - `SonEx.MusicBrainz.Artist`, `.Release`, etc. - Entity-specific modules
  - `SonEx.MusicBrainz` (this module) - Main unified interface

  ## Configuration

  Configure the client in your application's config:

      config :son_ex_musicbrainz_client,
        user_agent: "MyApp/1.0.0 (contact@example.com)",
        http_options: [
          retry: :transient,
          max_retries: 3,
          receive_timeout: 15_000
        ]

  ## Rate Limiting

  The MusicBrainz API enforces a rate limit of 1 request per second.
  This client does not implement rate limiting internally - you should
  implement backpressure and throttling at a higher layer.

  ## Usage Examples

  ### Traditional MBID-based API

      # Lookup by MBID
      {:ok, artist} = SonEx.MusicBrainz.lookup_artist("5b11f4ce-a62d-471e-81fc-a69a8278c7da")

      # Browse releases by artist
      {:ok, releases} = SonEx.MusicBrainz.browse_releases([artist: "artist-mbid"], limit: 50)

      # Search
      {:ok, results} = SonEx.MusicBrainz.search_artists("name:Nirvana", limit: 10)

  ### Smart Dispatch with Entity Maps

      # Lookup artist from a release map
      release = %{"artist-credit" => [%{"artist" => %{"id" => "artist-mbid"}}]}
      {:ok, artist} = SonEx.MusicBrainz.lookup_artist(release)

      # Browse releases from an artist map
      artist = %{"id" => "artist-mbid", "type" => "Group"}
      {:ok, releases} = SonEx.MusicBrainz.browse_releases(artist)

  ### Module-based API

  You can also call entity modules directly:

      SonEx.MusicBrainz.Artist.lookup("mbid")
      SonEx.MusicBrainz.Release.browse([artist: "mbid"])
      SonEx.MusicBrainz.Recording.search("title:Bohemian Rhapsody")
  """

  alias SonEx.MusicBrainz.{
    Artist,
    Release,
    ReleaseGroup,
    Recording,
    Event,
    Label,
    Place,
    Work,
    Area,
    Genre,
    Instrument,
    Series,
    URL,
    Client
  }

  ## Artist Functions

  @doc "Lookup an artist by MBID or extract from another entity."
  defdelegate lookup_artist(source, opts \\ []), to: Artist, as: :lookup

  @doc "Browse artists by related entity."
  defdelegate browse_artists(relationship_or_map, opts \\ []), to: Artist, as: :browse

  @doc "Search for artists."
  defdelegate search_artists(query, opts \\ []), to: Artist, as: :search

  ## Release Functions

  @doc "Lookup a release by MBID or extract from another entity."
  defdelegate lookup_release(source, opts \\ []), to: Release, as: :lookup

  @doc "Browse releases by related entity."
  defdelegate browse_releases(relationship_or_map, opts \\ []), to: Release, as: :browse

  @doc "Search for releases."
  defdelegate search_releases(query, opts \\ []), to: Release, as: :search

  ## Release Group Functions

  @doc "Lookup a release group by MBID or extract from another entity."
  defdelegate lookup_release_group(source, opts \\ []), to: ReleaseGroup, as: :lookup

  @doc "Browse release groups by related entity."
  defdelegate browse_release_groups(relationship_or_map, opts \\ []),
    to: ReleaseGroup,
    as: :browse

  @doc "Search for release groups."
  defdelegate search_release_groups(query, opts \\ []), to: ReleaseGroup, as: :search

  ## Recording Functions

  @doc "Lookup a recording by MBID or extract from another entity."
  defdelegate lookup_recording(source, opts \\ []), to: Recording, as: :lookup

  @doc "Browse recordings by related entity."
  defdelegate browse_recordings(relationship_or_map, opts \\ []), to: Recording, as: :browse

  @doc "Search for recordings."
  defdelegate search_recordings(query, opts \\ []), to: Recording, as: :search

  ## Event Functions

  @doc "Lookup an event by MBID or extract from another entity."
  defdelegate lookup_event(source, opts \\ []), to: Event, as: :lookup

  @doc "Browse events by related entity."
  defdelegate browse_events(relationship_or_map, opts \\ []), to: Event, as: :browse

  @doc "Search for events."
  defdelegate search_events(query, opts \\ []), to: Event, as: :search

  ## Label Functions

  @doc "Lookup a label by MBID or extract from another entity."
  defdelegate lookup_label(source, opts \\ []), to: Label, as: :lookup

  @doc "Browse labels by related entity."
  defdelegate browse_labels(relationship_or_map, opts \\ []), to: Label, as: :browse

  @doc "Search for labels."
  defdelegate search_labels(query, opts \\ []), to: Label, as: :search

  ## Place Functions

  @doc "Lookup a place by MBID or extract from another entity."
  defdelegate lookup_place(source, opts \\ []), to: Place, as: :lookup

  @doc "Browse places by related entity."
  defdelegate browse_places(relationship_or_map, opts \\ []), to: Place, as: :browse

  @doc "Search for places."
  defdelegate search_places(query, opts \\ []), to: Place, as: :search

  ## Work Functions

  @doc "Lookup a work by MBID or extract from another entity."
  defdelegate lookup_work(source, opts \\ []), to: Work, as: :lookup

  @doc "Browse works by related entity."
  defdelegate browse_works(relationship_or_map, opts \\ []), to: Work, as: :browse

  @doc "Search for works."
  defdelegate search_works(query, opts \\ []), to: Work, as: :search

  ## Area Functions

  @doc "Lookup an area by MBID or extract from another entity."
  defdelegate lookup_area(source, opts \\ []), to: Area, as: :lookup

  @doc "Browse areas by related entity."
  defdelegate browse_areas(relationship_or_map, opts \\ []), to: Area, as: :browse

  @doc "Search for areas."
  defdelegate search_areas(query, opts \\ []), to: Area, as: :search

  ## Genre Functions

  @doc "Lookup a genre by MBID."
  defdelegate lookup_genre(source, opts \\ []), to: Genre, as: :lookup

  @doc "Search for genres."
  defdelegate search_genres(query, opts \\ []), to: Genre, as: :search

  ## Instrument Functions

  @doc "Lookup an instrument by MBID."
  defdelegate lookup_instrument(source, opts \\ []), to: Instrument, as: :lookup

  @doc "Browse instruments by related entity."
  defdelegate browse_instruments(relationship_or_map, opts \\ []), to: Instrument, as: :browse

  @doc "Search for instruments."
  defdelegate search_instruments(query, opts \\ []), to: Instrument, as: :search

  ## Series Functions

  @doc "Lookup a series by MBID."
  defdelegate lookup_series(source, opts \\ []), to: Series, as: :lookup

  @doc "Browse series by related entity."
  defdelegate browse_series(relationship_or_map, opts \\ []), to: Series, as: :browse

  @doc "Search for series."
  defdelegate search_series(query, opts \\ []), to: Series, as: :search

  ## URL Functions

  @doc "Lookup a URL by MBID."
  defdelegate lookup_url(source, opts \\ []), to: URL, as: :lookup

  @doc "Browse URLs by related entity."
  defdelegate browse_urls(relationship_or_map, opts \\ []), to: URL, as: :browse

  @doc "Search for URLs."
  defdelegate search_urls(query, opts \\ []), to: URL, as: :search

  ## Generic Functions (for backward compatibility)

  @doc """
  Generic lookup function for any entity type.

  Use this for entity types that don't have dedicated modules yet
  (area, event, genre, instrument, label, place, series, work, url).

  ## Examples

      SonEx.MusicBrainz.lookup(:label, "label-mbid")
      SonEx.MusicBrainz.lookup(:area, "area-mbid", inc: ["aliases"])
  """
  defdelegate lookup(entity_type, mbid, opts \\ []), to: Client

  @doc """
  Generic browse function for any entity type.

  ## Examples

      SonEx.MusicBrainz.browse(:label, [area: "area-mbid"], limit: 50)
      SonEx.MusicBrainz.browse(:event, [artist: "artist-mbid"])
  """
  defdelegate browse(entity_type, relationship, opts \\ []), to: Client

  @doc """
  Generic search function for any entity type.

  ## Examples

      SonEx.MusicBrainz.search(:label, "label:Warp", limit: 10)
      SonEx.MusicBrainz.search(:area, "area:London")
  """
  defdelegate search(entity_type, query, opts \\ []), to: Client
end

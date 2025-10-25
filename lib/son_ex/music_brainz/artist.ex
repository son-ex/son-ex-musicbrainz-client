defmodule SonEx.MusicBrainz.Artist do
  @moduledoc """
  Functions for working with MusicBrainz Artist entities.

  This module provides smart dispatch - functions can accept either:
  - A string MBID
  - A map representing any entity that contains artist information

  ## Examples

      # Traditional lookup with MBID
      Artist.lookup("5b11f4ce-a62d-471e-81fc-a69a8278c7da")

      # Search by name
      Artist.search("Nirvana")

      # Smart dispatch - extract artist from a release
      release = %{"artist-credit" => [%{"artist" => %{"id" => "abc123"}}]}
      Artist.lookup(release)  # Extracts artist MBID and looks it up
  """

  alias SonEx.MusicBrainz.{Client, Extractor}

  @type source :: String.t() | map()
  @type opts :: keyword()

  @doc """
  Lookup an artist by MBID or from another entity.

  Accepts:
  - String MBID
  - Any map containing artist information (release, recording, etc.)

  ## Options

  - `:inc` - List of subqueries to include (e.g., `["aliases", "recordings"]`)

  ## Examples

      Artist.lookup("5b11f4ce-a62d-471e-81fc-a69a8278c7da")
      #=> {:ok, %{"id" => "...", "name" => "Nirvana", ...}}

      Artist.lookup(%{"artist-credit" => [%{"artist" => %{"id" => "..."}}]})
      #=> {:ok, %{"id" => "...", "name" => "...", ...}}
  """
  @spec lookup(source(), opts()) :: {:ok, map()} | {:error, term()}
  def lookup(source, opts \\ []) do
    with {:ok, mbid} <- Extractor.extract_mbid(source, :artist) do
      Client.lookup(:artist, mbid, opts)
    end
  end

  @doc """
  Browse artists by related entity.

  Accepts:
  - Keyword list with relationship (e.g., `[area: "mbid"]`)
  - Map representing a related entity (automatically extracts appropriate MBID)

  ## Supported Relationships

  - `:area` - Artists from a specific area
  - `:collection` - Artists in a collection
  - `:recording` - Artists of a recording
  - `:release` - Artists of a release
  - `:release_group` - Artists of a release group
  - `:work` - Artists of a work

  ## Options

  - `:limit` - Number of results (default: 25, max: 100)
  - `:offset` - Offset for pagination
  - `:inc` - List of subqueries to include

  ## Examples

      Artist.browse([area: "area-mbid"], limit: 50)
      #=> {:ok, %{"artists" => [...], ...}}

      # Smart dispatch from an area map
      area = %{"id" => "area-mbid"}
      Artist.browse(area)
      #=> {:ok, %{"artists" => [...], ...}}
  """
  @spec browse(keyword() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def browse(relationship_or_map, opts \\ [])

  # Handle keyword list (traditional approach)
  def browse(relationship, opts) when is_list(relationship) and is_list(opts) do
    Client.browse(:artist, relationship, opts)
  end

  # Smart dispatch from area map
  def browse(%{"iso-3166-1-codes" => _} = area_map, opts) do
    with {:ok, mbid} <- Extractor.extract_mbid(area_map, :area) do
      Client.browse(:artist, [area: mbid], opts)
    end
  end

  # Smart dispatch from recording map
  def browse(%{"length" => _, "video" => _} = recording_map, opts) do
    with {:ok, mbid} <- Extractor.extract_mbid(recording_map, :recording) do
      Client.browse(:artist, [recording: mbid], opts)
    end
  end

  # Smart dispatch from release map
  def browse(%{"status" => _} = release_map, opts) do
    with {:ok, mbid} <- Extractor.extract_mbid(release_map, :release) do
      Client.browse(:artist, [release: mbid], opts)
    end
  end

  # Smart dispatch from release-group map
  def browse(%{"primary-type" => _} = rg_map, opts) do
    with {:ok, mbid} <- Extractor.extract_mbid(rg_map, :release_group) do
      Client.browse(:artist, [release_group: mbid], opts)
    end
  end

  # Fallback: try to extract ID directly
  def browse(%{"id" => id}, opts) do
    # Try different relationship types based on common patterns
    # Default to area if we can't determine
    Client.browse(:artist, [area: id], opts)
  end

  @doc """
  Search for artists using Lucene query syntax.

  Accepts:
  - String query
  - Map representing another entity (searches for related artists)

  ## Query Fields

  - `artist` - Artist name
  - `alias` - Artist alias
  - `type` - Artist type (Person, Group)
  - `gender` - Gender
  - `area` - Area name
  - `arid` - Artist MBID

  ## Options

  - `:limit` - Number of results (default: 25, max: 100)
  - `:offset` - Offset for pagination

  ## Examples

      Artist.search("artist:nirvana AND country:US", limit: 10)
      #=> {:ok, %{"artists" => [...], "count" => 15, ...}}

      # Search from partial data (searches by name if available)
      Artist.search(%{"name" => "Nirvana"})
      #=> {:ok, %{"artists" => [...], ...}}
  """
  @spec search(String.t() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def search(query, opts \\ [])

  # String query - pass through
  def search(query, opts) when is_binary(query) do
    Client.search(:artist, query, opts)
  end

  # Map with name - search by name
  def search(%{"name" => name}, opts) when is_binary(name) do
    Client.search(:artist, "artist:#{name}", opts)
  end

  # Fallback - try to build a query from available fields
  def search(map, opts) when is_map(map) do
    query = build_search_query(map)
    Client.search(:artist, query, opts)
  end

  defp build_search_query(%{"name" => name}), do: "artist:#{name}"
  defp build_search_query(_), do: "*:*"
end

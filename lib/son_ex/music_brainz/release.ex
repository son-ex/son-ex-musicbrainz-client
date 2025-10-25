defmodule SonEx.MusicBrainz.Release do
  @moduledoc """
  Functions for working with MusicBrainz Release entities.

  This module provides smart dispatch - functions can accept either:
  - A string MBID
  - A map representing any entity that contains release information

  ## Examples

      # Traditional lookup with MBID
      Release.lookup("76df3287-6cda-33eb-8e9a-044b5e15ffdd")

      # Browse releases by artist
      Release.browse([artist: "artist-mbid"])

      # Smart dispatch - browse releases from an artist map
      artist = %{"id" => "artist-mbid", "type" => "Group"}
      Release.browse(artist)
  """

  alias SonEx.MusicBrainz.{Client, Extractor}

  @type source :: String.t() | map()
  @type opts :: keyword()

  @doc """
  Lookup a release by MBID or from another entity.
  """
  @spec lookup(source(), opts()) :: {:ok, map()} | {:error, term()}
  def lookup(source, opts \\ []) do
    with {:ok, mbid} <- Extractor.extract_mbid(source, :release) do
      Client.lookup(:release, mbid, opts)
    end
  end

  @doc """
  Browse releases by related entity.

  ## Supported Relationships

  - `:artist` - Releases by an artist
  - `:collection` - Releases in a collection
  - `:label` - Releases by a label
  - `:track` - Releases containing a track
  - `:track_artist` - Releases with track by artist
  - `:recording` - Releases containing a recording
  - `:release_group` - Releases in a release group

  ## Options

  - `:limit` - Number of results (default: 25, max: 100)
  - `:offset` - Offset for pagination
  - `:inc` - List of subqueries to include
  - `:type` - Release group type filter
  - `:status` - Release status filter

  ## Examples

      Release.browse([artist: "artist-mbid"], limit: 50)
      #=> {:ok, %{"releases" => [...], ...}}

      # Smart dispatch from artist map
      artist = %{"id" => "artist-mbid", "type" => "Group"}
      Release.browse(artist)
      #=> {:ok, %{"releases" => [...], ...}}
  """
  @spec browse(keyword() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def browse(relationship_or_map, opts \\ [])

  # Handle keyword list (traditional approach)
  def browse(relationship, opts) when is_list(relationship) and is_list(opts) do
    Client.browse(:release, relationship, opts)
  end

  # Smart dispatch from artist map
  def browse(%{"type" => type} = artist_map, opts) when type in ["Group", "Person"] do
    with {:ok, mbid} <- Extractor.extract_mbid(artist_map, :artist) do
      Client.browse(:release, [artist: mbid], opts)
    end
  end

  # Smart dispatch from label map
  def browse(%{"label-code" => _} = label_map, opts) do
    with {:ok, mbid} <- Extractor.extract_mbid(label_map, :label) do
      Client.browse(:release, [label: mbid], opts)
    end
  end

  # Smart dispatch from recording map
  def browse(%{"length" => _, "video" => _} = recording_map, opts) do
    with {:ok, mbid} <- Extractor.extract_mbid(recording_map, :recording) do
      Client.browse(:release, [recording: mbid], opts)
    end
  end

  # Smart dispatch from release-group map
  def browse(%{"primary-type" => _} = rg_map, opts) do
    with {:ok, mbid} <- Extractor.extract_mbid(rg_map, :release_group) do
      Client.browse(:release, [release_group: mbid], opts)
    end
  end

  # Fallback: try to extract ID and guess relationship
  def browse(%{"id" => id}, opts) do
    # Default to artist as most common use case
    Client.browse(:release, [artist: id], opts)
  end

  @doc """
  Search for releases using Lucene query syntax.

  ## Query Fields

  - `release` - Release title
  - `artist` - Artist name
  - `date` - Release date
  - `country` - Release country
  - `barcode` - Barcode
  - `status` - Release status
  - `reid` - Release MBID

  ## Options

  - `:limit` - Number of results (default: 25, max: 100)
  - `:offset` - Offset for pagination

  ## Examples

      Release.search("release:nevermind AND artist:nirvana", limit: 10)
      #=> {:ok, %{"releases" => [...], ...}}
  """
  @spec search(String.t() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def search(query, opts \\ [])

  def search(query, opts) when is_binary(query) do
    Client.search(:release, query, opts)
  end

  def search(%{"title" => title}, opts) when is_binary(title) do
    Client.search(:release, "release:#{title}", opts)
  end

  def search(map, opts) when is_map(map) do
    query = build_search_query(map)
    Client.search(:release, query, opts)
  end

  defp build_search_query(%{"title" => title}), do: "release:#{title}"
  defp build_search_query(_), do: "*:*"
end

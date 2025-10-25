defmodule SonEx.MusicBrainz.Event do
  @moduledoc """
  Functions for working with MusicBrainz Event entities (concerts, festivals, etc.).
  """

  alias SonEx.MusicBrainz.{Client, Extractor}

  @type source :: String.t() | map()
  @type opts :: keyword()

  @spec lookup(source(), opts()) :: {:ok, map()} | {:error, term()}
  def lookup(source, opts \\ []) do
    with {:ok, mbid} <- Extractor.extract_mbid(source, :event) do
      Client.lookup(:event, mbid, opts)
    end
  end

  @spec browse(keyword() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def browse(relationship_or_map, opts \\ [])

  def browse(relationship, opts) when is_list(relationship) and is_list(opts) do
    Client.browse(:event, relationship, opts)
  end

  # Smart dispatch from artist map
  def browse(%{"type" => type} = artist_map, opts) when type in ["Group", "Person"] do
    with {:ok, mbid} <- Extractor.extract_mbid(artist_map, :artist) do
      Client.browse(:event, [artist: mbid], opts)
    end
  end

  # Smart dispatch from area map
  def browse(%{"iso-3166-1-codes" => _} = area_map, opts) do
    with {:ok, mbid} <- Extractor.extract_mbid(area_map, :area) do
      Client.browse(:event, [area: mbid], opts)
    end
  end

  # Smart dispatch from place map
  def browse(%{"coordinates" => _} = place_map, opts) do
    with {:ok, mbid} <- Extractor.extract_mbid(place_map, :place) do
      Client.browse(:event, [place: mbid], opts)
    end
  end

  def browse(%{"id" => id}, opts) do
    Client.browse(:event, [area: id], opts)
  end

  @spec search(String.t() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def search(query, opts \\ [])

  def search(query, opts) when is_binary(query) do
    Client.search(:event, query, opts)
  end

  def search(%{"name" => name}, opts) when is_binary(name) do
    Client.search(:event, "event:#{name}", opts)
  end

  def search(map, opts) when is_map(map) do
    Client.search(:event, "*:*", opts)
  end
end

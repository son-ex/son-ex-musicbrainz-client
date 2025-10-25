defmodule SonEx.MusicBrainz.Place do
  @moduledoc """
  Functions for working with MusicBrainz Place entities (venues, stadiums, etc.).
  """

  alias SonEx.MusicBrainz.{Client, Extractor}

  @type source :: String.t() | map()
  @type opts :: keyword()

  @spec lookup(source(), opts()) :: {:ok, map()} | {:error, term()}
  def lookup(source, opts \\ []) do
    with {:ok, mbid} <- Extractor.extract_mbid(source, :place) do
      Client.lookup(:place, mbid, opts)
    end
  end

  @spec browse(keyword() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def browse(relationship_or_map, opts \\ [])

  def browse(relationship, opts) when is_list(relationship) and is_list(opts) do
    Client.browse(:place, relationship, opts)
  end

  # Smart dispatch from area map
  def browse(%{"iso-3166-1-codes" => _} = area_map, opts) do
    with {:ok, mbid} <- Extractor.extract_mbid(area_map, :area) do
      Client.browse(:place, [area: mbid], opts)
    end
  end

  def browse(%{"id" => id}, opts) do
    Client.browse(:place, [area: id], opts)
  end

  @spec search(String.t() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def search(query, opts \\ [])

  def search(query, opts) when is_binary(query) do
    Client.search(:place, query, opts)
  end

  def search(%{"name" => name}, opts) when is_binary(name) do
    Client.search(:place, "place:#{name}", opts)
  end

  def search(map, opts) when is_map(map) do
    Client.search(:place, "*:*", opts)
  end
end

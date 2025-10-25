defmodule SonEx.MusicBrainz.Area do
  @moduledoc """
  Functions for working with MusicBrainz Area entities (countries, cities, regions).
  """

  alias SonEx.MusicBrainz.{Client, Extractor}

  @type source :: String.t() | map()
  @type opts :: keyword()

  @spec lookup(source(), opts()) :: {:ok, map()} | {:error, term()}
  def lookup(source, opts \\ []) do
    with {:ok, mbid} <- Extractor.extract_mbid(source, :area) do
      Client.lookup(:area, mbid, opts)
    end
  end

  @spec browse(keyword() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def browse(relationship_or_map, opts \\ [])

  def browse(relationship, opts) when is_list(relationship) and is_list(opts) do
    Client.browse(:area, relationship, opts)
  end

  def browse(%{"id" => id}, opts) do
    Client.browse(:area, [collection: id], opts)
  end

  @spec search(String.t() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def search(query, opts \\ [])

  def search(query, opts) when is_binary(query) do
    Client.search(:area, query, opts)
  end

  def search(%{"name" => name}, opts) when is_binary(name) do
    Client.search(:area, "area:#{name}", opts)
  end

  def search(map, opts) when is_map(map) do
    Client.search(:area, "*:*", opts)
  end
end

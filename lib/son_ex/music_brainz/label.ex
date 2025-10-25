defmodule SonEx.MusicBrainz.Label do
  @moduledoc """
  Functions for working with MusicBrainz Label entities.
  """

  alias SonEx.MusicBrainz.{Client, Extractor}

  @type source :: String.t() | map()
  @type opts :: keyword()

  @spec lookup(source(), opts()) :: {:ok, map()} | {:error, term()}
  def lookup(source, opts \\ []) do
    with {:ok, mbid} <- Extractor.extract_mbid(source, :label) do
      Client.lookup(:label, mbid, opts)
    end
  end

  @spec browse(keyword() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def browse(relationship_or_map, opts \\ [])

  def browse(relationship, opts) when is_list(relationship) and is_list(opts) do
    Client.browse(:label, relationship, opts)
  end

  # Smart dispatch from area map
  def browse(%{"iso-3166-1-codes" => _} = area_map, opts) do
    with {:ok, mbid} <- Extractor.extract_mbid(area_map, :area) do
      Client.browse(:label, [area: mbid], opts)
    end
  end

  # Smart dispatch from release map
  def browse(%{"status" => _} = release_map, opts) do
    with {:ok, mbid} <- Extractor.extract_mbid(release_map, :release) do
      Client.browse(:label, [release: mbid], opts)
    end
  end

  def browse(%{"id" => id}, opts) do
    Client.browse(:label, [area: id], opts)
  end

  @spec search(String.t() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def search(query, opts \\ [])

  def search(query, opts) when is_binary(query) do
    Client.search(:label, query, opts)
  end

  def search(%{"name" => name}, opts) when is_binary(name) do
    Client.search(:label, "label:#{name}", opts)
  end

  def search(map, opts) when is_map(map) do
    Client.search(:label, "*:*", opts)
  end
end

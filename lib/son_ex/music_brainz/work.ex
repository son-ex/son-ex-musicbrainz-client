defmodule SonEx.MusicBrainz.Work do
  @moduledoc """
  Functions for working with MusicBrainz Work entities (compositions, songs, etc.).
  """

  alias SonEx.MusicBrainz.{Client, Extractor}

  @type source :: String.t() | map()
  @type opts :: keyword()

  @spec lookup(source(), opts()) :: {:ok, map()} | {:error, term()}
  def lookup(source, opts \\ []) do
    with {:ok, mbid} <- Extractor.extract_mbid(source, :work) do
      Client.lookup(:work, mbid, opts)
    end
  end

  @spec browse(keyword() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def browse(relationship_or_map, opts \\ [])

  def browse(relationship, opts) when is_list(relationship) and is_list(opts) do
    Client.browse(:work, relationship, opts)
  end

  # Smart dispatch from artist map
  def browse(%{"type" => type} = artist_map, opts) when type in ["Group", "Person"] do
    with {:ok, mbid} <- Extractor.extract_mbid(artist_map, :artist) do
      Client.browse(:work, [artist: mbid], opts)
    end
  end

  def browse(%{"id" => id}, opts) do
    Client.browse(:work, [artist: id], opts)
  end

  @spec search(String.t() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def search(query, opts \\ [])

  def search(query, opts) when is_binary(query) do
    Client.search(:work, query, opts)
  end

  def search(%{"title" => title}, opts) when is_binary(title) do
    Client.search(:work, "work:#{title}", opts)
  end

  def search(map, opts) when is_map(map) do
    Client.search(:work, "*:*", opts)
  end
end

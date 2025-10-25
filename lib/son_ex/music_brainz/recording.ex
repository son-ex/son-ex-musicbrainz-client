defmodule SonEx.MusicBrainz.Recording do
  @moduledoc """
  Functions for working with MusicBrainz Recording entities.
  """

  alias SonEx.MusicBrainz.{Client, Extractor}

  @type source :: String.t() | map()
  @type opts :: keyword()

  @spec lookup(source(), opts()) :: {:ok, map()} | {:error, term()}
  def lookup(source, opts \\ []) do
    with {:ok, mbid} <- Extractor.extract_mbid(source, :recording) do
      Client.lookup(:recording, mbid, opts)
    end
  end

  @spec browse(keyword() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def browse(relationship_or_map, opts \\ [])

  def browse(relationship, opts) when is_list(relationship) and is_list(opts) do
    Client.browse(:recording, relationship, opts)
  end

  # Smart dispatch from artist map
  def browse(%{"type" => type} = artist_map, opts) when type in ["Group", "Person"] do
    with {:ok, mbid} <- Extractor.extract_mbid(artist_map, :artist) do
      Client.browse(:recording, [artist: mbid], opts)
    end
  end

  # Smart dispatch from release map
  def browse(%{"status" => _} = release_map, opts) do
    with {:ok, mbid} <- Extractor.extract_mbid(release_map, :release) do
      Client.browse(:recording, [release: mbid], opts)
    end
  end

  def browse(%{"id" => id}, opts) do
    Client.browse(:recording, [artist: id], opts)
  end

  @spec search(String.t() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def search(query, opts \\ [])

  def search(query, opts) when is_binary(query) do
    Client.search(:recording, query, opts)
  end

  def search(%{"title" => title}, opts) when is_binary(title) do
    Client.search(:recording, "recording:#{title}", opts)
  end

  def search(map, opts) when is_map(map) do
    query = build_search_query(map)
    Client.search(:recording, query, opts)
  end

  defp build_search_query(%{"title" => title}), do: "recording:#{title}"
  defp build_search_query(_), do: "*:*"
end

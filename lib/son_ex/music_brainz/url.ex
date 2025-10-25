defmodule SonEx.MusicBrainz.URL do
  @moduledoc """
  Functions for working with MusicBrainz URL entities.

  URLs represent external links associated with other entities.
  """

  alias SonEx.MusicBrainz.Client

  @type source :: String.t() | map()
  @type opts :: keyword()

  @spec lookup(source(), opts()) :: {:ok, map()} | {:error, term()}
  def lookup(source, opts \\ [])

  def lookup(mbid, opts) when is_binary(mbid) do
    Client.lookup(:url, mbid, opts)
  end

  def lookup(%{"id" => id}, opts) do
    Client.lookup(:url, id, opts)
  end

  @spec browse(keyword() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def browse(relationship_or_map, opts \\ [])

  def browse(relationship, opts) when is_list(relationship) and is_list(opts) do
    Client.browse(:url, relationship, opts)
  end

  def browse(%{"id" => id}, opts) do
    Client.browse(:url, [resource: id], opts)
  end

  @spec search(String.t() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def search(query, opts \\ [])

  def search(query, opts) when is_binary(query) do
    Client.search(:url, query, opts)
  end

  def search(_map, opts) do
    Client.search(:url, "*:*", opts)
  end
end

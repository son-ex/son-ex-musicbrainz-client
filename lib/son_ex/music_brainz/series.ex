defmodule SonEx.MusicBrainz.Series do
  @moduledoc """
  Functions for working with MusicBrainz Series entities.

  Series group releases, release groups, recordings, works, or events with a common theme.
  """

  alias SonEx.MusicBrainz.Client

  @type source :: String.t() | map()
  @type opts :: keyword()

  @spec lookup(source(), opts()) :: {:ok, map()} | {:error, term()}
  def lookup(source, opts \\ [])

  def lookup(mbid, opts) when is_binary(mbid) do
    Client.lookup(:series, mbid, opts)
  end

  def lookup(%{"id" => id}, opts) do
    Client.lookup(:series, id, opts)
  end

  @spec browse(keyword() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def browse(relationship_or_map, opts \\ [])

  def browse(relationship, opts) when is_list(relationship) and is_list(opts) do
    Client.browse(:series, relationship, opts)
  end

  def browse(%{"id" => id}, opts) do
    Client.browse(:series, [collection: id], opts)
  end

  @spec search(String.t() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def search(query, opts \\ [])

  def search(query, opts) when is_binary(query) do
    Client.search(:series, query, opts)
  end

  def search(%{"name" => name}, opts) when is_binary(name) do
    Client.search(:series, "#{name}", opts)
  end

  def search(_map, opts) do
    Client.search(:series, "*:*", opts)
  end
end

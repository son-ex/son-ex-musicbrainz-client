defmodule SonEx.MusicBrainz.Instrument do
  @moduledoc """
  Functions for working with MusicBrainz Instrument entities.

  Note: Instruments have a simple structure similar to genres and are
  primarily used for categorization.
  """

  alias SonEx.MusicBrainz.Client

  @type source :: String.t() | map()
  @type opts :: keyword()

  @spec lookup(source(), opts()) :: {:ok, map()} | {:error, term()}
  def lookup(source, opts \\ [])

  def lookup(mbid, opts) when is_binary(mbid) do
    Client.lookup(:instrument, mbid, opts)
  end

  def lookup(%{"id" => id}, opts) do
    Client.lookup(:instrument, id, opts)
  end

  @spec browse(keyword() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def browse(relationship_or_map, opts \\ [])

  def browse(relationship, opts) when is_list(relationship) and is_list(opts) do
    Client.browse(:instrument, relationship, opts)
  end

  def browse(%{"id" => id}, opts) do
    Client.browse(:instrument, [collection: id], opts)
  end

  @spec search(String.t() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def search(query, opts \\ [])

  def search(query, opts) when is_binary(query) do
    Client.search(:instrument, query, opts)
  end

  def search(%{"name" => name}, opts) when is_binary(name) do
    Client.search(:instrument, "#{name}", opts)
  end

  def search(_map, opts) do
    Client.search(:instrument, "*:*", opts)
  end
end

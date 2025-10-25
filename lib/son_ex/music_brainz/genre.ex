defmodule SonEx.MusicBrainz.Genre do
  @moduledoc """
  Functions for working with MusicBrainz Genre entities.

  Note: Genres have a simple structure (id, name, disambiguation) and are
  primarily used for categorization rather than relationship traversal.
  """

  alias SonEx.MusicBrainz.Client

  @type source :: String.t() | map()
  @type opts :: keyword()

  @spec lookup(source(), opts()) :: {:ok, map()} | {:error, term()}
  def lookup(source, opts \\ [])

  def lookup(mbid, opts) when is_binary(mbid) do
    Client.lookup(:genre, mbid, opts)
  end

  def lookup(%{"id" => id}, opts) do
    Client.lookup(:genre, id, opts)
  end

  @spec search(String.t() | map(), opts()) :: {:ok, map()} | {:error, term()}
  def search(query, opts \\ [])

  def search(query, opts) when is_binary(query) do
    Client.search(:genre, query, opts)
  end

  def search(%{"name" => name}, opts) when is_binary(name) do
    Client.search(:genre, "#{name}", opts)
  end

  def search(_map, opts) do
    Client.search(:genre, "*:*", opts)
  end
end

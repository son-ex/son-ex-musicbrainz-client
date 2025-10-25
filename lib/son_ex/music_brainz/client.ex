defmodule SonEx.MusicBrainz.Client do
  @moduledoc """
  Low-level HTTP client for the MusicBrainz API.

  This module handles the actual HTTP requests to the MusicBrainz web service,
  including configuration, header management, and parameter normalization.

  ## Configuration

  Configure via your application config:

      config :son_ex_musicbrainz_client,
        user_agent: "MyApp/1.0.0 (contact@example.com)",
        http_options: [
          retry: :transient,
          max_retries: 3,
          receive_timeout: 15_000
        ]
  """

  @base_url "https://musicbrainz.org/ws/2"
  @default_user_agent "SonExMusicbrainz/0.2.0"

  @type entity_type ::
          :area
          | :artist
          | :event
          | :genre
          | :instrument
          | :label
          | :place
          | :recording
          | :release
          | :release_group
          | :series
          | :work
          | :url
  @type opts :: keyword()
  @type response :: {:ok, map()} | term()

  @doc """
  Performs a lookup request for a specific entity by MBID.

  ## Parameters

  - `entity_type` - The type of entity to lookup
  - `mbid` - The MusicBrainz ID
  - `opts` - Optional parameters (e.g., `inc: ["recordings", "releases"]`)

  ## Examples

      Client.lookup(:artist, "5b11f4ce-a62d-471e-81fc-a69a8278c7da")
      #=> {:ok, %{"id" => "...", "name" => "Nirvana", ...}}
  """
  @spec lookup(entity_type(), String.t(), opts()) :: response()
  def lookup(entity_type, mbid, opts \\ []) do
    path = "/#{normalize_entity_type(entity_type)}/#{mbid}"
    get(path, opts)
  end

  @doc """
  Performs a browse request to find entities related to another entity.

  ## Parameters

  - `entity_type` - The type of entity to browse
  - `relationship` - Keyword list with the relationship (e.g., `[artist: "mbid"]`)
  - `opts` - Optional parameters (e.g., `limit: 50, offset: 0`)

  ## Examples

      Client.browse(:release, [artist: "5b11f4ce-a62d-471e-81fc-a69a8278c7da"], limit: 50)
      #=> {:ok, %{"releases" => [...], "release-count" => 150, ...}}
  """
  @spec browse(entity_type(), keyword(), opts()) :: response()
  def browse(entity_type, relationship, opts \\ []) do
    path = "/#{normalize_entity_type(entity_type)}"
    combined_opts = relationship ++ opts
    get(path, combined_opts)
  end

  @doc """
  Performs a search request using Lucene query syntax.

  ## Parameters

  - `entity_type` - The type of entity to search
  - `query` - Lucene query string (e.g., `"artist:nirvana"`)
  - `opts` - Optional parameters (e.g., `limit: 25, offset: 0`)

  ## Examples

      Client.search(:artist, "artist:nirvana AND country:US", limit: 10)
      #=> {:ok, %{"artists" => [...], "count" => 15, ...}}
  """
  @spec search(entity_type(), String.t(), opts()) :: response()
  def search(entity_type, query, opts \\ []) do
    path = "/#{normalize_entity_type(entity_type)}"
    combined_opts = [{:query, query} | opts]
    get(path, combined_opts)
  end

  ## Private Functions

  @spec get(String.t(), opts()) :: response()
  defp get(path, opts) do
    params = build_params(opts)
    url = @base_url <> path

    user_agent = Application.get_env(:son_ex_musicbrainz_client, :user_agent, @default_user_agent)
    http_options = Application.get_env(:son_ex_musicbrainz_client, :http_options, [])

    req_options =
      Keyword.merge(
        [
          params: params,
          headers: [
            {"User-Agent", user_agent},
            {"Accept", "application/json"}
          ]
        ],
        http_options
      )

    case Req.get(url, req_options) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      response ->
        response
    end
  end

  @spec build_params(opts()) :: keyword()
  defp build_params(opts) do
    opts
    |> Enum.map(&normalize_param/1)
    |> Enum.reject(&is_nil/1)
  end

  @spec normalize_param({atom(), term()}) :: {atom(), String.t()} | nil
  defp normalize_param({:inc, values}) when is_list(values) do
    {:inc, Enum.join(values, "+")}
  end

  defp normalize_param({:inc, value}) when is_binary(value) do
    {:inc, value}
  end

  defp normalize_param({:release_group, mbid}) do
    {:"release-group", mbid}
  end

  defp normalize_param({key, value}) do
    {key, to_string(value)}
  end

  @spec normalize_entity_type(entity_type()) :: String.t()
  defp normalize_entity_type(:release_group), do: "release-group"
  defp normalize_entity_type(entity_type), do: Atom.to_string(entity_type)
end

defmodule SonExMusicbrainzClient do
  @moduledoc """
  A client for the MusicBrainz API (https://musicbrainz.org/doc/MusicBrainz_API).

  This client provides three main operations:
  - `lookup/3` - Retrieve a specific entity by MBID
  - `browse/3` - Find entities linked to another entity
  - `search/3` - Query for entities by name or other criteria

  All responses are returned as native Elixir maps parsed from JSON.

  ## Configuration

  Configure the client in your application's config:

      config :son_ex_musicbrainz_client,
        user_agent: "MyApp/1.0.0 (contact@example.com)",
        http_options: [
          retry: :transient,
          max_retries: 3,
          receive_timeout: 15_000
        ]

  ### User Agent

  The MusicBrainz API requires a meaningful User-Agent header identifying your application.
  Configure this via the `:user_agent` key.

  ### HTTP Options

  You can pass additional options to the underlying Req client via `:http_options`.
  These will be merged with the default options. Common options include:
  - `:retry` - Retry strategy (`:safe_transient`, `:transient`, `:never`, or custom function)
  - `:max_retries` - Maximum number of retry attempts
  - `:receive_timeout` - Socket receive timeout in milliseconds
  - `:pool_timeout` - Connection pool checkout timeout
  - `:connect_options` - Low-level connection options

  See the Req documentation for all available options.

  ## Rate Limiting

  The MusicBrainz API enforces a rate limit of 1 request per second. This client does
  not implement rate limiting internally - you should implement backpressure and throttling
  at a higher layer in your application.

  ## Supported Entity Types

  The following entity types are supported across all operations:
  - `:area`
  - `:artist`
  - `:event`
  - `:genre`
  - `:instrument`
  - `:label`
  - `:place`
  - `:recording`
  - `:release`
  - `:release_group`
  - `:series`
  - `:work`
  - `:url`

  ## Examples

      # Lookup an artist by MBID
      {:ok, artist} = SonExMusicbrainzClient.lookup(:artist, "5b11f4ce-a62d-471e-81fc-a69a8278c7da")

      # Lookup with additional includes
      {:ok, artist} = SonExMusicbrainzClient.lookup(:artist, "5b11f4ce-a62d-471e-81fc-a69a8278c7da",
        inc: ["recordings", "releases"])

      # Browse releases by artist
      {:ok, releases} = SonExMusicbrainzClient.browse(:release, [artist: "5b11f4ce-a62d-471e-81fc-a69a8278c7da"],
        limit: 50, offset: 0)

      # Search for artists
      {:ok, results} = SonExMusicbrainzClient.search(:artist, "name:Nirvana", limit: 10)
  """

  @base_url "https://musicbrainz.org/ws/2"
  @default_user_agent "SonExMusicbrainzClient/0.1.0"

  @type mbid :: String.t()
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

  ## Lookup Functions

  @doc """
  Lookup an entity by MBID (MusicBrainz Identifier).

  ## Supported Entities

  `:area`, `:artist`, `:event`, `:genre`, `:instrument`, `:label`, `:place`,
  `:recording`, `:release`, `:release_group`, `:series`, `:work`, `:url`

  ## Options

  - `:inc` - List of subqueries to include (e.g., `["aliases", "tags", "recordings", "releases"]`)

  ## Examples

      SonExMusicbrainzClient.lookup(:artist, "5b11f4ce-a62d-471e-81fc-a69a8278c7da")
      {:ok, %{"id" => "5b11f4ce-a62d-471e-81fc-a69a8278c7da", "name" => "Nirvana", ...}}

      SonExMusicbrainzClient.lookup(:release, "...", inc: ["artists", "labels"])
      {:ok, %{"artists" => [...], ...}}
  """
  @spec lookup(entity_type(), mbid(), opts()) :: response()
  def lookup(entity_type, mbid, opts \\ [])

  def lookup(:area, mbid, opts) do
    get("/area/#{mbid}", opts)
  end

  def lookup(:artist, mbid, opts) do
    get("/artist/#{mbid}", opts)
  end

  def lookup(:event, mbid, opts) do
    get("/event/#{mbid}", opts)
  end

  def lookup(:genre, mbid, opts) do
    get("/genre/#{mbid}", opts)
  end

  def lookup(:instrument, mbid, opts) do
    get("/instrument/#{mbid}", opts)
  end

  def lookup(:label, mbid, opts) do
    get("/label/#{mbid}", opts)
  end

  def lookup(:place, mbid, opts) do
    get("/place/#{mbid}", opts)
  end

  def lookup(:recording, mbid, opts) do
    get("/recording/#{mbid}", opts)
  end

  def lookup(:release, mbid, opts) do
    get("/release/#{mbid}", opts)
  end

  def lookup(:release_group, mbid, opts) do
    get("/release-group/#{mbid}", opts)
  end

  def lookup(:series, mbid, opts) do
    get("/series/#{mbid}", opts)
  end

  def lookup(:work, mbid, opts) do
    get("/work/#{mbid}", opts)
  end

  def lookup(:url, mbid, opts) do
    get("/url/#{mbid}", opts)
  end

  ## Browse Functions

  @doc """
  Browse entities by related entity.

  ## Supported Entity Types

  `:area`, `:artist`, `:event`, `:instrument`, `:label`, `:place`, `:recording`,
  `:release`, `:release_group`, `:series`, `:work`, `:url`

  Each entity type supports different relationships. See the MusicBrainz API
  documentation for valid relationship combinations per entity type.

  ## Options

  - `:limit` - Number of results to return (default: 25, max: 100)
  - `:offset` - Offset for pagination (default: 0)
  - `:inc` - List of subqueries to include
  - `:type` - Type filter (for releases and release groups)
  - `:status` - Status filter (for releases)

  ## Examples

      SonExMusicbrainzClient.browse(:release, [artist: "5b11f4ce-a62d-471e-81fc-a69a8278c7da"], limit: 50)
      {:ok, %{"releases" => [...], "release-count" => 150, ...}}

      SonExMusicbrainzClient.browse(:artist, [area: "..."], inc: ["aliases"])
      {:ok, %{"artists" => [...], ...}}
  """
  @spec browse(entity_type(), keyword(), opts()) :: response()
  def browse(entity, relationship, opts \\ [])

  def browse(:area, [collection: mbid], opts) do
    get("/area", [{:collection, mbid} | opts])
  end

  def browse(:artist, [area: mbid], opts) do
    get("/artist", [{:area, mbid} | opts])
  end

  def browse(:artist, [collection: mbid], opts) do
    get("/artist", [{:collection, mbid} | opts])
  end

  def browse(:artist, [recording: mbid], opts) do
    get("/artist", [{:recording, mbid} | opts])
  end

  def browse(:artist, [release: mbid], opts) do
    get("/artist", [{:release, mbid} | opts])
  end

  def browse(:artist, [release_group: mbid], opts) do
    get("/artist", [{:"release-group", mbid} | opts])
  end

  def browse(:artist, [work: mbid], opts) do
    get("/artist", [{:work, mbid} | opts])
  end

  def browse(:event, [area: mbid], opts) do
    get("/event", [{:area, mbid} | opts])
  end

  def browse(:event, [artist: mbid], opts) do
    get("/event", [{:artist, mbid} | opts])
  end

  def browse(:event, [collection: mbid], opts) do
    get("/event", [{:collection, mbid} | opts])
  end

  def browse(:event, [place: mbid], opts) do
    get("/event", [{:place, mbid} | opts])
  end

  def browse(:instrument, [collection: mbid], opts) do
    get("/instrument", [{:collection, mbid} | opts])
  end

  def browse(:label, [area: mbid], opts) do
    get("/label", [{:area, mbid} | opts])
  end

  def browse(:label, [collection: mbid], opts) do
    get("/label", [{:collection, mbid} | opts])
  end

  def browse(:label, [release: mbid], opts) do
    get("/label", [{:release, mbid} | opts])
  end

  def browse(:place, [area: mbid], opts) do
    get("/place", [{:area, mbid} | opts])
  end

  def browse(:place, [collection: mbid], opts) do
    get("/place", [{:collection, mbid} | opts])
  end

  def browse(:recording, [artist: mbid], opts) do
    get("/recording", [{:artist, mbid} | opts])
  end

  def browse(:recording, [collection: mbid], opts) do
    get("/recording", [{:collection, mbid} | opts])
  end

  def browse(:recording, [release: mbid], opts) do
    get("/recording", [{:release, mbid} | opts])
  end

  def browse(:recording, [work: mbid], opts) do
    get("/recording", [{:work, mbid} | opts])
  end

  def browse(:release, [artist: mbid], opts) do
    get("/release", [{:artist, mbid} | opts])
  end

  def browse(:release, [collection: mbid], opts) do
    get("/release", [{:collection, mbid} | opts])
  end

  def browse(:release, [label: mbid], opts) do
    get("/release", [{:label, mbid} | opts])
  end

  def browse(:release, [track: mbid], opts) do
    get("/release", [{:track, mbid} | opts])
  end

  def browse(:release, [track_artist: mbid], opts) do
    get("/release", [{:track_artist, mbid} | opts])
  end

  def browse(:release, [recording: mbid], opts) do
    get("/release", [{:recording, mbid} | opts])
  end

  def browse(:release, [release_group: mbid], opts) do
    get("/release", [{:"release-group", mbid} | opts])
  end

  def browse(:release_group, [artist: mbid], opts) do
    get("/release-group", [{:artist, mbid} | opts])
  end

  def browse(:release_group, [collection: mbid], opts) do
    get("/release-group", [{:collection, mbid} | opts])
  end

  def browse(:release_group, [release: mbid], opts) do
    get("/release-group", [{:release, mbid} | opts])
  end

  def browse(:series, [collection: mbid], opts) do
    get("/series", [{:collection, mbid} | opts])
  end

  def browse(:work, [artist: mbid], opts) do
    get("/work", [{:artist, mbid} | opts])
  end

  def browse(:work, [collection: mbid], opts) do
    get("/work", [{:collection, mbid} | opts])
  end

  def browse(:url, [resource: mbid], opts) do
    get("/url", [{:resource, mbid} | opts])
  end

  ## Search Functions

  @doc """
  Search for entities using Lucene query syntax.

  ## Supported Entity Types

  `:area`, `:artist`, `:event`, `:genre`, `:instrument`, `:label`, `:place`,
  `:recording`, `:release`, `:release_group`, `:series`, `:work`, `:url`

  ## Query Syntax

  Uses Lucene search syntax. Common fields vary by entity type:
  - Artists: `artist`, `alias`, `type`, `gender`, `area`, `tag`, `arid` (MBID)
  - Releases: `release`, `artist`, `date`, `country`, `barcode`, `status`, `reid` (MBID)
  - Recordings: `recording`, `artist`, `release`, `date`, `isrc`, `rid` (MBID)

  ## Options

  - `:limit` - Number of results to return (default: 25, max: 100)
  - `:offset` - Offset for pagination (default: 0)

  ## Examples

      SonExMusicbrainzClient.search(:artist, "artist:nirvana AND country:US")
      {:ok, %{"artists" => [...], "count" => 15, "offset" => 0}}

      SonExMusicbrainzClient.search(:release, "release:nevermind", limit: 10)
      {:ok, %{"releases" => [...], ...}}
  """
  @spec search(entity_type(), String.t(), opts()) :: response()
  def search(entity, query, opts \\ [])

  def search(:area, query, opts) do
    get("/area", [{:query, query} | opts])
  end

  def search(:artist, query, opts) do
    get("/artist", [{:query, query} | opts])
  end

  def search(:event, query, opts) do
    get("/event", [{:query, query} | opts])
  end

  def search(:genre, query, opts) do
    get("/genre", [{:query, query} | opts])
  end

  def search(:instrument, query, opts) do
    get("/instrument", [{:query, query} | opts])
  end

  def search(:label, query, opts) do
    get("/label", [{:query, query} | opts])
  end

  def search(:place, query, opts) do
    get("/place", [{:query, query} | opts])
  end

  def search(:recording, query, opts) do
    get("/recording", [{:query, query} | opts])
  end

  def search(:release, query, opts) do
    get("/release", [{:query, query} | opts])
  end

  def search(:release_group, query, opts) do
    get("/release-group", [{:query, query} | opts])
  end

  def search(:series, query, opts) do
    get("/series", [{:query, query} | opts])
  end

  def search(:work, query, opts) do
    get("/work", [{:query, query} | opts])
  end

  def search(:url, query, opts) do
    get("/url", [{:query, query} | opts])
  end

  ## Private HTTP Functions

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
end

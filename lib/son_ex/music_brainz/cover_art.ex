defmodule SonEx.MusicBrainz.CoverArt do
  @moduledoc """
  Functions for working with the Cover Art Archive API.

  The Cover Art Archive (https://coverartarchive.org) is a joint project between
  the Internet Archive and MusicBrainz, providing cover art images for releases.

  This module provides smart dispatch - functions can accept either:
  - A string MBID
  - A map representing a release or release-group entity

  ## Response Types

  - **Metadata functions** return `{:ok, map()}` with cover art information (JSON)
  - **Image functions** return `{:ok, url}` with the image URL as a string
  - **Thumbnail support**: All image functions accept `:size` option (250, 500, or 1200 pixels)

  ## Examples

      # Get cover art metadata for a release
      {:ok, metadata} = CoverArt.fetch_release_cover_art("release-mbid")
      #=> {:ok, %{"images" => [...], "release" => "..."}}

      # Get front cover image URL
      {:ok, url} = CoverArt.fetch_front("release-mbid")
      #=> {:ok, "https://archive.org/download/mbid-770b9b80-.../image.jpg"}

      # Get front cover thumbnail
      {:ok, url} = CoverArt.fetch_front("release-mbid", size: 250)
      #=> {:ok, "https://archive.org/download/mbid-770b9b80-.../front-250.jpg"}

      # Smart dispatch from release map
      release = %{"id" => "release-mbid", "status" => "Official"}
      {:ok, url} = CoverArt.fetch_front(release)
      #=> {:ok, "https://archive.org/download/...jpg"}
  """

  alias SonEx.MusicBrainz.Extractor

  @base_url "https://coverartarchive.org"
  @default_user_agent "SonExMusicbrainz/0.2.1"

  @type source :: String.t() | map()
  @type opts :: keyword()
  @type size :: 250 | 500 | 1200
  @type image_type :: :front | :back | String.t()

  # Release endpoints

  @doc """
  Fetch cover art metadata for a release.

  Returns JSON with all available cover art images and their metadata.

  ## Parameters

  - `source` - Release MBID string or release map
  - `opts` - Optional parameters

  ## Examples

      CoverArt.fetch_release_cover_art("76df3287-6cda-33eb-8e9a-044b5e15ffdd")
      #=> {:ok, %{
      #     "images" => [
      #       %{
      #         "approved" => true,
      #         "front" => true,
      #         "image" => "https://...",
      #         "thumbnails" => %{"250" => "...", "500" => "...", "1200" => "..."},
      #         "types" => ["Front"]
      #       }
      #     ],
      #     "release" => "https://musicbrainz.org/release/..."
      #   }}
  """
  @spec fetch_release_cover_art(source(), opts()) :: {:ok, map()} | {:error, term()}
  def fetch_release_cover_art(source, opts \\ []) do
    with {:ok, mbid} <- Extractor.extract_mbid(source, :release) do
      path = "/release/#{mbid}"
      get(path, opts, :json)
    end
  end

  @doc """
  Fetch cover art metadata for a release group.

  Returns JSON with cover art from a representative release in the group.

  ## Parameters

  - `source` - Release group MBID string or release-group map
  - `opts` - Optional parameters

  ## Examples

      CoverArt.fetch_release_group_cover_art("release-group-mbid")
      #=> {:ok, %{"images" => [...], "release" => "..."}}
  """
  @spec fetch_release_group_cover_art(source(), opts()) :: {:ok, map()} | {:error, term()}
  def fetch_release_group_cover_art(source, opts \\ []) do
    with {:ok, mbid} <- Extractor.extract_mbid(source, :release_group) do
      path = "/release-group/#{mbid}"
      get(path, opts, :json)
    end
  end

  @doc """
  Fetch the front cover image URL.

  Returns the direct URL to the image.
  Supports optional thumbnail size.

  ## Parameters

  - `source` - Release or release-group MBID string, or entity map
  - `opts` - Optional parameters
    - `:size` - Thumbnail size (250, 500, or 1200 pixels)
    - `:entity_type` - Either `:release` (default) or `:release_group`

  ## Examples

      # Full size front cover
      {:ok, url} = CoverArt.fetch_front("release-mbid")
      #=> {:ok, "https://archive.org/download/.../image.jpg"}

      # Thumbnail
      {:ok, url} = CoverArt.fetch_front("release-mbid", size: 250)
      #=> {:ok, "https://archive.org/download/.../image-250.jpg"}

      # From release group
      {:ok, url} = CoverArt.fetch_front("rg-mbid", entity_type: :release_group)

      # Smart dispatch from map
      {:ok, url} = CoverArt.fetch_front(%{"id" => "...", "status" => "Official"})
  """
  @spec fetch_front(source(), opts()) :: {:ok, String.t()} | {:error, term()}
  def fetch_front(source, opts \\ []) do
    fetch_image(source, :front, opts)
  end

  @doc """
  Fetch the back cover image URL.

  Returns the direct URL to the image.
  Supports optional thumbnail size.

  ## Parameters

  - `source` - Release or release-group MBID string, or entity map
  - `opts` - Optional parameters (same as `fetch_front/2`)

  ## Examples

      {:ok, url} = CoverArt.fetch_back("release-mbid")
      #=> {:ok, "https://archive.org/download/.../back.jpg"}

      {:ok, url} = CoverArt.fetch_back("release-mbid", size: 500)
      #=> {:ok, "https://archive.org/download/.../back-500.jpg"}
  """
  @spec fetch_back(source(), opts()) :: {:ok, String.t()} | {:error, term()}
  def fetch_back(source, opts \\ []) do
    fetch_image(source, :back, opts)
  end

  @doc """
  Fetch a specific cover art image URL by ID.

  Returns the direct URL to the image.
  Supports optional thumbnail size.

  ## Parameters

  - `source` - Release MBID string or release map
  - `image_id` - The cover art archive image ID (from metadata)
  - `opts` - Optional parameters
    - `:size` - Thumbnail size (250, 500, or 1200 pixels)

  ## Examples

      {:ok, url} = CoverArt.fetch_image_by_id("release-mbid", "12345")
      #=> {:ok, "https://archive.org/download/.../12345.jpg"}

      {:ok, url} = CoverArt.fetch_image_by_id("release-mbid", "12345", size: 250)
      #=> {:ok, "https://archive.org/download/.../12345-250.jpg"}
  """
  @spec fetch_image_by_id(source(), String.t(), opts()) :: {:ok, String.t()} | {:error, term()}
  def fetch_image_by_id(source, image_id, opts \\ []) do
    fetch_image(source, image_id, opts)
  end

  ## Private Functions

  @spec fetch_image(source(), image_type(), opts()) :: {:ok, String.t()} | {:error, term()}
  defp fetch_image(source, image_type, opts) do
    entity_type = Keyword.get(opts, :entity_type, :release)
    size = Keyword.get(opts, :size)

    with {:ok, mbid} <- extract_mbid_for_entity(source, entity_type) do
      entity_path = entity_path(entity_type)
      image_path = build_image_path(image_type, size)
      path = "/#{entity_path}/#{mbid}/#{image_path}"

      case get(path, opts, :redirect) do
        {:ok, %{headers: headers}} ->
          case Map.get(headers, "location") do
            [url | _] -> {:ok, url}
            _ -> {:error, :no_location_header}
          end

        error ->
          error
      end
    end
  end

  @spec extract_mbid_for_entity(source(), atom()) :: {:ok, String.t()} | {:error, term()}
  defp extract_mbid_for_entity(source, :release) do
    Extractor.extract_mbid(source, :release)
  end

  defp extract_mbid_for_entity(source, :release_group) do
    Extractor.extract_mbid(source, :release_group)
  end

  @spec entity_path(atom()) :: String.t()
  defp entity_path(:release), do: "release"
  defp entity_path(:release_group), do: "release-group"

  @spec build_image_path(image_type(), size() | nil) :: String.t()
  defp build_image_path(image_type, nil), do: to_string(image_type)

  defp build_image_path(image_type, size) when size in [250, 500, 1200] do
    "#{image_type}-#{size}"
  end

  @spec get(String.t(), opts(), :json | :redirect) :: {:ok, map()} | {:error, term()}
  defp get(path, opts, response_type) do
    url = @base_url <> path

    user_agent = Application.get_env(:son_ex_musicbrainz_client, :user_agent, @default_user_agent)
    http_options = Application.get_env(:son_ex_musicbrainz_client, :http_options, [])

    headers = [
      {"User-Agent", user_agent},
      {"Accept", "application/json"}
    ]

    req_options =
      Keyword.merge(
        [
          headers: headers,
          # Don't auto-follow redirects for image endpoints
          redirect: response_type == :json
        ],
        http_options
      )

    # Allow plug override from opts (for testing)
    req_options =
      case Keyword.get(opts, :plug) do
        nil -> req_options
        plug -> Keyword.put(req_options, :plug, plug)
      end

    case Req.get(url, req_options) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: 307} = response} ->
        # Return the full response for redirect endpoints
        {:ok, response}

      response ->
        response
    end
  end
end

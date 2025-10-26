defmodule SonExMusicbrainzCoverArtTest do
  use ExUnit.Case

  alias SonEx.MusicBrainz
  alias SonEx.MusicBrainz.CoverArt

  setup do
    # Create a mock plug for Cover Art Archive API
    mock_plug = fn conn ->
      response =
        case conn.request_path do
          "/release/" <> rest ->
            handle_release_endpoint(rest)

          "/release-group/" <> rest ->
            handle_release_group_endpoint(rest)

          _ ->
            {404, %{"error" => "Not found"}}
        end

      {status, body} = response

      # If the body has a location header marker, set it
      conn =
        case Map.get(body, "__location_header__") do
          nil ->
            conn

          location ->
            Plug.Conn.put_resp_header(conn, "location", location)
        end

      # Remove the marker from the body
      body = Map.delete(body, "__location_header__")

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(status, JSON.encode!(body))
    end

    %{plug: mock_plug}
  end

  defp handle_release_endpoint(rest) do
    cond do
      # Metadata endpoint
      String.ends_with?(rest, "/") or not String.contains?(rest, "/") ->
        mbid = String.trim_trailing(rest, "/")

        {200,
         %{
           "images" => [
             %{
               "approved" => true,
               "front" => true,
               "back" => false,
               "image" => "https://archive.org/download/mbid-#{mbid}/front.jpg",
               "thumbnails" => %{
                 "250" => "https://archive.org/download/mbid-#{mbid}/front-250.jpg",
                 "500" => "https://archive.org/download/mbid-#{mbid}/front-500.jpg",
                 "1200" => "https://archive.org/download/mbid-#{mbid}/front-1200.jpg"
               },
               "types" => ["Front"],
               "comment" => "",
               "edit" => 12345,
               "id" => "1234567890"
             }
           ],
           "release" => "https://musicbrainz.org/release/#{mbid}"
         }}

      # Front/back/specific image endpoints (return 307 redirect)
      String.contains?(rest, "/front") or String.contains?(rest, "/back") or
          String.match?(rest, ~r/\/\d+/) ->
        [mbid, image_path] = String.split(rest, "/", parts: 2)
        location = "https://archive.org/download/mbid-#{mbid}/#{image_path}.jpg"

        # Return a special marker that the mock plug will use to set the location header
        {307,
         %{
           "__location_header__" => location,
           "redirect_location" => location
         }}

      true ->
        {404, %{"error" => "Not found"}}
    end
  end

  defp handle_release_group_endpoint(rest) do
    cond do
      # Metadata endpoint
      String.ends_with?(rest, "/") or not String.contains?(rest, "/") ->
        mbid = String.trim_trailing(rest, "/")

        {200,
         %{
           "images" => [
             %{
               "approved" => true,
               "front" => true,
               "image" => "https://archive.org/download/rg-#{mbid}/front.jpg",
               "thumbnails" => %{
                 "250" => "https://archive.org/download/rg-#{mbid}/front-250.jpg",
                 "500" => "https://archive.org/download/rg-#{mbid}/front-500.jpg",
                 "1200" => "https://archive.org/download/rg-#{mbid}/front-1200.jpg"
               },
               "types" => ["Front"]
             }
           ],
           "release" => "https://musicbrainz.org/release/some-release-mbid"
         }}

      # Front image endpoint
      String.contains?(rest, "/front") ->
        [mbid, _] = String.split(rest, "/", parts: 2)
        location = "https://archive.org/download/rg-#{mbid}/front.jpg"

        {307,
         %{
           "__location_header__" => location,
           "redirect_location" => location
         }}

      true ->
        {404, %{"error" => "Not found"}}
    end
  end

  describe "CoverArt.fetch_release_cover_art/2" do
    test "fetches cover art metadata for a release by MBID", %{plug: plug} do
      assert {:ok, response} = CoverArt.fetch_release_cover_art("test-mbid", plug: plug)
      assert is_map(response)
      assert is_list(response["images"])
      assert length(response["images"]) > 0

      image = hd(response["images"])
      assert image["approved"] == true
      assert image["front"] == true
      assert is_map(image["thumbnails"])
      assert Map.has_key?(image["thumbnails"], "250")
      assert Map.has_key?(image["thumbnails"], "500")
      assert Map.has_key?(image["thumbnails"], "1200")
    end

    test "works with release map (smart dispatch)", %{plug: plug} do
      release_map = %{"id" => "test-mbid", "status" => "Official", "packaging" => "Jewel Case"}
      assert {:ok, response} = CoverArt.fetch_release_cover_art(release_map, plug: plug)
      assert is_map(response)
      assert is_list(response["images"])
    end
  end

  describe "CoverArt.fetch_release_group_cover_art/2" do
    test "fetches cover art metadata for a release group by MBID", %{plug: plug} do
      assert {:ok, response} = CoverArt.fetch_release_group_cover_art("test-rg-mbid", plug: plug)
      assert is_map(response)
      assert is_list(response["images"])
      assert length(response["images"]) > 0
    end

    test "works with release group map (smart dispatch)", %{plug: plug} do
      rg_map = %{"id" => "test-rg-mbid", "primary-type" => "Album", "secondary-types" => []}
      assert {:ok, response} = CoverArt.fetch_release_group_cover_art(rg_map, plug: plug)
      assert is_map(response)
      assert is_list(response["images"])
    end

    test "extracts release group from release map", %{plug: plug} do
      release_map = %{
        "id" => "release-mbid",
        "status" => "Official",
        "release-group" => %{"id" => "test-rg-mbid"}
      }

      assert {:ok, response} = CoverArt.fetch_release_group_cover_art(release_map, plug: plug)
      assert is_map(response)
    end
  end

  describe "CoverArt.fetch_front/2" do
    test "fetches front cover image URL for a release", %{plug: plug} do
      assert {:ok, url} = CoverArt.fetch_front("test-mbid", plug: plug)
      assert url =~ "archive.org"
      assert url =~ "test-mbid"
      assert url =~ "front.jpg"
    end

    test "fetches front cover with thumbnail size", %{plug: plug} do
      assert {:ok, url} = CoverArt.fetch_front("test-mbid", plug: plug, size: 250)
      assert url =~ "front-250.jpg"
    end

    test "works with release map (smart dispatch)", %{plug: plug} do
      release_map = %{"id" => "test-mbid", "status" => "Official"}
      assert {:ok, url} = CoverArt.fetch_front(release_map, plug: plug)
      assert url =~ "front.jpg"
    end

    test "fetches from release group with entity_type option", %{plug: plug} do
      assert {:ok, url} =
               CoverArt.fetch_front("test-rg-mbid", plug: plug, entity_type: :release_group)

      assert url =~ "front.jpg"
      assert url =~ "test-rg-mbid"
    end
  end

  describe "CoverArt.fetch_back/2" do
    test "fetches back cover image URL for a release", %{plug: plug} do
      assert {:ok, url} = CoverArt.fetch_back("test-mbid", plug: plug)
      assert url =~ "archive.org"
      assert url =~ "back.jpg"
    end

    test "fetches back cover with thumbnail size", %{plug: plug} do
      assert {:ok, url} = CoverArt.fetch_back("test-mbid", plug: plug, size: 500)
      assert url =~ "back-500.jpg"
    end

    test "works with release map (smart dispatch)", %{plug: plug} do
      release_map = %{"id" => "test-mbid", "status" => "Official", "packaging" => "Jewel Case"}
      assert {:ok, url} = CoverArt.fetch_back(release_map, plug: plug)
      assert url =~ "back.jpg"
    end
  end

  describe "CoverArt.fetch_image_by_id/3" do
    test "fetches specific image URL by ID", %{plug: plug} do
      assert {:ok, url} = CoverArt.fetch_image_by_id("test-mbid", "1234567890", plug: plug)
      assert url =~ "archive.org"
      assert url =~ "1234567890.jpg"
    end

    test "fetches specific image with thumbnail size", %{plug: plug} do
      assert {:ok, url} =
               CoverArt.fetch_image_by_id("test-mbid", "1234567890", plug: plug, size: 1200)

      assert url =~ "1234567890-1200.jpg"
    end

    test "works with release map (smart dispatch)", %{plug: plug} do
      release_map = %{"id" => "test-mbid", "status" => "Official"}

      assert {:ok, url} =
               CoverArt.fetch_image_by_id(release_map, "1234567890", plug: plug)

      assert url =~ "1234567890.jpg"
    end
  end

  describe "Main module delegation" do
    test "delegates fetch_release_cover_art to CoverArt module", %{plug: plug} do
      assert {:ok, response} = MusicBrainz.fetch_release_cover_art("test-mbid", plug: plug)
      assert is_map(response)
      assert is_list(response["images"])
    end

    test "delegates fetch_release_group_cover_art to CoverArt module", %{plug: plug} do
      assert {:ok, response} =
               MusicBrainz.fetch_release_group_cover_art("test-mbid", plug: plug)

      assert is_map(response)
      assert is_list(response["images"])
    end

    test "delegates fetch_front to CoverArt module", %{plug: plug} do
      assert {:ok, url} = MusicBrainz.fetch_front("test-mbid", plug: plug)
      assert url =~ "front.jpg"
      assert url =~ "archive.org"
    end

    test "delegates fetch_back to CoverArt module", %{plug: plug} do
      assert {:ok, url} = MusicBrainz.fetch_back("test-mbid", plug: plug)
      assert url =~ "back.jpg"
      assert url =~ "archive.org"
    end

    test "delegates fetch_cover_art_image to CoverArt module", %{plug: plug} do
      assert {:ok, url} = MusicBrainz.fetch_cover_art_image("test-mbid", "123", plug: plug)
      assert url =~ "123.jpg"
      assert url =~ "archive.org"
    end
  end
end

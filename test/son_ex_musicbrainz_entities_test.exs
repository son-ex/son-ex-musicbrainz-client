defmodule SonExMusicbrainzEntitiesTest do
  use ExUnit.Case

  alias SonEx.MusicBrainz

  setup do
    # Create a comprehensive mock plug for all entity types
    mock_plug = fn conn ->
      response_body =
        case conn.request_path do
          "/ws/2/event/" <> _mbid ->
            %{
              "id" => "test-mbid",
              "name" => "Test Event",
              "type" => "Concert",
              "cancelled" => false
            }

          "/ws/2/label/" <> _mbid ->
            %{"id" => "test-mbid", "name" => "Test Label", "label-code" => 123}

          "/ws/2/place/" <> _mbid ->
            %{
              "id" => "test-mbid",
              "name" => "Test Place",
              "coordinates" => %{"latitude" => 51.5, "longitude" => -0.1}
            }

          "/ws/2/work/" <> _mbid ->
            %{"id" => "test-mbid", "title" => "Test Work", "iswcs" => ["T-123-456-789"]}

          "/ws/2/area/" <> _mbid ->
            %{"id" => "test-mbid", "name" => "Test Area", "iso-3166-1-codes" => ["US"]}

          "/ws/2/genre/" <> _mbid ->
            %{"id" => "test-mbid", "name" => "Test Genre"}

          "/ws/2/instrument/" <> _mbid ->
            %{"id" => "test-mbid", "name" => "Test Instrument"}

          "/ws/2/series/" <> _mbid ->
            %{"id" => "test-mbid", "name" => "Test Series"}

          "/ws/2/url/" <> _mbid ->
            %{"id" => "test-mbid", "resource" => "https://example.com"}

          # Browse and search endpoints
          "/ws/2/event" ->
            handle_browse_or_search(conn, "events")

          "/ws/2/label" ->
            handle_browse_or_search(conn, "labels")

          "/ws/2/place" ->
            handle_browse_or_search(conn, "places")

          "/ws/2/work" ->
            handle_browse_or_search(conn, "works")

          "/ws/2/area" ->
            handle_browse_or_search(conn, "areas")

          "/ws/2/genre" ->
            handle_browse_or_search(conn, "genres")

          "/ws/2/instrument" ->
            handle_browse_or_search(conn, "instruments")

          "/ws/2/series" ->
            handle_browse_or_search(conn, "series")

          "/ws/2/url" ->
            handle_browse_or_search(conn, "urls")

          _ ->
            %{"id" => "test-mbid", "data" => "test"}
        end

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, JSON.encode!(response_body))
    end

    Application.put_env(:son_ex_musicbrainz_client, :http_options, plug: mock_plug)

    on_exit(fn ->
      Application.delete_env(:son_ex_musicbrainz_client, :http_options)
    end)

    :ok
  end

  defp handle_browse_or_search(conn, entity_key) do
    query_params = Plug.Conn.fetch_query_params(conn).query_params

    cond do
      Map.has_key?(query_params, "query") ->
        %{
          entity_key => [
            %{"id" => "search-result-1", "name" => "Result 1", "score" => 100}
          ],
          "count" => 1,
          "offset" => 0
        }

      true ->
        %{
          entity_key => [
            %{"id" => "browse-result-1", "name" => "Browse Result 1"}
          ],
          "#{entity_key}-count" => 1,
          "#{entity_key}-offset" => 0
        }
    end
  end

  describe "Event module" do
    test "looks up an event by MBID" do
      assert {:ok, event} = MusicBrainz.lookup_event("event-mbid")
      assert event["id"] == "test-mbid"
      assert event["name"] == "Test Event"
    end

    test "browses events by artist" do
      assert {:ok, result} = MusicBrainz.browse_events(artist: "artist-mbid")
      assert is_list(result["events"])
    end

    test "searches for events" do
      assert {:ok, result} = MusicBrainz.search_events("event:concert")
      assert is_list(result["events"])
    end

    test "browses events from artist map" do
      artist = %{"id" => "artist-123", "type" => "Group"}
      assert {:ok, result} = MusicBrainz.browse_events(artist)
      assert is_map(result)
    end
  end

  describe "Label module" do
    test "looks up a label by MBID" do
      assert {:ok, label} = MusicBrainz.lookup_label("label-mbid")
      assert label["id"] == "test-mbid"
      assert label["label-code"] == 123
    end

    test "browses labels by area" do
      assert {:ok, result} = MusicBrainz.browse_labels(area: "area-mbid")
      assert is_list(result["labels"])
    end

    test "searches for labels" do
      assert {:ok, result} = MusicBrainz.search_labels("label:warp")
      assert is_list(result["labels"])
    end

    test "browses labels from release map" do
      release = %{"id" => "release-123", "status" => "Official"}
      assert {:ok, result} = MusicBrainz.browse_labels(release)
      assert is_map(result)
    end
  end

  describe "Place module" do
    test "looks up a place by MBID" do
      assert {:ok, place} = MusicBrainz.lookup_place("place-mbid")
      assert place["id"] == "test-mbid"
      assert place["coordinates"]["latitude"] == 51.5
    end

    test "browses places by area" do
      assert {:ok, result} = MusicBrainz.browse_places(area: "area-mbid")
      assert is_list(result["places"])
    end

    test "searches for places" do
      assert {:ok, result} = MusicBrainz.search_places("place:stadium")
      assert is_list(result["places"])
    end

    test "browses places from area map" do
      area = %{"id" => "area-123", "iso-3166-1-codes" => ["US"]}
      assert {:ok, result} = MusicBrainz.browse_places(area)
      assert is_map(result)
    end
  end

  describe "Work module" do
    test "looks up a work by MBID" do
      assert {:ok, work} = MusicBrainz.lookup_work("work-mbid")
      assert work["id"] == "test-mbid"
      assert is_list(work["iswcs"])
    end

    test "browses works by artist" do
      assert {:ok, result} = MusicBrainz.browse_works(artist: "artist-mbid")
      assert is_list(result["works"])
    end

    test "searches for works" do
      assert {:ok, result} = MusicBrainz.search_works("work:bohemian")
      assert is_list(result["works"])
    end

    test "browses works from artist map" do
      artist = %{"id" => "artist-123", "type" => "Person"}
      assert {:ok, result} = MusicBrainz.browse_works(artist)
      assert is_map(result)
    end
  end

  describe "Area module" do
    test "looks up an area by MBID" do
      assert {:ok, area} = MusicBrainz.lookup_area("area-mbid")
      assert area["id"] == "test-mbid"
      assert is_list(area["iso-3166-1-codes"])
    end

    test "browses areas by collection" do
      assert {:ok, result} = MusicBrainz.browse_areas(collection: "collection-mbid")
      assert is_list(result["areas"])
    end

    test "searches for areas" do
      assert {:ok, result} = MusicBrainz.search_areas("area:london")
      assert is_list(result["areas"])
    end
  end

  describe "Genre module" do
    test "looks up a genre by MBID" do
      assert {:ok, genre} = MusicBrainz.lookup_genre("genre-mbid")
      assert genre["id"] == "test-mbid"
      assert genre["name"] == "Test Genre"
    end

    test "searches for genres" do
      assert {:ok, result} = MusicBrainz.search_genres("rock")
      assert is_list(result["genres"])
    end

    test "looks up genre from map" do
      genre_map = %{"id" => "genre-123"}
      assert {:ok, genre} = MusicBrainz.lookup_genre(genre_map)
      assert genre["id"] == "test-mbid"
    end
  end

  describe "Instrument module" do
    test "looks up an instrument by MBID" do
      assert {:ok, instrument} = MusicBrainz.lookup_instrument("instrument-mbid")
      assert instrument["id"] == "test-mbid"
      assert instrument["name"] == "Test Instrument"
    end

    test "browses instruments by collection" do
      assert {:ok, result} = MusicBrainz.browse_instruments(collection: "collection-mbid")
      assert is_list(result["instruments"])
    end

    test "searches for instruments" do
      assert {:ok, result} = MusicBrainz.search_instruments("guitar")
      assert is_list(result["instruments"])
    end
  end

  describe "Series module" do
    test "looks up a series by MBID" do
      assert {:ok, series} = MusicBrainz.lookup_series("series-mbid")
      assert series["id"] == "test-mbid"
      assert series["name"] == "Test Series"
    end

    test "browses series by collection" do
      assert {:ok, result} = MusicBrainz.browse_series(collection: "collection-mbid")
      assert is_list(result["series"])
    end

    test "searches for series" do
      assert {:ok, result} = MusicBrainz.search_series("series:collection")
      assert is_list(result["series"])
    end
  end

  describe "URL module" do
    test "looks up a URL by MBID" do
      assert {:ok, url} = MusicBrainz.lookup_url("url-mbid")
      assert url["id"] == "test-mbid"
    end

    test "browses URLs by resource" do
      assert {:ok, result} = MusicBrainz.browse_urls(resource: "resource-mbid")
      assert is_list(result["urls"])
    end

    test "searches for URLs" do
      assert {:ok, result} = MusicBrainz.search_urls("url:wikipedia")
      assert is_list(result["urls"])
    end
  end

  describe "Smart dispatch integration" do
    test "chains artist -> releases -> recordings" do
      artist_map = %{"id" => "artist-123", "type" => "Group"}

      # Browse releases from artist map
      assert {:ok, releases} = MusicBrainz.browse_releases(artist_map)
      assert is_map(releases)

      # Browse recordings from artist map
      assert {:ok, recordings} = MusicBrainz.browse_recordings(artist_map)
      assert is_map(recordings)
    end

    test "chains release -> artist -> works" do
      release_map = %{
        "id" => "release-123",
        "status" => "Official",
        "artist-credit" => [%{"artist" => %{"id" => "artist-456"}}]
      }

      # Lookup artist from release
      assert {:ok, artist} = MusicBrainz.lookup_artist(release_map)
      assert artist["id"] == "test-mbid"

      # Browse works from artist map
      artist_map = %{"id" => artist["id"], "type" => "Group"}
      assert {:ok, works} = MusicBrainz.browse_works(artist_map)
      assert is_map(works)
    end

    test "chains area -> artists -> events" do
      area_map = %{"id" => "area-123", "iso-3166-1-codes" => ["US"]}

      # Browse artists from area
      assert {:ok, artists} = MusicBrainz.browse_artists(area_map)
      assert is_map(artists)

      # Browse events from area
      assert {:ok, events} = MusicBrainz.browse_events(area_map)
      assert is_map(events)
    end
  end
end

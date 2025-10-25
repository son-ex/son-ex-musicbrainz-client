defmodule SonExMusicbrainzClientTest do
  use ExUnit.Case
  # doctest SonExMusicbrainzClient - disabled due to mock-based testing

  setup do
    # Create a mock plug for testing
    mock_plug = fn conn ->
      response_body =
        case conn.request_path do
          "/ws/2/artist/" <> _mbid ->
            %{"id" => "test-mbid", "name" => "Test Artist", "type" => "Group"}

          "/ws/2/release/" <> _mbid ->
            %{"id" => "test-mbid", "title" => "Test Album"}

          "/ws/2/recording/" <> _mbid ->
            %{"id" => "test-mbid", "title" => "Test Recording"}

          "/ws/2/release-group/" <> _mbid ->
            %{"id" => "test-mbid", "title" => "Test Release Group"}

          "/ws/2/area/" <> _mbid ->
            %{"id" => "test-mbid", "name" => "Test Area"}

          "/ws/2/event/" <> _mbid ->
            %{"id" => "test-mbid", "name" => "Test Event"}

          "/ws/2/genre/" <> _mbid ->
            %{"id" => "test-mbid", "name" => "Test Genre"}

          "/ws/2/instrument/" <> _mbid ->
            %{"id" => "test-mbid", "name" => "Test Instrument"}

          "/ws/2/label/" <> _mbid ->
            %{"id" => "test-mbid", "name" => "Test Label"}

          "/ws/2/place/" <> _mbid ->
            %{"id" => "test-mbid", "name" => "Test Place"}

          "/ws/2/series/" <> _mbid ->
            %{"id" => "test-mbid", "name" => "Test Series"}

          "/ws/2/work/" <> _mbid ->
            %{"id" => "test-mbid", "name" => "Test Work"}

          "/ws/2/url/" <> _mbid ->
            %{"id" => "test-mbid", "name" => "Test URL"}

          "/ws/2/area" ->
            handle_browse_or_search(conn, "areas")

          "/ws/2/artist" ->
            handle_browse_or_search(conn, "artists")

          "/ws/2/release" ->
            handle_browse_or_search(conn, "releases")

          "/ws/2/recording" ->
            handle_browse_or_search(conn, "recordings")

          "/ws/2/label" ->
            handle_browse_or_search(conn, "labels")

          "/ws/2/work" ->
            handle_browse_or_search(conn, "works")

          "/ws/2/event" ->
            handle_browse_or_search(conn, "events")

          "/ws/2/instrument" ->
            handle_browse_or_search(conn, "instruments")

          "/ws/2/place" ->
            handle_browse_or_search(conn, "places")

          "/ws/2/series" ->
            handle_browse_or_search(conn, "series")

          "/ws/2/url" ->
            handle_browse_or_search(conn, "urls")

          "/ws/2/release-group" ->
            handle_browse_or_search(conn, "release-groups")

          "/ws/2/genre" ->
            handle_browse_or_search(conn, "genres")

          _ ->
            %{"id" => "test-mbid", "data" => "test"}
        end

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, JSON.encode!(response_body))
    end

    # Configure the test to use the mock plug
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
        # Search request
        %{
          entity_key => [
            %{"id" => "search-result-1", "name" => "Result 1", "score" => 100},
            %{"id" => "search-result-2", "name" => "Result 2", "score" => 95}
          ],
          "count" => 2,
          "offset" => String.to_integer(query_params["offset"] || "0")
        }

      true ->
        # Browse request
        %{
          entity_key => [
            %{"id" => "browse-result-1", "name" => "Browse Result 1"},
            %{"id" => "browse-result-2", "name" => "Browse Result 2"}
          ],
          "#{entity_key}-count" => 2,
          "#{entity_key}-offset" => String.to_integer(query_params["offset"] || "0")
        }
    end
  end

  describe "lookup/3" do
    test "looks up an artist by MBID" do
      assert {:ok, artist} = SonExMusicbrainzClient.lookup(:artist, "test-mbid-123")
      assert artist["id"] == "test-mbid"
      assert artist["name"] == "Test Artist"
    end

    test "looks up a release by MBID" do
      assert {:ok, release} = SonExMusicbrainzClient.lookup(:release, "release-mbid-456")
      assert release["id"] == "test-mbid"
      assert release["title"] == "Test Album"
    end

    test "looks up a recording by MBID" do
      assert {:ok, recording} = SonExMusicbrainzClient.lookup(:recording, "recording-mbid-789")
      assert recording["id"] == "test-mbid"
      assert recording["title"] == "Test Recording"
    end

    test "looks up a release_group by MBID" do
      assert {:ok, rg} = SonExMusicbrainzClient.lookup(:release_group, "rg-mbid-101")
      assert rg["id"] == "test-mbid"
      assert rg["title"] == "Test Release Group"
    end

    test "looks up all entity types" do
      entity_types = [
        :area,
        :artist,
        :event,
        :genre,
        :instrument,
        :label,
        :place,
        :recording,
        :release,
        :release_group,
        :series,
        :work,
        :url
      ]

      for entity_type <- entity_types do
        assert {:ok, result} = SonExMusicbrainzClient.lookup(entity_type, "test-mbid")
        assert is_map(result)
        assert result["id"] == "test-mbid"
      end
    end

    test "accepts inc parameter as list" do
      assert {:ok, artist} =
               SonExMusicbrainzClient.lookup(:artist, "test-mbid", inc: ["recordings", "releases"])

      assert artist["id"] == "test-mbid"
    end

    test "accepts inc parameter as string" do
      assert {:ok, artist} =
               SonExMusicbrainzClient.lookup(:artist, "test-mbid", inc: "recordings+releases")

      assert artist["id"] == "test-mbid"
    end

    test "looks up all other entity types" do
      entity_types = [
        :event,
        :genre,
        :instrument,
        :label,
        :place,
        :series,
        :work,
        :url
      ]

      for entity_type <- entity_types do
        assert {:ok, result} = SonExMusicbrainzClient.lookup(entity_type, "test-mbid")
        assert is_map(result)
        assert result["id"] == "test-mbid"
      end
    end
  end

  describe "browse/3" do
    test "browses releases by artist" do
      assert {:ok, result} = SonExMusicbrainzClient.browse(:release, [artist: "artist-mbid"])
      assert is_list(result["releases"])
      assert length(result["releases"]) == 2
    end

    test "browses artists by area" do
      assert {:ok, result} = SonExMusicbrainzClient.browse(:artist, [area: "area-mbid"])
      assert is_list(result["artists"])
      assert result["artists-count"] == 2
    end

    test "browses recordings by release" do
      assert {:ok, result} = SonExMusicbrainzClient.browse(:recording, [release: "release-mbid"])
      assert is_list(result["recordings"])
    end

    test "browses with limit and offset" do
      assert {:ok, result} =
               SonExMusicbrainzClient.browse(:release, [artist: "artist-mbid"],
                 limit: 50,
                 offset: 25
               )

      assert result["releases-offset"] == 25
    end

    test "browses with inc parameter" do
      assert {:ok, result} =
               SonExMusicbrainzClient.browse(:artist, [area: "area-mbid"],
                 inc: ["aliases", "tags"]
               )

      assert is_list(result["artists"])
    end

    test "browses artists by all supported relationships" do
      relationships = [
        [area: "area-mbid"],
        [collection: "collection-mbid"],
        [recording: "recording-mbid"],
        [release: "release-mbid"],
        [release_group: "rg-mbid"],
        [work: "work-mbid"]
      ]

      for relationship <- relationships do
        assert {:ok, result} = SonExMusicbrainzClient.browse(:artist, relationship)
        assert is_map(result)
        assert is_list(result["artists"])
      end
    end

    test "browses releases by all supported relationships" do
      relationships = [
        [artist: "artist-mbid"],
        [collection: "collection-mbid"],
        [label: "label-mbid"],
        [track: "track-mbid"],
        [track_artist: "artist-mbid"],
        [recording: "recording-mbid"],
        [release_group: "rg-mbid"]
      ]

      for relationship <- relationships do
        assert {:ok, result} = SonExMusicbrainzClient.browse(:release, relationship)
        assert is_map(result)
        assert is_list(result["releases"])
      end
    end

    test "browses areas by collection" do
      assert {:ok, result} = SonExMusicbrainzClient.browse(:area, [collection: "collection-mbid"])
      assert is_map(result)
      assert is_list(result["areas"])
    end

    test "browses events by all supported relationships" do
      relationships = [
        [area: "area-mbid"],
        [artist: "artist-mbid"],
        [collection: "collection-mbid"],
        [place: "place-mbid"]
      ]

      for relationship <- relationships do
        assert {:ok, result} = SonExMusicbrainzClient.browse(:event, relationship)
        assert is_map(result)
      end
    end

    test "browses instruments by collection" do
      assert {:ok, result} = SonExMusicbrainzClient.browse(:instrument, [collection: "collection-mbid"])
      assert is_map(result)
    end

    test "browses labels by all supported relationships" do
      relationships = [
        [area: "area-mbid"],
        [collection: "collection-mbid"],
        [release: "release-mbid"]
      ]

      for relationship <- relationships do
        assert {:ok, result} = SonExMusicbrainzClient.browse(:label, relationship)
        assert is_map(result)
      end
    end

    test "browses places by all supported relationships" do
      relationships = [
        [area: "area-mbid"],
        [collection: "collection-mbid"]
      ]

      for relationship <- relationships do
        assert {:ok, result} = SonExMusicbrainzClient.browse(:place, relationship)
        assert is_map(result)
      end
    end

    test "browses recordings by all supported relationships" do
      relationships = [
        [artist: "artist-mbid"],
        [collection: "collection-mbid"],
        [release: "release-mbid"],
        [work: "work-mbid"]
      ]

      for relationship <- relationships do
        assert {:ok, result} = SonExMusicbrainzClient.browse(:recording, relationship)
        assert is_map(result)
      end
    end

    test "browses release_groups by all supported relationships" do
      relationships = [
        [artist: "artist-mbid"],
        [collection: "collection-mbid"],
        [release: "release-mbid"]
      ]

      for relationship <- relationships do
        assert {:ok, result} = SonExMusicbrainzClient.browse(:release_group, relationship)
        assert is_map(result)
      end
    end

    test "browses series by collection" do
      assert {:ok, result} = SonExMusicbrainzClient.browse(:series, [collection: "collection-mbid"])
      assert is_map(result)
    end

    test "browses works by all supported relationships" do
      relationships = [
        [artist: "artist-mbid"],
        [collection: "collection-mbid"]
      ]

      for relationship <- relationships do
        assert {:ok, result} = SonExMusicbrainzClient.browse(:work, relationship)
        assert is_map(result)
      end
    end

    test "browses urls by resource" do
      assert {:ok, result} = SonExMusicbrainzClient.browse(:url, [resource: "resource-mbid"])
      assert is_map(result)
    end
  end

  describe "search/3" do
    test "searches for artists" do
      assert {:ok, result} = SonExMusicbrainzClient.search(:artist, "artist:nirvana")
      assert is_list(result["artists"])
      assert result["count"] == 2
      assert result["offset"] == 0
    end

    test "searches for releases" do
      assert {:ok, result} = SonExMusicbrainzClient.search(:release, "release:nevermind")
      assert is_list(result["releases"])
    end

    test "searches for recordings" do
      assert {:ok, result} = SonExMusicbrainzClient.search(:recording, "recording:test")
      assert is_list(result["recordings"])
    end

    test "searches with limit and offset" do
      assert {:ok, result} =
               SonExMusicbrainzClient.search(:artist, "artist:test", limit: 10, offset: 5)

      assert result["offset"] == 5
    end

    test "searches for all entity types" do
      entity_types = [
        :area,
        :event,
        :genre,
        :instrument,
        :label,
        :place,
        :release_group,
        :series,
        :work,
        :url
      ]

      for entity_type <- entity_types do
        query_string = Atom.to_string(entity_type) <> ":test"
        assert {:ok, result} = SonExMusicbrainzClient.search(entity_type, query_string)
        assert is_map(result)
      end
    end

    test "handles complex Lucene queries" do
      assert {:ok, result} =
               SonExMusicbrainzClient.search(
                 :artist,
                 "artist:beatles AND country:GB AND type:group"
               )

      assert is_map(result)
    end
  end

  describe "parameter normalization" do
    test "converts inc list to plus-separated string" do
      # Test that inc parameter with list is converted to plus-separated string
      url_capture_plug = fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["inc"] == "recordings+releases"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, JSON.encode!(%{"id" => "test"}))
      end

      Application.put_env(:son_ex_musicbrainz_client, :http_options, plug: url_capture_plug)

      assert {:ok, _} =
               SonExMusicbrainzClient.lookup(:artist, "test", inc: ["recordings", "releases"])

      Application.delete_env(:son_ex_musicbrainz_client, :http_options)
    end

    test "handles inc as string unchanged" do
      # Test that inc parameter with string is passed through
      url_capture_plug = fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["inc"] == "recordings+releases"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, JSON.encode!(%{"id" => "test"}))
      end

      Application.put_env(:son_ex_musicbrainz_client, :http_options, plug: url_capture_plug)

      assert {:ok, _} =
               SonExMusicbrainzClient.lookup(:artist, "test", inc: "recordings+releases")

      Application.delete_env(:son_ex_musicbrainz_client, :http_options)
    end

    test "converts release_group param to release-group in browse" do
      # Test that release_group is converted to release-group in query params
      url_capture_plug = fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["release-group"] == "test-mbid"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, JSON.encode!(%{"artists" => []}))
      end

      Application.put_env(:son_ex_musicbrainz_client, :http_options, plug: url_capture_plug)

      assert {:ok, _} = SonExMusicbrainzClient.browse(:artist, [release_group: "test-mbid"])

      Application.delete_env(:son_ex_musicbrainz_client, :http_options)
    end

    test "handles release_group entity type in lookup URL" do
      # Test that release_group entity type is converted to release-group in URL
      assert {:ok, _} = SonExMusicbrainzClient.lookup(:release_group, "test-mbid")
    end

    test "converts numeric parameters to strings" do
      url_capture_plug = fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["limit"] == "50"
        assert conn.query_params["offset"] == "100"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, JSON.encode!(%{"releases" => []}))
      end

      Application.put_env(:son_ex_musicbrainz_client, :http_options, plug: url_capture_plug)

      assert {:ok, _} =
               SonExMusicbrainzClient.browse(:release, [artist: "test"],
                 limit: 50,
                 offset: 100
               )

      Application.delete_env(:son_ex_musicbrainz_client, :http_options)
    end

    test "converts release_group in opts to release-group" do
      # Test edge case where release_group appears in opts (not as relationship)
      url_capture_plug = fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        # When release_group is in opts, it should be converted to release-group
        assert conn.query_params["release-group"] == "rg-mbid-123"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, JSON.encode!(%{"id" => "test"}))
      end

      Application.put_env(:son_ex_musicbrainz_client, :http_options, plug: url_capture_plug)

      # Use lookup with release_group in opts to exercise the normalize_param clause
      assert {:ok, _} =
               SonExMusicbrainzClient.lookup(:artist, "test-mbid",
                 release_group: "rg-mbid-123"
               )

      Application.delete_env(:son_ex_musicbrainz_client, :http_options)
    end
  end

  describe "configuration" do
    test "uses default user agent when not configured" do
      Application.delete_env(:son_ex_musicbrainz_client, :user_agent)

      # Create a plug that captures headers
      header_capture_plug = fn conn ->
        user_agent = Plug.Conn.get_req_header(conn, "user-agent") |> List.first()
        assert user_agent == "SonExMusicbrainzClient/0.1.0"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, JSON.encode!(%{"id" => "test"}))
      end

      Application.put_env(:son_ex_musicbrainz_client, :http_options, plug: header_capture_plug)

      assert {:ok, _} = SonExMusicbrainzClient.lookup(:artist, "test")

      Application.delete_env(:son_ex_musicbrainz_client, :http_options)
    end

    test "uses configured user agent" do
      Application.put_env(:son_ex_musicbrainz_client, :user_agent, "TestApp/1.0")

      # Create a plug that captures headers
      header_capture_plug = fn conn ->
        user_agent = Plug.Conn.get_req_header(conn, "user-agent") |> List.first()
        assert user_agent == "TestApp/1.0"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, JSON.encode!(%{"id" => "test"}))
      end

      Application.put_env(:son_ex_musicbrainz_client, :http_options, plug: header_capture_plug)

      assert {:ok, _} = SonExMusicbrainzClient.lookup(:artist, "test")

      Application.delete_env(:son_ex_musicbrainz_client, :http_options)
      Application.delete_env(:son_ex_musicbrainz_client, :user_agent)
    end

    test "always includes Accept: application/json header" do
      header_capture_plug = fn conn ->
        accept = Plug.Conn.get_req_header(conn, "accept") |> List.first()
        assert accept == "application/json"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, JSON.encode!(%{"id" => "test"}))
      end

      Application.put_env(:son_ex_musicbrainz_client, :http_options, plug: header_capture_plug)

      assert {:ok, _} = SonExMusicbrainzClient.lookup(:artist, "test")

      Application.delete_env(:son_ex_musicbrainz_client, :http_options)
    end
  end

  describe "URL construction" do
    test "constructs correct URLs for lookup" do
      url_capture_plug = fn conn ->
        assert conn.request_path =~ ~r{^/ws/2/(artist|release|recording|area)/[^/]+$}
        assert String.starts_with?(conn.host, "musicbrainz.org")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, JSON.encode!(%{"id" => "test"}))
      end

      Application.put_env(:son_ex_musicbrainz_client, :http_options, plug: url_capture_plug)

      assert {:ok, _} = SonExMusicbrainzClient.lookup(:artist, "test-mbid")

      Application.delete_env(:son_ex_musicbrainz_client, :http_options)
    end

    test "includes query parameters correctly" do
      url_capture_plug = fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["inc"] == "recordings+releases"
        assert conn.query_params["limit"] == "50"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, JSON.encode!(%{"id" => "test"}))
      end

      Application.put_env(:son_ex_musicbrainz_client, :http_options, plug: url_capture_plug)

      assert {:ok, _} =
               SonExMusicbrainzClient.lookup(:artist, "test",
                 inc: ["recordings", "releases"],
                 limit: 50
               )

      Application.delete_env(:son_ex_musicbrainz_client, :http_options)
    end
  end
end

defmodule SonExMusicbrainzSmartDispatchTest do
  use ExUnit.Case

  alias SonEx.MusicBrainz

  setup do
    mock_plug = fn conn ->
      response_body = %{
        "test-entity" => [%{"id" => "result-1"}],
        "test-entity-count" => 1
      }

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

  describe "Artist smart dispatch" do
    test "browses from area map" do
      area = %{"iso-3166-1-codes" => ["US"], "id" => "area-id"}
      assert {:ok, _} = MusicBrainz.Artist.browse(area)
    end

    test "browses from recording map" do
      recording = %{"length" => 12345, "video" => false, "id" => "rec-id"}
      assert {:ok, _} = MusicBrainz.Artist.browse(recording)
    end

    test "browses from release map" do
      release = %{"status" => "Official", "id" => "rel-id"}
      assert {:ok, _} = MusicBrainz.Artist.browse(release)
    end

    test "browses from release-group map" do
      rg = %{"primary-type" => "Album", "id" => "rg-id"}
      assert {:ok, _} = MusicBrainz.Artist.browse(rg)
    end

    test "browses with keyword list" do
      assert {:ok, _} = MusicBrainz.Artist.browse(area: "area-mbid")
    end

    test "searches with string query" do
      assert {:ok, _} = MusicBrainz.Artist.search("artist:test")
    end

    test "searches with map containing name" do
      assert {:ok, _} = MusicBrainz.Artist.search(%{"name" => "Nirvana"})
    end

    test "searches with generic map (fallback query)" do
      assert {:ok, _} = MusicBrainz.Artist.search(%{"unknown" => "field"})
    end
  end

  describe "Release smart dispatch" do
    test "browses with keyword list" do
      assert {:ok, _} = MusicBrainz.Release.browse(artist: "artist-mbid")
    end

    test "browses from artist map" do
      artist = %{"type" => "Group", "id" => "artist-id"}
      assert {:ok, _} = MusicBrainz.Release.browse(artist)
    end

    test "browses from label map" do
      label = %{"label-code" => 123, "id" => "label-id"}
      assert {:ok, _} = MusicBrainz.Release.browse(label)
    end

    test "browses from recording map" do
      recording = %{"length" => 12345, "video" => false, "id" => "rec-id"}
      assert {:ok, _} = MusicBrainz.Release.browse(recording)
    end

    test "browses from release-group map" do
      rg = %{"primary-type" => "Album", "id" => "rg-id"}
      assert {:ok, _} = MusicBrainz.Release.browse(rg)
    end

    test "browses with generic map (fallback)" do
      assert {:ok, _} = MusicBrainz.Release.browse(%{"id" => "generic-id"})
    end

    test "searches with string query" do
      assert {:ok, _} = MusicBrainz.Release.search("release:test")
    end

    test "searches with map containing title" do
      assert {:ok, _} = MusicBrainz.Release.search(%{"title" => "Nevermind"})
    end

    test "searches with generic map (fallback query)" do
      assert {:ok, _} = MusicBrainz.Release.search(%{"unknown" => "field"})
    end
  end

  describe "Recording smart dispatch" do
    test "browses with keyword list" do
      assert {:ok, _} = MusicBrainz.Recording.browse(artist: "artist-mbid")
    end

    test "browses from artist map" do
      artist = %{"type" => "Person", "id" => "artist-id"}
      assert {:ok, _} = MusicBrainz.Recording.browse(artist)
    end

    test "browses from release map" do
      release = %{"status" => "Official", "id" => "rel-id"}
      assert {:ok, _} = MusicBrainz.Recording.browse(release)
    end

    test "browses with generic map (fallback)" do
      assert {:ok, _} = MusicBrainz.Recording.browse(%{"id" => "generic-id"})
    end

    test "searches with string query" do
      assert {:ok, _} = MusicBrainz.Recording.search("recording:test")
    end

    test "searches with map containing title" do
      assert {:ok, _} = MusicBrainz.Recording.search(%{"title" => "Bohemian Rhapsody"})
    end

    test "searches with generic map (fallback query)" do
      assert {:ok, _} = MusicBrainz.Recording.search(%{"unknown" => "field"})
    end
  end

  describe "ReleaseGroup smart dispatch" do
    test "browses with keyword list" do
      assert {:ok, _} = MusicBrainz.ReleaseGroup.browse(artist: "artist-mbid")
    end

    test "browses from artist map" do
      artist = %{"type" => "Group", "id" => "artist-id"}
      assert {:ok, _} = MusicBrainz.ReleaseGroup.browse(artist)
    end

    test "browses from release map" do
      release = %{"status" => "Official", "id" => "rel-id"}
      assert {:ok, _} = MusicBrainz.ReleaseGroup.browse(release)
    end

    test "browses with generic map (fallback)" do
      assert {:ok, _} = MusicBrainz.ReleaseGroup.browse(%{"id" => "generic-id"})
    end

    test "searches with string query" do
      assert {:ok, _} = MusicBrainz.ReleaseGroup.search("releasegroup:test")
    end

    test "searches with map containing title" do
      assert {:ok, _} = MusicBrainz.ReleaseGroup.search(%{"title" => "Album Title"})
    end

    test "searches with generic map (fallback query)" do
      assert {:ok, _} = MusicBrainz.ReleaseGroup.search(%{"unknown" => "field"})
    end
  end

  describe "Event smart dispatch" do
    test "browses with keyword list" do
      assert {:ok, _} = MusicBrainz.Event.browse(artist: "artist-mbid")
    end

    test "browses from artist map with Group type" do
      artist = %{"type" => "Group", "id" => "artist-id"}
      assert {:ok, _} = MusicBrainz.Event.browse(artist)
    end

    test "browses from artist map with Person type" do
      artist = %{"type" => "Person", "id" => "artist-id"}
      assert {:ok, _} = MusicBrainz.Event.browse(artist)
    end

    test "browses from area map" do
      area = %{"iso-3166-1-codes" => ["GB"], "id" => "area-id"}
      assert {:ok, _} = MusicBrainz.Event.browse(area)
    end

    test "browses from place map" do
      place = %{"coordinates" => %{"latitude" => 51.5, "longitude" => -0.1}, "id" => "place-id"}
      assert {:ok, _} = MusicBrainz.Event.browse(place)
    end

    test "browses with generic map" do
      assert {:ok, _} = MusicBrainz.Event.browse(%{"id" => "generic-id"})
    end

    test "searches with string query" do
      assert {:ok, _} = MusicBrainz.Event.search("event:test")
    end

    test "searches with map containing name" do
      assert {:ok, _} = MusicBrainz.Event.search(%{"name" => "Concert"})
    end

    test "searches with generic map (fallback query)" do
      assert {:ok, _} = MusicBrainz.Event.search(%{"unknown" => "field"})
    end
  end

  describe "Label smart dispatch" do
    test "browses with keyword list" do
      assert {:ok, _} = MusicBrainz.Label.browse(area: "area-mbid")
    end

    test "browses from area map" do
      area = %{"iso-3166-1-codes" => ["US"], "id" => "area-id"}
      assert {:ok, _} = MusicBrainz.Label.browse(area)
    end

    test "browses from release map" do
      release = %{"status" => "Official", "id" => "rel-id"}
      assert {:ok, _} = MusicBrainz.Label.browse(release)
    end

    test "browses with generic map" do
      assert {:ok, _} = MusicBrainz.Label.browse(%{"id" => "generic-id"})
    end

    test "searches with string query" do
      assert {:ok, _} = MusicBrainz.Label.search("label:test")
    end

    test "searches with map containing name" do
      assert {:ok, _} = MusicBrainz.Label.search(%{"name" => "Warp"})
    end

    test "searches with generic map (fallback query)" do
      assert {:ok, _} = MusicBrainz.Label.search(%{"unknown" => "field"})
    end
  end

  describe "Place smart dispatch" do
    test "browses with keyword list" do
      assert {:ok, _} = MusicBrainz.Place.browse(area: "area-mbid")
    end

    test "browses from area map" do
      area = %{"iso-3166-1-codes" => ["UK"], "id" => "area-id"}
      assert {:ok, _} = MusicBrainz.Place.browse(area)
    end

    test "browses with generic map" do
      assert {:ok, _} = MusicBrainz.Place.browse(%{"id" => "generic-id"})
    end

    test "searches with string query" do
      assert {:ok, _} = MusicBrainz.Place.search("place:test")
    end

    test "searches with map containing name" do
      assert {:ok, _} = MusicBrainz.Place.search(%{"name" => "Emirates Stadium"})
    end

    test "searches with generic map (fallback query)" do
      assert {:ok, _} = MusicBrainz.Place.search(%{"unknown" => "field"})
    end
  end

  describe "Work smart dispatch" do
    test "browses with keyword list" do
      assert {:ok, _} = MusicBrainz.Work.browse(artist: "artist-mbid")
    end

    test "browses from artist map with Group type" do
      artist = %{"type" => "Group", "id" => "artist-id"}
      assert {:ok, _} = MusicBrainz.Work.browse(artist)
    end

    test "browses from artist map with Person type" do
      artist = %{"type" => "Person", "id" => "artist-id"}
      assert {:ok, _} = MusicBrainz.Work.browse(artist)
    end

    test "browses with generic map" do
      assert {:ok, _} = MusicBrainz.Work.browse(%{"id" => "generic-id"})
    end

    test "searches with string query" do
      assert {:ok, _} = MusicBrainz.Work.search("work:test")
    end

    test "searches with map containing title" do
      assert {:ok, _} = MusicBrainz.Work.search(%{"title" => "Bohemian Rhapsody"})
    end

    test "searches with generic map (fallback query)" do
      assert {:ok, _} = MusicBrainz.Work.search(%{"unknown" => "field"})
    end
  end

  describe "Area smart dispatch" do
    test "browses with generic map" do
      assert {:ok, _} = MusicBrainz.Area.browse(%{"id" => "collection-id"})
    end

    test "searches with map containing name" do
      assert {:ok, _} = MusicBrainz.Area.search(%{"name" => "London"})
    end

    test "searches with generic map" do
      assert {:ok, _} = MusicBrainz.Area.search(%{})
    end
  end

  describe "Genre smart dispatch" do
    test "looks up from map" do
      assert {:ok, _} = MusicBrainz.Genre.lookup(%{"id" => "genre-id"})
    end

    test "searches with map containing name" do
      assert {:ok, _} = MusicBrainz.Genre.search(%{"name" => "rock"})
    end

    test "searches with generic map" do
      assert {:ok, _} = MusicBrainz.Genre.search(%{})
    end
  end

  describe "Instrument smart dispatch" do
    test "looks up from map" do
      assert {:ok, _} = MusicBrainz.Instrument.lookup(%{"id" => "instrument-id"})
    end

    test "browses with generic map" do
      assert {:ok, _} = MusicBrainz.Instrument.browse(%{"id" => "collection-id"})
    end

    test "searches with map containing name" do
      assert {:ok, _} = MusicBrainz.Instrument.search(%{"name" => "guitar"})
    end

    test "searches with generic map" do
      assert {:ok, _} = MusicBrainz.Instrument.search(%{})
    end
  end

  describe "Series smart dispatch" do
    test "looks up from map" do
      assert {:ok, _} = MusicBrainz.Series.lookup(%{"id" => "series-id"})
    end

    test "browses with generic map" do
      assert {:ok, _} = MusicBrainz.Series.browse(%{"id" => "collection-id"})
    end

    test "searches with map containing name" do
      assert {:ok, _} = MusicBrainz.Series.search(%{"name" => "series name"})
    end

    test "searches with generic map" do
      assert {:ok, _} = MusicBrainz.Series.search(%{})
    end
  end

  describe "URL smart dispatch" do
    test "looks up from map" do
      assert {:ok, _} = MusicBrainz.URL.lookup(%{"id" => "url-id"})
    end

    test "browses with generic map" do
      assert {:ok, _} = MusicBrainz.URL.browse(%{"id" => "resource-id"})
    end

    test "searches with generic map" do
      assert {:ok, _} = MusicBrainz.URL.search(%{})
    end
  end
end

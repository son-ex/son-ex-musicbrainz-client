defmodule SonExMusicbrainzExtractorTest do
  use ExUnit.Case

  alias SonEx.MusicBrainz.Extractor

  describe "extract_mbid/2" do
    test "extracts MBID from string" do
      assert {:ok, "test-mbid-123"} = Extractor.extract_mbid("test-mbid-123", :artist)
    end

    test "extracts MBID from entity map" do
      assert {:ok, "artist-mbid"} = Extractor.extract_mbid(%{"id" => "artist-mbid"}, :artist)
    end

    test "extracts artist from artist-credit in release" do
      release = %{
        "artist-credit" => [
          %{"artist" => %{"id" => "artist-123"}}
        ]
      }

      assert {:ok, "artist-123"} = Extractor.extract_mbid(release, :artist)
    end

    test "extracts artist from artist-credit in recording" do
      recording = %{
        "artist-credit" => [
          %{"artist" => %{"id" => "recording-artist"}}
        ]
      }

      assert {:ok, "recording-artist"} = Extractor.extract_mbid(recording, :artist)
    end

    test "extracts release-group from release" do
      release = %{
        "release-group" => %{"id" => "rg-mbid"}
      }

      assert {:ok, "rg-mbid"} = Extractor.extract_mbid(release, :release_group)
    end

    test "extracts area from entity" do
      entity = %{"area" => %{"id" => "area-123"}}
      assert {:ok, "area-123"} = Extractor.extract_mbid(entity, :area)
    end

    test "extracts area from begin-area" do
      artist = %{"begin-area" => %{"id" => "begin-area-123"}}
      assert {:ok, "begin-area-123"} = Extractor.extract_mbid(artist, :area)
    end

    test "extracts area from release-events" do
      release = %{
        "release-events" => [
          %{"area" => %{"id" => "event-area-123"}}
        ]
      }

      assert {:ok, "event-area-123"} = Extractor.extract_mbid(release, :area)
    end

    test "returns error when cannot extract" do
      assert {:error, :cannot_extract} = Extractor.extract_mbid(%{}, :artist)
      assert {:error, :cannot_extract} = Extractor.extract_mbid(%{"name" => "test"}, :artist)
    end
  end

  describe "extract_mbid/2 complex patterns" do
    test "extracts place from event with 'held at' relation" do
      event = %{
        "cancelled" => false,
        "relations" => [
          %{"type" => "held at", "place" => %{"id" => "place-123"}}
        ]
      }

      assert {:ok, "place-123"} = Extractor.extract_mbid(event, :place)
    end

    test "extracts place from event with 'held in' relation" do
      event = %{
        "cancelled" => false,
        "relations" => [
          %{"type" => "held in", "place" => %{"id" => "place-456"}}
        ]
      }

      assert {:ok, "place-456"} = Extractor.extract_mbid(event, :place)
    end

    test "returns error when event has no place relations" do
      event = %{"cancelled" => false, "relations" => [%{"type" => "other"}]}
      assert {:error, :cannot_extract} = Extractor.extract_mbid(event, :place)
    end

    test "returns error when event has no relations" do
      event = %{"cancelled" => false}
      assert {:error, :cannot_extract} = Extractor.extract_mbid(event, :place)
    end

    test "extracts work from recording with performance relation" do
      recording = %{
        "length" => 12345,
        "video" => false,
        "relations" => [
          %{"type" => "performance", "work" => %{"id" => "work-789"}}
        ]
      }

      assert {:ok, "work-789"} = Extractor.extract_mbid(recording, :work)
    end

    test "returns error when recording has no work relations" do
      recording = %{"length" => 12345, "video" => false, "relations" => []}
      assert {:error, :cannot_extract} = Extractor.extract_mbid(recording, :work)
    end

    test "returns error when recording has no relations" do
      recording = %{"length" => 12345, "video" => false}
      assert {:error, :cannot_extract} = Extractor.extract_mbid(recording, :work)
    end
  end

  describe "detect_entity_type/1" do
    test "detects artist by type and life-span" do
      artist = %{"type" => "Group", "life-span" => %{}, "sort-name" => "Test"}
      assert {:ok, :artist} = Extractor.detect_entity_type(artist)

      person = %{"type" => "Person", "life-span" => %{}}
      assert {:ok, :artist} = Extractor.detect_entity_type(person)
    end

    test "detects release by status and packaging" do
      release = %{"status" => "Official", "packaging" => "Jewel Case"}
      assert {:ok, :release} = Extractor.detect_entity_type(release)
    end

    test "detects release by status-id and release-events" do
      release = %{"status-id" => "abc", "release-events" => []}
      assert {:ok, :release} = Extractor.detect_entity_type(release)
    end

    test "detects recording by length and video" do
      recording = %{"length" => 355106, "video" => false}
      assert {:ok, :recording} = Extractor.detect_entity_type(recording)
    end

    test "detects release-group by primary-type and secondary-types" do
      rg = %{"primary-type" => "Album", "secondary-types" => []}
      assert {:ok, :release_group} = Extractor.detect_entity_type(rg)
    end

    test "detects label by label-code" do
      label = %{"label-code" => 2070}
      assert {:ok, :label} = Extractor.detect_entity_type(label)
    end

    test "detects area by iso-3166-1-codes" do
      area = %{"iso-3166-1-codes" => ["US"]}
      assert {:ok, :area} = Extractor.detect_entity_type(area)
    end

    test "detects event by cancelled field" do
      event = %{"cancelled" => false, "name" => "Concert"}
      assert {:ok, :event} = Extractor.detect_entity_type(event)
    end

    test "detects place by coordinates" do
      place = %{"coordinates" => %{"latitude" => 51.555, "longitude" => -0.108611}}
      assert {:ok, :place} = Extractor.detect_entity_type(place)
    end

    test "detects work by iswcs" do
      work = %{"iswcs" => ["T-010.154.505-4"]}
      assert {:ok, :work} = Extractor.detect_entity_type(work)
    end

    test "detects work by languages and title" do
      work = %{"languages" => ["eng"], "title" => "Bohemian Rhapsody"}
      assert {:ok, :work} = Extractor.detect_entity_type(work)
    end

    test "detects series by type" do
      series_types = [
        "Release group series",
        "Release series",
        "Recording series",
        "Work series",
        "Catalogue series",
        "Event series"
      ]

      for type <- series_types do
        series = %{"type" => type}
        assert {:ok, :series} = Extractor.detect_entity_type(series),
               "Failed to detect series with type: #{type}"
      end
    end

    test "returns error for unknown entity type" do
      assert {:error, :unknown_entity} = Extractor.detect_entity_type(%{})
      assert {:error, :unknown_entity} = Extractor.detect_entity_type(%{"unknown" => "field"})
    end
  end
end

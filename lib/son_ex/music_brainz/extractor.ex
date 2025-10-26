defmodule SonEx.MusicBrainz.Extractor do
  @moduledoc """
  Extracts MBIDs and identifiers from various MusicBrainz API response shapes.

  This module uses pattern matching to intelligently extract identifiers from
  different entity types and related entities, enabling smart function dispatch.

  See `docs/api_response_examples.md` for the actual API response structures
  that these patterns are based on.
  """

  @doc """
  Extracts an MBID for a given target entity type from various data sources.

  ## Parameters

  - `source` - Can be a string MBID, or a map representing a MusicBrainz entity
  - `target_type` - The type of entity MBID to extract (`:artist`, `:release`, etc.)

  ## Returns

  - `{:ok, mbid}` - Successfully extracted MBID
  - `{:error, :cannot_extract}` - Could not extract MBID from the given source

  ## Examples

      # Direct MBID string
      extract_mbid("5b11f4ce-a62d-471e-81fc-a69a8278c7da", :artist)
      #=> {:ok, "5b11f4ce-a62d-471e-81fc-a69a8278c7da"}

      # From entity map (self-referential)
      extract_mbid(%{"id" => "abc123", "name" => "..."}, :artist)
      #=> {:ok, "abc123"}

      # From release map to get artist
      extract_mbid(%{"artist-credit" => [%{"artist" => %{"id" => "xyz"}}]}, :artist)
      #=> {:ok, "xyz"}
  """
  @spec extract_mbid(String.t() | map(), atom()) :: {:ok, String.t()} | {:error, :cannot_extract}

  # String MBID - pass through for any target type
  def extract_mbid(mbid, _target_type) when is_binary(mbid) do
    {:ok, mbid}
  end

  # Extract own ID (when source entity matches target type)
  def extract_mbid(%{"id" => id}, _target_type) when is_binary(id) do
    {:ok, id}
  end

  # Extract artist from artist-credit (found in Release, Recording, ReleaseGroup)
  def extract_mbid(%{"artist-credit" => [%{"artist" => %{"id" => id}} | _]}, :artist) do
    {:ok, id}
  end

  # Extract release-group from release
  def extract_mbid(%{"release-group" => %{"id" => id}}, :release_group) do
    {:ok, id}
  end

  # Extract area from various entity types
  def extract_mbid(%{"area" => %{"id" => id}}, :area) do
    {:ok, id}
  end

  def extract_mbid(%{"begin-area" => %{"id" => id}}, :area) do
    {:ok, id}
  end

  # Extract area from release-events (in Release entities)
  def extract_mbid(%{"release-events" => [%{"area" => %{"id" => id}} | _]}, :area) do
    {:ok, id}
  end

  # Extract place from event
  def extract_mbid(%{"cancelled" => _} = event_map, :place) do
    # Events may have place references in relations
    case event_map do
      %{"relations" => relations} when is_list(relations) ->
        Enum.find_value(relations, {:error, :cannot_extract}, fn
          %{"type" => "held at", "place" => %{"id" => id}} -> {:ok, id}
          %{"type" => "held in", "place" => %{"id" => id}} -> {:ok, id}
          _ -> nil
        end)

      _ ->
        {:error, :cannot_extract}
    end
  end

  # Extract work from recording (recordings link to works)
  def extract_mbid(%{"length" => _, "video" => _} = recording_map, :work) do
    case recording_map do
      %{"relations" => relations} when is_list(relations) ->
        Enum.find_value(relations, {:error, :cannot_extract}, fn
          %{"type" => "performance", "work" => %{"id" => id}} -> {:ok, id}
          _ -> nil
        end)

      _ ->
        {:error, :cannot_extract}
    end
  end

  # Fallback - could not extract
  def extract_mbid(_source, _target_type) do
    {:error, :cannot_extract}
  end

  @doc """
  Detects the entity type of a MusicBrainz API response map.

  Uses field presence and values to determine what type of entity this is.

  ## Returns

  - `{:ok, entity_type}` - Successfully identified entity type
  - `{:error, :unknown_entity}` - Could not determine entity type

  ## Examples

      detect_entity_type(%{"type" => "Group", "sort-name" => "...", "life-span" => %{}})
      #=> {:ok, :artist}

      detect_entity_type(%{"primary-type" => "Album", "secondary-types" => []})
      #=> {:ok, :release_group}
  """
  @spec detect_entity_type(map()) :: {:ok, atom()} | {:error, :unknown_entity}

  # Artist: has type in ["Group", "Person"] and life-span
  def detect_entity_type(%{"type" => type, "life-span" => _})
      when type in ["Group", "Person"] do
    {:ok, :artist}
  end

  # Release: has barcode, packaging, and status
  def detect_entity_type(%{"status" => _, "packaging" => _}) do
    {:ok, :release}
  end

  # Alternative release detection: has status-id and release-events
  def detect_entity_type(%{"status-id" => _, "release-events" => _}) do
    {:ok, :release}
  end

  # Recording: has length (number) and video (boolean)
  def detect_entity_type(%{"length" => length, "video" => _}) when is_number(length) do
    {:ok, :recording}
  end

  # Release Group: has primary-type and secondary-types
  def detect_entity_type(%{"primary-type" => _, "secondary-types" => _}) do
    {:ok, :release_group}
  end

  # Label: has label-code
  def detect_entity_type(%{"label-code" => _}) do
    {:ok, :label}
  end

  # Area: has iso-3166-1-codes
  def detect_entity_type(%{"iso-3166-1-codes" => _}) do
    {:ok, :area}
  end

  # Event: has cancelled (boolean) and typically life-span with specific dates
  def detect_entity_type(%{"cancelled" => cancelled}) when is_boolean(cancelled) do
    {:ok, :event}
  end

  # Place: has coordinates with latitude and longitude
  def detect_entity_type(%{"coordinates" => %{"latitude" => _, "longitude" => _}}) do
    {:ok, :place}
  end

  # Work: has iswcs (array of International Standard Musical Work Codes)
  def detect_entity_type(%{"iswcs" => iswcs}) when is_list(iswcs) do
    {:ok, :work}
  end

  # Work alternative: has languages array (works can have multiple languages)
  def detect_entity_type(%{"languages" => langs, "title" => _}) when is_list(langs) do
    {:ok, :work}
  end

  # Series: has type field with series-specific types
  # Note: Series are context-dependent and may need type checking
  def detect_entity_type(%{"type" => type})
      when type in [
             "Release group series",
             "Release series",
             "Recording series",
             "Work series",
             "Catalogue series",
             "Event series"
           ] do
    {:ok, :series}
  end

  # Genre and Instrument: Very similar simple structures
  # These are difficult to distinguish without context
  # They only have: id, name, disambiguation
  # Detection will rely on calling context in most cases

  # URL: Typically a string representation
  # Detection relies on context as URLs don't have a standard entity structure

  # Fallback - unknown entity type
  def detect_entity_type(_map) do
    {:error, :unknown_entity}
  end
end

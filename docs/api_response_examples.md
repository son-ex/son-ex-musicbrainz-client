# MusicBrainz API Response Examples

This document contains real API response examples collected from the MusicBrainz API.
These are used as reference for pattern matching and MBID extraction logic.

**Note**: All requests made with 1 second delays to respect rate limits.

---

## Artist

### Basic Artist Lookup
**Request**: `GET /ws/2/artist/5b11f4ce-a62d-471e-81fc-a69a8278c7da`

```json
{
  "isnis": ["0000000123486830", "0000000123487390"],
  "gender": null,
  "sort-name": "Nirvana",
  "id": "5b11f4ce-a62d-471e-81fc-a69a8278c7da",
  "type": "Group",
  "gender-id": null,
  "end-area": null,
  "ipis": [],
  "begin-area": {
    "type-id": null,
    "type": null,
    "sort-name": "Aberdeen",
    "id": "a640b45c-c173-49b1-8030-973603e895b5",
    "name": "Aberdeen",
    "disambiguation": ""
  },
  "disambiguation": "1980s–1990s US grunge band",
  "country": "US",
  "type-id": "e431f5f6-b5d2-343d-8b36-72607fffb74b",
  "life-span": {
    "ended": true,
    "end": "1994-04-05",
    "begin": "1987"
  },
  "name": "Nirvana",
  "area": {
    "type-id": null,
    "name": "United States",
    "id": "489ce91b-6658-3307-9877-795b68554c98",
    "type": null,
    "iso-3166-1-codes": ["US"],
    "disambiguation": "",
    "sort-name": "United States"
  }
}
```

**Key Fields for Pattern Matching**:
- `type` ∈ ["Group", "Person"] - distinguishes artists from other entities
- `sort-name` - present in artists
- `life-span` - specific to artists
- `begin-area`, `area` - contain nested area entities with `id` (MBID)

---

## Release

### Basic Release Lookup
**Request**: `GET /ws/2/release/76df3287-6cda-33eb-8e9a-044b5e15ffdd`

```json
{
  "quality": "normal",
  "packaging-id": "ec27701a-4a22-37f4-bfac-6616e0f9750a",
  "status-id": "4e304316-386d-3409-af2e-78857eec5cfe",
  "date": "1994-08-22",
  "id": "76df3287-6cda-33eb-8e9a-044b5e15ffdd",
  "barcode": "042282855329",
  "text-representation": {
    "language": "eng",
    "script": "Latn"
  },
  "disambiguation": "",
  "release-events": [
    {
      "date": "1994-08-22",
      "area": {
        "type": null,
        "type-id": null,
        "name": "Europe",
        "id": "89a675c2-3e37-3518-b83c-418bad59a85a",
        "iso-3166-1-codes": ["XE"],
        "disambiguation": "",
        "sort-name": "Europe"
      }
    }
  ],
  "status": "Official",
  "title": "Dummy",
  "asin": "B000001FI7",
  "country": "XE",
  "cover-art-archive": {
    "front": true,
    "count": 6,
    "back": true,
    "artwork": true,
    "darkened": false
  },
  "packaging": "Jewel Case"
}
```

### Release with Artist Credits
**Request**: `GET /ws/2/release/76df3287-6cda-33eb-8e9a-044b5e15ffdd?inc=artist-credits`

```json
{
  "country": "XE",
  "cover-art-archive": {
    "back": true,
    "darkened": false,
    "artwork": true,
    "count": 6,
    "front": true
  },
  "artist-credit": [
    {
      "name": "Portishead",
      "artist": {
        "sort-name": "Portishead",
        "type": "Group",
        "id": "8f6bd1e4-fbe1-4f50-aa9b-94c450ec0f11",
        "type-id": "e431f5f6-b5d2-343d-8b36-72607fffb74b",
        "disambiguation": "",
        "name": "Portishead",
        "country": "GB"
      },
      "joinphrase": ""
    }
  ],
  "title": "Dummy",
  "date": "1994-08-22",
  "id": "76df3287-6cda-33eb-8e9a-044b5e15ffdd",
  "status-id": "4e304316-386d-3409-af2e-78857eec5cfe",
  "barcode": "042282855329",
  "packaging-id": "ec27701a-4a22-37f4-bfac-6616e0f9750a",
  "quality": "normal",
  "disambiguation": "",
  "status": "Official",
  "asin": "B000001FI7",
  "release-events": [
    {
      "date": "1994-08-22",
      "area": {
        "disambiguation": "",
        "name": "Europe",
        "sort-name": "Europe",
        "type": null,
        "iso-3166-1-codes": ["XE"],
        "type-id": null,
        "id": "89a675c2-3e37-3518-b83c-418bad59a85a"
      }
    }
  ],
  "packaging": "Jewel Case",
  "text-representation": {
    "language": "eng",
    "script": "Latn"
  }
}
```

**Key Fields for Pattern Matching**:
- `title` + `barcode` + `packaging` - distinguishes releases
- `status` ∈ ["Official", ...] - release-specific
- `artist-credit` - array containing artist MBID at `[0]["artist"]["id"]`
- `release-events` - contains area entities

---

## Recording

### Recording with Artist Credits
**Request**: `GET /ws/2/recording/b1a9c0e9-d987-4042-ae91-78d6a3267d69?inc=artist-credits`

```json
{
  "disambiguation": "",
  "first-release-date": "1975-11-21",
  "title": "Bohemian Rhapsody",
  "artist-credit": [
    {
      "joinphrase": "",
      "artist": {
        "disambiguation": "UK rock group",
        "sort-name": "Queen",
        "id": "0383dadf-2a4e-4d10-a46a-e9e041da8eb3",
        "type": "Group",
        "type-id": "e431f5f6-b5d2-343d-8b36-72607fffb74b",
        "country": "GB",
        "name": "Queen"
      },
      "name": "Queen"
    }
  ],
  "video": false,
  "id": "b1a9c0e9-d987-4042-ae91-78d6a3267d69",
  "length": 355106
}
```

**Key Fields for Pattern Matching**:
- `length` (number in milliseconds) - specific to recordings
- `video` (boolean) - specific to recordings
- `first-release-date` - specific to recordings
- `artist-credit` - array containing artist MBID at `[0]["artist"]["id"]`

---

## Release Group

### Release Group with Artist Credits
**Request**: `GET /ws/2/release-group/1b022e01-4da6-387b-8658-8678046e4cef?inc=artist-credits`

```json
{
  "artist-credit": [
    {
      "name": "Nirvana",
      "artist": {
        "disambiguation": "1980s–1990s US grunge band",
        "type-id": "e431f5f6-b5d2-343d-8b36-72607fffb74b",
        "id": "5b11f4ce-a62d-471e-81fc-a69a8278c7da",
        "name": "Nirvana",
        "type": "Group",
        "country": "US",
        "sort-name": "Nirvana"
      },
      "joinphrase": ""
    }
  ],
  "id": "1b022e01-4da6-387b-8658-8678046e4cef",
  "secondary-type-ids": [],
  "disambiguation": "",
  "first-release-date": "1991-09-24",
  "title": "Nevermind",
  "secondary-types": [],
  "primary-type": "Album",
  "primary-type-id": "f529b476-6e62-324f-b0aa-1f3e33d313fc"
}
```

**Key Fields for Pattern Matching**:
- `primary-type` ∈ ["Album", "Single", "EP", ...] - specific to release groups
- `secondary-types` (array) - specific to release groups
- `first-release-date` - present in release groups
- `artist-credit` - array containing artist MBID at `[0]["artist"]["id"]`

---

## Label

### Basic Label Lookup
**Request**: `GET /ws/2/label/46f0f4cd-8aab-4b33-b698-f459faf64190`

```json
{
  "type": "Original Production",
  "country": "GB",
  "name": "Warp",
  "ipis": [],
  "area": {
    "disambiguation": "",
    "iso-3166-1-codes": ["GB"],
    "sort-name": "United Kingdom",
    "id": "8a754a16-0027-3a29-b6d7-2b40ea0481ed",
    "type": null,
    "type-id": null,
    "name": "United Kingdom"
  },
  "disambiguation": "UK independent label",
  "isnis": ["0000000107280584"],
  "type-id": "7aaa37fe-2def-3476-b359-80245850062d",
  "life-span": {
    "end": null,
    "ended": false,
    "begin": "1989-07"
  },
  "id": "46f0f4cd-8aab-4b33-b698-f459faf64190",
  "sort-name": "Warp",
  "label-code": 2070
}
```

**Key Fields for Pattern Matching**:
- `label-code` (number) - unique to labels
- `type` ∈ ["Original Production", "Distributor", ...] - label types
- `area` - contains area MBID

---

## Pattern Matching Strategy

### Entity Type Detection

Based on the responses, here's how to detect entity types:

```elixir
# Artist: has life-span and sort-name, type in ["Group", "Person"]
%{"type" => type, "sort-name" => _, "life-span" => _} when type in ["Group", "Person"]

# Release: has barcode, packaging, status
%{"barcode" => _, "packaging" => _, "status" => _}

# Recording: has length (number), video (boolean)
%{"length" => length, "video" => _} when is_number(length)

# Release Group: has primary-type, secondary-types
%{"primary-type" => _, "secondary-types" => _}

# Label: has label-code
%{"label-code" => _}
```

### MBID Extraction Patterns

```elixir
# Direct ID
%{"id" => id} -> id

# Artist from artist-credit (Release, Recording, ReleaseGroup)
%{"artist-credit" => [%{"artist" => %{"id" => id}} | _]} -> id

# Area from various entities
%{"area" => %{"id" => id}} -> id
%{"begin-area" => %{"id" => id}} -> id
%{"release-events" => [%{"area" => %{"id" => id}} | _]} -> id
```

---

## Event

### Basic Event Lookup
**Request**: `GET /ws/2/event/44a5fcdf-64bb-45f1-b135-e712906ccd83`

```json
{
  "type": "Concert",
  "name": "[concert]",
  "type-id": "ef55e8d7-3d00-394a-8012-f5506a29ff0b",
  "cancelled": false,
  "setlist": "* [fd08127f-2cca-411b-a806-dab4029d3c5c|Waltz From Delibes' Coppélia] (Delibes, arr. Dohnányi) (world premiere)",
  "time": "",
  "life-span": {
    "ended": true,
    "begin": "1926-11-29",
    "end": "1926-11-29"
  },
  "id": "44a5fcdf-64bb-45f1-b135-e712906ccd83",
  "disambiguation": ""
}
```

**Key Fields for Pattern Matching**:
- `cancelled` (boolean) - specific to events
- `setlist` - event-specific field
- `time` - time of event
- Has `life-span` like artist but with specific date ranges

---

## Place

### Basic Place Lookup
**Request**: `GET /ws/2/place/83f61216-b806-4d2d-8a4e-7f960f30c280`

```json
{
  "life-span": {
    "begin": "2006-07-22",
    "end": null,
    "ended": false
  },
  "id": "83f61216-b806-4d2d-8a4e-7f960f30c280",
  "disambiguation": "",
  "type": "Stadium",
  "name": "Emirates Stadium",
  "coordinates": {
    "longitude": -0.108611,
    "latitude": 51.555
  },
  "type-id": "62664fbd-cd55-3b5f-a5ea-fb5d1bc0113c",
  "address": "Holloway, London, N5 England",
  "area": {
    "type-id": null,
    "disambiguation": "Greater London",
    "id": "f03d09b3-39dc-4083-afd6-159e3f0d462f",
    "sort-name": "London",
    "type": null,
    "name": "London"
  }
}
```

**Key Fields for Pattern Matching**:
- `coordinates` - unique to places (contains `latitude` and `longitude`)
- `address` - place-specific
- `area` - contains area entity with MBID

---

## Work

### Basic Work Lookup
**Request**: `GET /ws/2/work/41c94a08-a551-3c86-bb17-d9a52e3a618b`

```json
{
  "attributes": [...],
  "type-id": "f061270a-2fd6-32f1-a641-f0f8676d14e6",
  "type": "Song",
  "id": "41c94a08-a551-3c86-bb17-d9a52e3a618b",
  "languages": ["eng"],
  "title": "Bohemian Rhapsody",
  "language": "eng",
  "iswcs": ["T-010.154.505-4", "T-304.031.869-8", "T-900.313.996-6"],
  "disambiguation": ""
}
```

**Key Fields for Pattern Matching**:
- `iswcs` (array) - International Standard Musical Work Code, specific to works
- `languages` (array) - work-specific
- `attributes` (array) - work attributes like GEMA ID, JASRAC ID, etc.
- Has `title` (not `name`)

---

## Genre

### Basic Genre Lookup
**Request**: `GET /ws/2/genre/54c01942-22fd-4184-9877-1db0089b18f1`

```json
{
  "disambiguation": "",
  "name": "acid house",
  "id": "54c01942-22fd-4184-9877-1db0089b18f1"
}
```

**Key Fields for Pattern Matching**:
- Very simple structure: just `id`, `name`, `disambiguation`
- No unique discriminating fields - will need context-based detection

---

## Notes

- All entities have an `id` field (MBID)
- The `artist-credit` pattern is consistent across Release, Recording, and ReleaseGroup
- Many entities have nested area references that contain MBIDs
- The API uses hyphenated keys (`artist-credit`, `release-events`, etc.)

### Entity Discrimination Strategy

**Entities with unique discriminators**:
- Artist: `life-span` + `type` in ["Group", "Person"]
- Release: `barcode` + `packaging` + `status`
- Recording: `length` (number) + `video` (boolean)
- Release Group: `primary-type` + `secondary-types`
- Label: `label-code` (number)
- Event: `cancelled` (boolean) + `setlist`
- Place: `coordinates` (with `latitude` and `longitude`)
- Work: `iswcs` (array)
- Area: `iso-3166-1-codes` (array)

**Entities requiring context** (no unique fields):
- Genre: Simple structure (id + name + disambiguation)
- Instrument: Similar simple structure
- Series: Requires type context
- URL: String-based, requires context

For context-dependent entities, pattern matching will use a combination of:
1. Field presence
2. Calling context (which function was called)
3. Type hints from related entities

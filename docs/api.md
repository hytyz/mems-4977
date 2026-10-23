# REST API Reference

Base URL (Azure): `https://mems-assignment-app.azurewebsites.net`

All requests and responses are `application/json` with **camelCase** property
names. Protected endpoints require:

```
Authorization: Bearer <jwt-token>
```

Errors are RFC 7807 `ProblemDetails`:

```json
{ "type": "...", "title": "...", "status": 400, "detail": "...", "traceId": "..." }
```

Model-validation failures (400) additionally include
`"errors": { "Field": ["Message"] }`.

## Endpoints

| Method | Path | Auth | Description |
| ------ | ---- | ---- | ----------- |
| POST | `/api/auth/register` | no | Create an account and return a JWT |
| POST | `/api/auth/login` | no | Authenticate and return a JWT |
| GET | `/api/municipalities` | no | All municipalities |
| GET | `/api/municipalities/{id}` | no | Municipality details + positions |
| GET | `/api/positions` | no | All positions |
| GET | `/api/positions/{id}` | no | Position details + candidates |
| GET | `/api/candidates` | no | All candidates |
| GET | `/api/candidates/{id}` | no | One candidate |
| GET | `/api/candidates/search?name=` | no | Case-insensitive name search |
| GET | `/api/savedcandidates` | yes | The caller's voting guide |
| POST | `/api/savedcandidates` | yes | Save a candidate to the guide |
| DELETE | `/api/savedcandidates/{id}` | yes | Remove a saved candidate |

## Authentication

### `POST /api/auth/register`

```json
{ "fullName": "Test User", "email": "test@example.com", "password": "secret1" }
```

Rules: `fullName` required, 2–100 characters, not whitespace-only; `email`
required and valid; `password` required, 6–100 characters.

`200 OK`

```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "email": "test@example.com",
  "fullName": "Test User"
}
```

`400 Bad Request` — validation error (e.g. duplicate email, blank name, short
password), with an `errors` object.

### `POST /api/auth/login`

```json
{ "email": "test@example.com", "password": "secret1" }
```

`200 OK` — same shape as register. `401 Unauthorized` — invalid credentials.

The JWT is HS256-signed, issuer `MunicipalElections`, audience
`MunicipalElectionsApp`, valid for 7 days, and carries the user id
(`nameidentifier`), email, and display name.

## Municipalities

### `GET /api/municipalities`

```json
[
  {
    "id": 1,
    "name": "Pitt Meadows",
    "province": "British Columbia",
    "electionDate": "2026-10-17T00:00:00Z",
    "description": "A family-friendly community where the mountains meet the Fraser River.",
    "logoUrl": "/uploads/municipalities/pitt-meadows.png"
  }
]
```

### `GET /api/municipalities/{id}`

```json
{
  "id": 1,
  "name": "Pitt Meadows",
  "province": "British Columbia",
  "electionDate": "2026-10-17T00:00:00Z",
  "description": "...",
  "logoUrl": "/uploads/municipalities/pitt-meadows.png",
  "positions": [
    { "id": 1, "name": "Mayor", "seatsAvailable": 1, "municipalityId": 1 }
  ]
}
```

`404 Not Found` if the id does not exist.

## Positions

### `GET /api/positions`

```json
[ { "id": 1, "name": "Mayor", "seatsAvailable": 1, "municipalityId": 1 } ]
```

### `GET /api/positions/{id}`

```json
{
  "id": 1,
  "name": "Mayor",
  "seatsAvailable": 1,
  "municipalityId": 1,
  "candidates": [
    {
      "id": 1,
      "name": "Jordan Lee",
      "biography": "Jordan has served on council for eight years...",
      "photoUrl": "/uploads/candidates/jordan-lee.png",
      "website": "https://jordanlee.example.com",
      "email": "jordan.lee@example.com",
      "positionId": 1,
      "municipalityId": 1
    }
  ]
}
```

## Candidates

### `GET /api/candidates`

```json
[
  {
    "id": 1,
    "name": "Jordan Lee",
    "biography": "Jordan has served on council for eight years...",
    "photoUrl": "/uploads/candidates/jordan-lee.png",
    "website": "https://jordanlee.example.com",
    "email": "jordan.lee@example.com",
    "positionId": 1,
    "municipalityId": 1
  }
]
```

`biography`, `photoUrl`, `website` and `email` may be `null`.

### `GET /api/candidates/{id}`

One candidate object as above. `404 Not Found` if missing.

### `GET /api/candidates/search?name=lee`

Same array shape, filtered by case-insensitive substring match on the name.
An empty or missing `name` returns all candidates.

## Voting guide (authenticated)

### `GET /api/savedcandidates`

Newest first. The embedded candidate is the full candidate object.

```json
[
  {
    "id": 1,
    "candidateId": 1,
    "dateSaved": "2026-10-23T06:45:02.130865Z",
    "candidate": { "id": 1, "name": "Jordan Lee", "...": "..." }
  }
]
```

`401 Unauthorized` without a valid bearer token.

### `POST /api/savedcandidates`

```json
{ "candidateId": 1 }
```

`201 Created`

```json
{ "id": 1, "candidateId": 1, "dateSaved": "2026-10-23T06:45:02.130865Z" }
```

`409 Conflict` if the caller already saved that candidate; `404 Not Found` if
the candidate does not exist; `400` if `candidateId` is missing or not a
positive integer.

### `DELETE /api/savedcandidates/{id}`

`204 No Content` on success. `404 Not Found` if the row does not exist or
belongs to another user.

## Seed data available to clients

- 4 municipalities (Pitt Meadows, Maple Ridge, Burnaby, Surrey), each with a
  logo.
- 3 positions per municipality (Mayor, Councillor, School Trustee).
- 12 candidates across all municipalities and position types, each with a
  biography and photo.
- Demo accounts: `super@municipal.local` and `pm@municipal.local`, password
  `P@$$w0rd` (created only when the database is first seeded).

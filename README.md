# Municipal Elections

COMP4977 project workspace containing two assignments that coexist in one
repository:

1. **Municipal Elections Management System** (previous assignment) — the
   ASP.NET Core MVC web app in `src/MunicipalElections`, with cookie-based
   Identity auth, an admin area, and a session-based personal voting guide.
2. **Municipal Elections Companion** (current assignment, COMP4977 iOS #1) —
   two additive layers:
   - A **JWT REST API** added to the same ASP.NET Core project
     (`Controllers/Api/`, `Auth/JwtTokenService.cs`, `DTOs/Api/`,
     `Models/SavedCandidate.cs`, migration `20261015205555_AddSavedCandidates`).
     The MVC app is untouched: camelCase JSON and a JwtBearer scheme were
     registered additively, and the Identity cookie remains the *default*
     authentication scheme, so all MVC pages keep working exactly as before.
   - A **SwiftUI iOS app** in `frontend/MunicipalCompanion` (Swift Package,
     MVVM, iOS 16+, zero third-party dependencies), built and deployed to a
     physical iPhone with xtool.

**Deployed API:** <https://mems-assignment-app.azurewebsites.net>

**Repository:** <https://github.com/hytyz/mems-4977>

## Repository layout

```
├── src/MunicipalElections/           ASP.NET Core 10 MVC app + REST API (one project)
│   ├── Controllers/                  MVC controllers (previous assignment)
│   ├── Controllers/Api/              REST API controllers (Auth, Municipalities,
│   │                                 Positions, Candidates, SavedCandidates)
│   ├── Auth/JwtTokenService.cs       JWT issuance
│   ├── DTOs/Api/                     request DTOs (DataAnnotations) + mappers
│   ├── Models/SavedCandidate.cs      voting-guide entity (unique (UserId, CandidateId) index)
│   ├── Data/DbInitializer.cs         idempotent seeding + migrations on startup
│   ├── Data/Migrations/..._AddSavedCandidates.cs
│   └── wwwroot/uploads/              seeded placeholder logos and photos
├── frontend/MunicipalCompanion/      SwiftUI iOS app (Swift Package, MVVM)
├── Containerfile                     .NET dev container (previous assignment)
├── scripts/run.sh                    build container and run backend on port 5000
├── scripts/dotnet.sh                 run dotnet / dotnet-ef inside the dev container
└── docs/                             architecture diagram, ERD, API reference, screenshots
```

## Backend quick start

All local development runs inside Podman containers (the host has no .NET SDK).

```sh
# Build the dev container image and run the app (dotnet watch) on port 5000.
./scripts/run.sh

# Or run one-off dotnet / dotnet-ef commands:
./scripts/dotnet.sh build
./scripts/dotnet.sh ef migrations list
```

The app then serves at `http://localhost:5000` (host port 5000 → container
8080). The SQLite database is migrated and seeded at startup. Seeding is
**idempotent**: on every start it adds anything that is missing rather than
skipping existing data.

Seed data:

- Municipalities: **Pitt Meadows, Maple Ridge, Burnaby** (plus Surrey) — each
  with a logo.
- Positions per municipality: **Mayor** (1 seat), **Councillor** (6), **School
  Trustee** (2).
- **12 candidates** spread across all three position types and all
  municipalities (assignment minimum: 10), each with a biography, photo, and
  most with contact details.
- Two Identity users: `super` (SuperAdmin) and `pm` (MunicipalityAdmin), with
  password `P@$$w0rd` **only on first creation** — an existing account's
  password is never reset on restart.

## REST API

JSON is camelCase everywhere. Errors are RFC 7807 problem-details objects.
Request DTOs carry DataAnnotations (`[Required]`, `[EmailAddress]`,
`[StringLength]`, `[Range]`), so invalid input returns 400 ValidationProblemDetails
regardless of client.

Full reference with request/response examples: [`docs/api.md`](docs/api.md).

### Auth flow

- `POST /api/auth/register` with `{fullName, email, password}` returns
  `{token, email, fullName}`. A blank/whitespace name, invalid email, or a
  password shorter than 6 characters is rejected with 400.
- `POST /api/auth/login` with `{email, password}` returns the same shape;
  bad credentials return 401 (problem-details).
- The token is a signed JWT (issuer `MunicipalElections`, audience
  `MunicipalElectionsApp`, 7-day expiry, HS256 key from the `Jwt` section of
  `appsettings.json`).
- Send it on protected endpoints as `Authorization: Bearer <token>`. The
  Identity cookie scheme is unchanged and only applies to MVC pages; API
  controllers opt into the JWT scheme explicitly.

### Endpoints

| Method | Path | Auth | Notes |
| ------ | ---- | ---- | ----- |
| POST | `/api/auth/register` | no | `{fullName,email,password}` → `{token,email,fullName}`; 400 on validation errors |
| POST | `/api/auth/login` | no | `{email,password}` → `{token,email,fullName}`; 401 on bad credentials |
| GET | `/api/municipalities` | no | all municipalities |
| GET | `/api/municipalities/{id}` | no | municipality + `positions[]` |
| GET | `/api/positions` | no | all positions |
| GET | `/api/positions/{id}` | no | position + `candidates[]` |
| GET | `/api/candidates` | no | all candidates |
| GET | `/api/candidates/{id}` | no | single candidate |
| GET | `/api/candidates/search?name=` | no | case-insensitive name search |
| GET | `/api/savedcandidates` | yes | the user's saved candidates, newest first |
| GET | `/api/savedcandidates/{id}` | yes | one saved row; 404 if not owned by the caller |
| POST | `/api/savedcandidates` | yes | `{candidateId}` → 201 `{id,candidateId,dateSaved}`; 409 if already saved; 404 unknown candidate |
| DELETE | `/api/savedcandidates/{id}` | yes | 204; 404 if not owned by the caller |

### Smoke-testing with curl

```sh
# Register (or login instead) and grab the token.
curl -s -X POST http://localhost:5000/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"fullName":"Test User","email":"test@example.com","password":"secret1"}'
TOKEN=<copy "token" from the response>

# Public endpoints.
curl -s http://localhost:5000/api/municipalities
curl -s http://localhost:5000/api/candidates/1
curl -s 'http://localhost:5000/api/candidates/search?name=smith'

# Validation is server-side too (400 with an "errors" object).
curl -s -X POST http://localhost:5000/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"fullName":"   ","email":"not-an-email","password":"1"}'

# Bearer-protected voting guide.
curl -s -X POST http://localhost:5000/api/savedcandidates \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"candidateId":1}'          # 201; repeat → 409; unknown id → 404
curl -s http://localhost:5000/api/savedcandidates -H "Authorization: Bearer $TOKEN"
curl -s -o /dev/null -w '%{http_code}\n' -X DELETE \
  http://localhost:5000/api/savedcandidates/1 -H "Authorization: Bearer $TOKEN"  # 204

# MVC pages still serve with cookie auth (unchanged).
curl -sI http://localhost:5000/ | head -1
```

## iOS app (frontend/MunicipalCompanion)

SwiftUI app consuming the API above. MVVM layout:

- `Models/` — Codable structs matching the API payloads, ISO-8601 JSON coding.
- `Services/` — `ApiService` (URLSession + async/await, automatic bearer
  injection, problem-details parsing), `AuthManager` + `KeychainTokenStore`
  (JWT persisted in the Keychain), `ApiError`.
- `ViewModels/` — 5 observable view-models driving UI state.
- `Views/` — Login, Registration, Municipalities, MunicipalityDetail /
  PositionDetail, CandidateDirectory (`.searchable` + municipality/position
  filters; rows show photo, name, position and municipality), CandidateDetail
  (biography, photo, website, email, "Add to Voting Guide"), VotingGuide,
  Profile, behind a `RootView` `TabView` gated on authentication.
- `Support/` — `AppConfig` (API base URL), utilities.

The API base URL is read from the `.env` file shipped in the app bundle
(`API_BASE_URL`, currently the Azure deployment) and can be overridden per
session on the **Profile** tab. See `frontend/MunicipalCompanion/README.md` for
the full architecture and packaging notes.

## Building and running the iOS app on this machine

xtool 1.22.2 is installed with the Darwin SDK already generated, and an iPhone
is paired. From `frontend/MunicipalCompanion`:

```sh
xtool dev build        # compile for iOS -> ./xtool/MunicipalCompanion.app
xtool dev run          # install + launch on the connected device
```

If `xtool dev` reports "Failed to obtain Swift version", the Swift toolchain
is managed by swiftly — source `~/.local/share/swiftly/env.sh` first (or add
it to your bash profile).

## Testing on macOS (simulator)

```sh
cd frontend/MunicipalCompanion
xtool dev                    # builds, boots an iOS simulator, installs, live-syncs
```

or, for IDE work:

```sh
xtool dev generate-xcode-project
open MunicipalCompanion.xcodeproj
```

Do not just `open Package.swift` — the package exposes a library product
(required by xtool), so a plain SwiftPM scheme has no runnable app.

## Deploying the API to Azure

The API runs on App Service `mems-assignment-app` (`mems-assignment-rg`,
Linux, .NET 10):

```sh
./scripts/dotnet.sh publish src/MunicipalElections -c Release -o /tmp/publish
(cd /tmp/publish && rm -f appsettings.Development.json && zip -qr /tmp/app.zip .)
az webapp deploy -g mems-assignment-rg -n mems-assignment-app \
  --src-path /tmp/app.zip --type zip
```

The SQLite file lives beside the app (`wwwroot`), so a zip deploy recreates
and reseeds it. For durable data, point `DefaultConnection` at App Service
persistent storage (`/home/...`) or Azure SQL.

## Documentation

- [`docs/architecture.md`](docs/architecture.md) — system architecture diagram (Mermaid).
- [`docs/erd.md`](docs/erd.md) — database ERD including `SavedCandidate` (Mermaid).
- [`docs/api.md`](docs/api.md) — endpoint reference with examples.
- [`docs/screenshots/`](docs/screenshots) — web application screenshots from
  the previous assignment.
- [`docs/screenshots/ios/`](docs/screenshots/ios) — Municipal Elections
  Companion screens: login, registration validation, municipalities,
  directory, search and filters, candidate detail, save confirmation, voting
  guide, removal, and profile.
- Azure evidence: [`azure-app-service-overview.png`](docs/screenshots/azure-app-service-overview.png)
  (App Service running on .NET 10),
  [`azure-api-candidates.png`](docs/screenshots/azure-api-candidates.png) and
  [`azure-api-municipalities.png`](docs/screenshots/azure-api-municipalities.png)
  (live deployed API responses).

## Known limitations

- **Relative image URLs**: the API returns photo/logo paths as relative URLs
  (`/uploads/...`); the app resolves them against the configured base URL
  (`mediaURL(from:)`) before loading.
- **Signing key**: the JWT key sits in `appsettings.json` for this assignment;
  in a real deployment it belongs in a secret store.
- **Seeded admin credentials**: `super`/`pm` use a known password for marking
  purposes and are only created if missing; their passwords are not reset on
  startup. Do not reuse this seeding pattern for a real administration system.

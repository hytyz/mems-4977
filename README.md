# Municipal Elections Companion

COMP4977 Assignment 2. A SwiftUI app for iPhone and iPad backed by an
ASP.NET Core Web API on Azure (login, election data filtered by municipality)
and Firebase Firestore (the user's municipality and candidate selections).

- **Azure API:** <https://mems-assignment-app.azurewebsites.net>
- **Repository:** <https://github.com/hytyz/mems-4977>
- **Firebase project:** `mems4977`
- **Report:** [`docs/assignment2-report.pdf`](docs/assignment2-report.pdf)

## Layout

```
src/MunicipalElections/        ASP.NET Core 10 Web API (+ the MVC site from the earlier assignment)
frontend/MunicipalCompanion/   SwiftUI app: Xcode project, MVVM sources, Firebase config
firebase/                      Firestore security rules and their emulator tests
docs/                          report PDF and screenshots
.github/workflows/build.yml    CI: API build, rules tests, iOS simulator build
```

## Run the API

Requires the .NET 10 SDK. The SQLite database is migrated and seeded on startup.

```sh
dotnet run --project src/MunicipalElections --urls http://localhost:5000
```

Firebase custom tokens (`GET /api/auth/firebase-token`) need the Firebase
service account in the `Firebase__ServiceAccountJson` setting. It is set on
Azure and must never be committed.

Election endpoints require a municipality, for example
`/api/candidates?city=Burnaby`, and return 400 without one.

## Run the app

Open `frontend/MunicipalCompanion/MunicipalCompanion.xcodeproj` in Xcode,
select the **MunicipalCompanion** scheme and run it on an iPhone 16 or iPad Air
simulator. The app talks to the Azure API (set in `.env`) and to the
`mems4977` Firebase project (`GoogleService-Info.plist`).

Demo accounts on the Azure API: `alex.voter@example.com` / `secret1`.

## Firebase

The Firestore security rules are in `firebase/firestore.rules`; collections
are described in the report. To test the rules (needs Node and Java 11+):

```sh
cd firebase && npm install && npm test
```

## Deploy the API

```sh
dotnet publish src/MunicipalElections -c Release -o publish
cd publish && zip -qr ../app.zip . && cd ..
az webapp deploy -g mems-assignment-rg -n mems-assignment-app --src-path app.zip --type zip
```

A deploy recreates the SQLite database from the seed data.

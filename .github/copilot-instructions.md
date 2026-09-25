# Copilot Instructions

## Project
Municipal Elections Management System (ASP.NET Core MVC + EF Core + SQLite + Identity).

## Conventions
- Use file-scoped namespaces and C# 12+ language features.
- Target .NET 10, nullable enabled, implicit usings.
- Follow MVC areas for admin functionality; public features live in root controllers.
- Keep Code First as the source of truth: change models, generate migrations with `dotnet ef`.
- Run builds and migrations with the .NET 10 SDK (`dotnet build`, `dotnet ef`); EF tools are pinned in `src/MunicipalElections/dotnet-tools.json` (`dotnet tool restore`).
- Use data annotations plus fluent configuration for validation and constraints.

## Authorization rules
- `SuperAdmin` role: system-wide access and municipality management.
- `MunicipalityAdmin` role: scoped to municipalities via the `MunicipalityAdmin` join table.
- Enforce access with `MunicipalityAccessService`; never trust client-supplied entity ids.

## UI/style
- Bootstrap 5 responsive design; support dark mode via `data-bs-theme`.
- Client-side and server-side validation on all forms.

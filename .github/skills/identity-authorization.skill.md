# Skill: Identity Roles and Municipality-Scoped Authorization

## When to use
Adding an admin action, page, or controller action that reads or writes municipal
data.

## Roles
- `SuperAdmin` — system-wide access; the only role allowed to create, edit, and
  delete municipalities.
- `MunicipalityAdmin` — access limited to the municipalities assigned in the
  `MunicipalityAdmins` join table.

Role names live in the `Roles` constants class in
`Services/MunicipalityAccessService.cs`; reference them instead of string literals.

## Applying authorization
- Gate whole controllers with
  `[Authorize(Roles = $"{Roles.SuperAdmin},{Roles.MunicipalityAdmin}")]`, or
  `[Authorize(Roles = Roles.SuperAdmin)]` for municipality management.
- Every action that takes an entity id must confirm ownership through
  `MunicipalityAccessService`:
  - `CanManageMunicipalityAsync(user, municipalityId)`
  - `CanManagePositionAsync(user, positionId)`
  - `CanManageCandidateAsync(user, candidateId)`
- Return `NotFound()` when a user reaches an entity outside their scope; reserve
  `Forbid()` for a known-but-disallowed action. Never trust a client-supplied id.
- Filter list/index queries with the ids from
  `GetMunicipalityIdsAsync(user)` so a municipality admin only ever sees their own
  data.

## Public (anonymous) surface
Anonymous visitors may browse, search, and select candidates and print or export
their voting guide. Do not require authentication for public candidate pages.

## Seed accounts
`DbInitializer` creates `super` (SuperAdmin) and `pm` (MunicipalityAdmin, mapped to
Pitt Meadows) with password `P@$$w0rd`.

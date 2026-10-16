namespace MunicipalElections.DTOs.Api;

// --- DTOs for the mobile (SwiftUI) app REST API ---
// JSON shapes are serialized with camelCase (configured in Program.cs).

public record AuthRequest(string FullName, string Email, string Password);

public record AuthLoginRequest(string Email, string Password);

public record AuthResponse(string Token, string Email, string FullName);

public record MunicipalityDto(
    int Id,
    string Name,
    string Province,
    DateTime ElectionDate,
    string? Description,
    string? LogoUrl);

public record PositionDto(
    int Id,
    string Name,
    int SeatsAvailable,
    int MunicipalityId);

public record MunicipalityDetailDto(
    int Id,
    string Name,
    string Province,
    DateTime ElectionDate,
    string? Description,
    string? LogoUrl,
    IReadOnlyList<PositionDto> Positions);

public record CandidateDto(
    int Id,
    string Name,
    string? Biography,
    string? PhotoUrl,
    string? Website,
    string? Email,
    int PositionId,
    int MunicipalityId);

public record PositionDetailDto(
    int Id,
    string Name,
    int SeatsAvailable,
    int MunicipalityId,
    IReadOnlyList<CandidateDto> Candidates);

public record SavedCandidateRequest(int CandidateId);

public record SavedCandidateDto(
    int Id,
    int CandidateId,
    DateTime DateSaved,
    CandidateDto Candidate);

public record SavedCandidateCreatedDto(int Id, int CandidateId, DateTime DateSaved);

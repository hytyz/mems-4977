using System.ComponentModel.DataAnnotations;

namespace MunicipalElections.DTOs.Api;

// --- DTOs for the mobile (SwiftUI) app REST API ---
// JSON shapes are serialized with camelCase (configured in Program.cs).
// Request DTOs carry DataAnnotations so [ApiController] returns a 400
// ValidationProblemDetails for invalid input; the iOS app is not the only
// client that may post to these endpoints.

public class AuthRequest
{
    [Required(ErrorMessage = "Name is required.")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "Name must be between 2 and 100 characters.")]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Email is required.")]
    [EmailAddress(ErrorMessage = "Email must be a valid email address.")]
    [StringLength(254, ErrorMessage = "Email cannot exceed 254 characters.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Password is required.")]
    [StringLength(100, MinimumLength = 6, ErrorMessage = "Password must be at least 6 characters.")]
    public string Password { get; set; } = string.Empty;
}

public class AuthLoginRequest
{
    [Required(ErrorMessage = "Email is required.")]
    [EmailAddress(ErrorMessage = "Email must be a valid email address.")]
    [StringLength(254, ErrorMessage = "Email cannot exceed 254 characters.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Password is required.")]
    public string Password { get; set; } = string.Empty;
}

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

public class SavedCandidateRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "A valid candidate id is required.")]
    public int CandidateId { get; set; }
}

public record SavedCandidateDto(
    int Id,
    int CandidateId,
    DateTime DateSaved,
    CandidateDto Candidate);

public record SavedCandidateCreatedDto(int Id, int CandidateId, DateTime DateSaved);

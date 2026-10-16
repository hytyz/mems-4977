using MunicipalElections.Models;

namespace MunicipalElections.DTOs.Api;

// --- Entity -> DTO mapping for the mobile REST API ---

public static class ApiMappers
{
    public static MunicipalityDto ToDto(this Municipality m) => new(
        m.MunicipalityId,
        m.Name,
        m.Province,
        DateTime.SpecifyKind(m.ElectionDate, DateTimeKind.Utc),
        m.Description,
        string.IsNullOrWhiteSpace(m.LogoFileName) ? null : $"/uploads/municipalities/{m.LogoFileName}");

    public static MunicipalityDetailDto ToDetailDto(this Municipality m) => new(
        m.MunicipalityId,
        m.Name,
        m.Province,
        DateTime.SpecifyKind(m.ElectionDate, DateTimeKind.Utc),
        m.Description,
        string.IsNullOrWhiteSpace(m.LogoFileName) ? null : $"/uploads/municipalities/{m.LogoFileName}",
        m.Positions.Select(p => p.ToDto()).ToList());

    public static PositionDto ToDto(this Position p) => new(
        p.PositionId,
        p.Name,
        p.SeatsAvailable,
        p.MunicipalityId);

    public static PositionDetailDto ToDetailDto(this Position p) => new(
        p.PositionId,
        p.Name,
        p.SeatsAvailable,
        p.MunicipalityId,
        p.Candidates.Select(c => c.ToDto()).ToList());

    public static CandidateDto ToDto(this Candidate c) => new(
        c.CandidateId,
        c.Name,
        c.Profile,
        string.IsNullOrWhiteSpace(c.PhotoFileName) ? null : $"/uploads/candidates/{c.PhotoFileName}",
        c.Website,
        c.Email,
        c.PositionId,
        c.Position?.MunicipalityId ?? 0);

    public static SavedCandidateDto ToDto(this SavedCandidate s) => new(
        s.Id,
        s.CandidateId,
        DateTime.SpecifyKind(s.DateSaved, DateTimeKind.Utc),
        s.Candidate?.ToDto()!);
}

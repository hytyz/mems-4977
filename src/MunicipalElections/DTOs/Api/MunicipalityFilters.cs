using MunicipalElections.Models;

namespace MunicipalElections.DTOs.Api;

public static class MunicipalityFilters
{
    public static IQueryable<Municipality> InMunicipality(
        this IQueryable<Municipality> query, string? city, int? municipalityId)
    {
        if (municipalityId is int id)
        {
            query = query.Where(m => m.MunicipalityId == id);
        }

        if (Normalize(city) is { } name)
        {
            query = query.Where(m => m.Name.ToLower() == name);
        }

        return query;
    }

    public static IQueryable<Position> InMunicipality(
        this IQueryable<Position> query, string? city, int? municipalityId)
    {
        if (municipalityId is int id)
        {
            query = query.Where(p => p.MunicipalityId == id);
        }

        if (Normalize(city) is { } name)
        {
            query = query.Where(p => p.Municipality!.Name.ToLower() == name);
        }

        return query;
    }

    public static IQueryable<Candidate> InMunicipality(
        this IQueryable<Candidate> query, string? city, int? municipalityId)
    {
        if (municipalityId is int id)
        {
            query = query.Where(c => c.Position!.MunicipalityId == id);
        }

        if (Normalize(city) is { } name)
        {
            query = query.Where(c => c.Position!.Municipality!.Name.ToLower() == name);
        }

        return query;
    }

    private static string? Normalize(string? city) =>
        string.IsNullOrWhiteSpace(city) ? null : city.Trim().ToLower();
}

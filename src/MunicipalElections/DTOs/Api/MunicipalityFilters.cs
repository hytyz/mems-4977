using Microsoft.AspNetCore.Mvc;
using MunicipalElections.Models;

namespace MunicipalElections.DTOs.Api;

public static class MunicipalityFilters
{
    public static ActionResult? RequireMunicipality(
        this ControllerBase controller, string? city, int? municipalityId)
    {
        if (municipalityId is not null || Normalize(city) is not null)
        {
            return null;
        }

        controller.ModelState.AddModelError(
            "city",
            "A municipality is required. Pass ?city=<name> or ?municipalityId=<id>.");
        return controller.ValidationProblem(controller.ModelState);
    }

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

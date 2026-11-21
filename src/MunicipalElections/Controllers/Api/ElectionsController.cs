using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Auth;
using MunicipalElections.Data;
using MunicipalElections.DTOs.Api;

namespace MunicipalElections.Controllers.Api;

[ApiController]
[Authorize(AuthenticationSchemes = ApiAuth.JwtScheme)]
[Route("api/[controller]")]
public class ElectionsController : ControllerBase
{
    private readonly ApplicationDbContext _db;

    public ElectionsController(ApplicationDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<MunicipalityDetailDto>>> GetAll(
        [FromQuery] string? city,
        [FromQuery] int? municipalityId)
    {
        if (this.RequireMunicipality(city, municipalityId) is { } missing)
        {
            return missing;
        }

        var municipalities = await _db.Municipalities
            .AsNoTracking()
            .Include(m => m.Positions)
            .InMunicipality(city, municipalityId)
            .OrderBy(m => m.Name)
            .ToListAsync();

        return Ok(municipalities.Select(m => m.ToDetailDto()));
    }
}

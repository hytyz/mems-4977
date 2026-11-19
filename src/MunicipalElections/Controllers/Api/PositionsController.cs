using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Data;
using MunicipalElections.DTOs.Api;

namespace MunicipalElections.Controllers.Api;

[ApiController]
[Route("api/positions")]
[Route("api/offices")]
public class PositionsController : ControllerBase
{
    private readonly ApplicationDbContext _db;

    public PositionsController(ApplicationDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<PositionDto>>> GetAll(
        [FromQuery] string? city,
        [FromQuery] int? municipalityId)
    {
        if (this.RequireMunicipality(city, municipalityId) is { } missing)
        {
            return missing;
        }

        var positions = await _db.Positions
            .AsNoTracking()
            .InMunicipality(city, municipalityId)
            .OrderBy(p => p.MunicipalityId).ThenBy(p => p.PositionId)
            .ToListAsync();

        return Ok(positions.Select(p => p.ToDto()));
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<PositionDetailDto>> GetById(
        int id,
        [FromQuery] string? city,
        [FromQuery] int? municipalityId)
    {
        if (this.RequireMunicipality(city, municipalityId) is { } missing)
        {
            return missing;
        }

        var position = await _db.Positions
            .AsNoTracking()
            .Include(p => p.Candidates)
            .InMunicipality(city, municipalityId)
            .FirstOrDefaultAsync(p => p.PositionId == id);

        if (position is null)
        {
            return NotFound();
        }

        return Ok(position.ToDetailDto());
    }
}

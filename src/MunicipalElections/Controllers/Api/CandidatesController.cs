using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Data;
using MunicipalElections.DTOs.Api;

namespace MunicipalElections.Controllers.Api;

[ApiController]
[Route("api/[controller]")]
public class CandidatesController : ControllerBase
{
    private readonly ApplicationDbContext _db;

    public CandidatesController(ApplicationDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<CandidateDto>>> GetAll(
        [FromQuery] string? name,
        [FromQuery] string? city,
        [FromQuery] int? municipalityId)
    {
        var query = _db.Candidates
            .AsNoTracking()
            .Include(c => c.Position)
            .InMunicipality(city, municipalityId);

        if (!string.IsNullOrWhiteSpace(name))
        {
            var term = name.Trim().ToLower();
            query = query.Where(c => c.Name.ToLower().Contains(term));
        }

        var list = await query.OrderBy(c => c.Name).ToListAsync();
        return Ok(list.Select(c => c.ToDto()));
    }

    [HttpGet("search")]
    public Task<ActionResult<IEnumerable<CandidateDto>>> Search(
        [FromQuery] string? name,
        [FromQuery] string? city,
        [FromQuery] int? municipalityId)
    {
        return GetAll(name, city, municipalityId);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<CandidateDto>> GetById(
        int id,
        [FromQuery] string? city,
        [FromQuery] int? municipalityId)
    {
        var candidate = await _db.Candidates
            .AsNoTracking()
            .Include(c => c.Position)
            .InMunicipality(city, municipalityId)
            .FirstOrDefaultAsync(c => c.CandidateId == id);

        if (candidate is null)
        {
            return NotFound();
        }

        return Ok(candidate.ToDto());
    }
}

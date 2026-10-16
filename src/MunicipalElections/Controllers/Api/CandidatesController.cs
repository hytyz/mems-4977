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
    public async Task<ActionResult<IEnumerable<CandidateDto>>> GetAll([FromQuery] string? name)
    {
        var candidates = await Query(name);
        return Ok(candidates);
    }

    [HttpGet("search")]
    public Task<ActionResult<IEnumerable<CandidateDto>>> Search([FromQuery] string? name)
    {
        return GetAll(name);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<CandidateDto>> GetById(int id)
    {
        var candidate = await _db.Candidates
            .AsNoTracking()
            .Include(c => c.Position)
            .FirstOrDefaultAsync(c => c.CandidateId == id);

        if (candidate is null)
        {
            return NotFound();
        }

        return Ok(candidate.ToDto());
    }

    private async Task<List<CandidateDto>> Query(string? name)
    {
        var query = _db.Candidates
            .AsNoTracking()
            .Include(c => c.Position)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(name))
        {
            var term = name.Trim().ToLowerInvariant();
            query = query.Where(c => c.Name.ToLower().Contains(term));
        }

        var list = await query.OrderBy(c => c.Name).ToListAsync();
        return list.Select(c => c.ToDto()).ToList();
    }
}

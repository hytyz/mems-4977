using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Data;
using MunicipalElections.DTOs.Api;

namespace MunicipalElections.Controllers.Api;

[ApiController]
[Route("api/[controller]")]
public class MunicipalitiesController : ControllerBase
{
    private readonly ApplicationDbContext _db;

    public MunicipalitiesController(ApplicationDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<MunicipalityDto>>> GetAll()
    {
        var municipalities = await _db.Municipalities
            .AsNoTracking()
            .OrderBy(m => m.Name)
            .ToListAsync();

        return Ok(municipalities.Select(m => m.ToDto()));
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<MunicipalityDetailDto>> GetById(int id)
    {
        var municipality = await _db.Municipalities
            .AsNoTracking()
            .Include(m => m.Positions)
            .FirstOrDefaultAsync(m => m.MunicipalityId == id);

        if (municipality is null)
        {
            return NotFound();
        }

        return Ok(municipality.ToDetailDto());
    }
}

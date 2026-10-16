using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Data;
using MunicipalElections.DTOs.Api;

namespace MunicipalElections.Controllers.Api;

[ApiController]
[Route("api/[controller]")]
public class PositionsController : ControllerBase
{
    private readonly ApplicationDbContext _db;

    public PositionsController(ApplicationDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<PositionDto>>> GetAll()
    {
        var positions = await _db.Positions
            .AsNoTracking()
            .OrderBy(p => p.MunicipalityId).ThenBy(p => p.Name)
            .ToListAsync();

        return Ok(positions.Select(p => p.ToDto()));
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<PositionDetailDto>> GetById(int id)
    {
        var position = await _db.Positions
            .AsNoTracking()
            .Include(p => p.Candidates)
            .FirstOrDefaultAsync(p => p.PositionId == id);

        if (position is null)
        {
            return NotFound();
        }

        return Ok(position.ToDetailDto());
    }
}

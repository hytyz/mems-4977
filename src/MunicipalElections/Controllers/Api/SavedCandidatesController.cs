using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Auth;
using MunicipalElections.Data;
using MunicipalElections.DTOs.Api;
using MunicipalElections.Models;

namespace MunicipalElections.Controllers.Api;

// --- API (mobile app): authenticated with JWT bearer tokens only ---
[ApiController]
[Authorize(AuthenticationSchemes = ApiAuth.JwtScheme)]
[Route("api/[controller]")]
public class SavedCandidatesController : ControllerBase
{
    private readonly ApplicationDbContext _db;

    public SavedCandidatesController(ApplicationDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<SavedCandidateDto>>> GetAll()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
        var saved = await _db.SavedCandidates
            .AsNoTracking()
            .Include(s => s.Candidate)
                .ThenInclude(c => c!.Position)
            .Where(s => s.UserId == userId)
            .OrderByDescending(s => s.DateSaved)
            .ToListAsync();

        return Ok(saved.Select(s => s.ToDto()));
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<SavedCandidateDto>> GetById(int id)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
        var saved = await _db.SavedCandidates
            .AsNoTracking()
            .Include(s => s.Candidate)
                .ThenInclude(c => c!.Position)
            .FirstOrDefaultAsync(s => s.Id == id && s.UserId == userId);

        if (saved is null)
        {
            return NotFound();
        }

        return Ok(saved.ToDto());
    }

    [HttpPost]
    public async Task<ActionResult<SavedCandidateCreatedDto>> Save(SavedCandidateRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;

        var candidateExists = await _db.Candidates.AnyAsync(c => c.CandidateId == request.CandidateId);
        if (!candidateExists)
        {
            return Problem(
                statusCode: StatusCodes.Status404NotFound,
                title: "Candidate not found",
                detail: $"No candidate with id {request.CandidateId} exists.");
        }

        var alreadySaved = await _db.SavedCandidates
            .AnyAsync(s => s.UserId == userId && s.CandidateId == request.CandidateId);
        if (alreadySaved)
        {
            return Problem(
                statusCode: StatusCodes.Status409Conflict,
                title: "Candidate already saved",
                detail: $"Candidate {request.CandidateId} is already in your saved list.");
        }

        var saved = new SavedCandidate
        {
            UserId = userId,
            CandidateId = request.CandidateId,
            DateSaved = DateTime.UtcNow
        };

        _db.SavedCandidates.Add(saved);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = saved.Id }, new SavedCandidateCreatedDto(
            saved.Id,
            saved.CandidateId,
            DateTime.SpecifyKind(saved.DateSaved, DateTimeKind.Utc)));
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
        var saved = await _db.SavedCandidates
            .FirstOrDefaultAsync(s => s.Id == id && s.UserId == userId);

        if (saved is null)
        {
            return NotFound();
        }

        _db.SavedCandidates.Remove(saved);
        await _db.SaveChangesAsync();

        return NoContent();
    }
}

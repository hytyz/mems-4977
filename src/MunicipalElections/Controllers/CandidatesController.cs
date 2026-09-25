using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Data;
using MunicipalElections.Models;
using MunicipalElections.Services;

namespace MunicipalElections.Controllers;

public class CandidatesController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly VotingGuideService _guide;

    public CandidatesController(ApplicationDbContext context, VotingGuideService guide)
    {
        _context = context;
        _guide = guide;
    }

    public async Task<IActionResult> Index(
        string? search,
        int? municipalityId,
        int? positionId,
        int page = 1,
        int pageSize = 9)
    {
        IQueryable<Candidate> query = _context.Candidates
            .Include(c => c.Position)
                .ThenInclude(p => p!.Municipality);

        if (!string.IsNullOrWhiteSpace(search))
        {
            search = search.Trim();
            query = query.Where(c => c.Name.Contains(search)
                || (c.Profile != null && c.Profile.Contains(search)));
        }

        if (municipalityId.HasValue)
        {
            query = query.Where(c => c.Position!.MunicipalityId == municipalityId.Value);
        }

        if (positionId.HasValue)
        {
            query = query.Where(c => c.PositionId == positionId.Value);
        }

        query = query.OrderBy(c => c.Position!.Municipality!.Name)
                     .ThenBy(c => c.Position!.Name)
                     .ThenBy(c => c.Name);

        int total = await query.CountAsync();
        int totalPages = Math.Max(1, (int)Math.Ceiling(total / (double)pageSize));
        page = Math.Clamp(page, 1, totalPages);

        var candidates = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        ViewData["Search"] = search;
        ViewData["MunicipalityId"] = municipalityId;
        ViewData["PositionId"] = positionId;
        ViewData["Page"] = page;
        ViewData["PageSize"] = pageSize;
        ViewData["Total"] = total;
        ViewData["TotalPages"] = totalPages;

        await PopulateFilterDropdownsAsync(municipalityId, positionId);

        return View(candidates);
    }

    public async Task<IActionResult> Details(int id)
    {
        var candidate = await _context.Candidates
            .Include(c => c.Position)
                .ThenInclude(p => p!.Municipality)
            .Include(c => c.Endorsements)
            .FirstOrDefaultAsync(c => c.CandidateId == id);

        if (candidate == null)
        {
            return NotFound();
        }

        ViewData["InGuide"] = _guide.Contains(id);
        return View(candidate);
    }

    public async Task<IActionResult> Compare(int? idA, int? idB)
    {
        var candidates = new List<Candidate>();
        if (idA.HasValue)
        {
            var a = await _context.Candidates
                .Include(c => c.Position).ThenInclude(p => p!.Municipality)
                .Include(c => c.Endorsements)
                .FirstOrDefaultAsync(c => c.CandidateId == idA.Value);
            if (a != null) candidates.Add(a);
        }

        if (idB.HasValue)
        {
            var b = await _context.Candidates
                .Include(c => c.Position).ThenInclude(p => p!.Municipality)
                .Include(c => c.Endorsements)
                .FirstOrDefaultAsync(c => c.CandidateId == idB.Value);
            if (b != null && b.CandidateId != idA) candidates.Add(b);
        }

        await PopulateCandidateDropdownsAsync(idA, idB);
        return View(candidates);
    }

    private async Task PopulateFilterDropdownsAsync(int? municipalityId, int? positionId)
    {
        var municipalities = await _context.Municipalities.OrderBy(m => m.Name).ToListAsync();
        ViewData["Municipalities"] = new SelectList(municipalities, nameof(Municipality.MunicipalityId), nameof(Municipality.Name), municipalityId);

        if (municipalityId.HasValue)
        {
            var positions = await _context.Positions
                .Where(p => p.MunicipalityId == municipalityId.Value)
                .OrderBy(p => p.Name)
                .ToListAsync();
            ViewData["Positions"] = new SelectList(positions, nameof(Position.PositionId), nameof(Position.Name), positionId);
        }
        else
        {
            ViewData["Positions"] = new SelectList(Enumerable.Empty<SelectListItem>());
        }
    }

    private async Task PopulateCandidateDropdownsAsync(int? idA, int? idB)
    {
        var candidates = await _context.Candidates
            .Include(c => c.Position).ThenInclude(p => p!.Municipality)
            .OrderBy(c => c.Name)
            .Select(c => new
            {
                c.CandidateId,
                DisplayName = $"{c.Name} ({c.Position!.Municipality!.Name} — {c.Position!.Name})"
            })
            .ToListAsync();

        ViewData["CandidateA"] = new SelectList(candidates, "CandidateId", "DisplayName", idA);
        ViewData["CandidateB"] = new SelectList(candidates, "CandidateId", "DisplayName", idB);
    }
}

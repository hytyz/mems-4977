using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Data;
using MunicipalElections.Services;

namespace MunicipalElections.Areas.Admin.Controllers;

[Area("Admin")]
[Authorize(Roles = $"{Roles.SuperAdmin},{Roles.MunicipalityAdmin}")]
public class DashboardController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly MunicipalityAccessService _access;

    public DashboardController(ApplicationDbContext context, MunicipalityAccessService access)
    {
        _context = context;
        _access = access;
    }

    public async Task<IActionResult> Index()
    {
        var municipalityIds = await _access.GetMunicipalityIdsAsync(User);

        var municipalityCount = municipalityIds.Count;
        var positionCount = await _context.Positions
            .CountAsync(p => municipalityIds.Contains(p.MunicipalityId));
        var candidateCount = await _context.Candidates
            .CountAsync(c => municipalityIds.Contains(c.Position!.MunicipalityId));

        ViewData["MunicipalityCount"] = municipalityCount;
        ViewData["PositionCount"] = positionCount;
        ViewData["CandidateCount"] = candidateCount;
        ViewData["IsSuperAdmin"] = _access.IsSuperAdmin(User);

        return View();
    }
}

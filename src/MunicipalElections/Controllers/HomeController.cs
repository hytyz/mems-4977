using Microsoft.AspNetCore.Mvc;
using MunicipalElections.Data;
using Microsoft.EntityFrameworkCore;

namespace MunicipalElections.Controllers;

public class HomeController : Controller
{
    private readonly ApplicationDbContext _context;

    public HomeController(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<IActionResult> Index()
    {
        var municipalities = await _context.Municipalities
            .OrderBy(m => m.ElectionDate)
            .ThenBy(m => m.Name)
            .ToListAsync();

        return View(municipalities);
    }

    public async Task<IActionResult> Municipality(int id)
    {
        var municipality = await _context.Municipalities
            .Include(m => m.Positions)
                .ThenInclude(p => p.Candidates)
            .FirstOrDefaultAsync(m => m.MunicipalityId == id);

        if (municipality == null)
        {
            return NotFound();
        }

        return View(municipality);
    }

    public IActionResult Privacy()
    {
        return View();
    }
}

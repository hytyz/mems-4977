using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Data;
using MunicipalElections.Models;
using MunicipalElections.Services;

namespace MunicipalElections.Areas.Admin.Controllers;

[Area("Admin")]
[Authorize(Roles = Roles.SuperAdmin)]
public class MunicipalitiesController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly ImageFileService _images;

    public MunicipalitiesController(ApplicationDbContext context, ImageFileService images)
    {
        _context = context;
        _images = images;
    }

    public async Task<IActionResult> Index()
    {
        return View(await _context.Municipalities
            .OrderBy(m => m.Name)
            .ToListAsync());
    }

    public async Task<IActionResult> Details(int? id)
    {
        if (id == null)
        {
            return NotFound();
        }

        var municipality = await _context.Municipalities
            .Include(m => m.Positions)
            .FirstOrDefaultAsync(m => m.MunicipalityId == id);
        if (municipality == null)
        {
            return NotFound();
        }

        return View(municipality);
    }

    public IActionResult Create()
    {
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create([Bind("Name,Province,ElectionDate,Description")] Municipality municipality, IFormFile? logoFile)
    {
        ModelState.Remove(nameof(Municipality.LogoFileName));
        if (ModelState.IsValid)
        {
            municipality.LogoFileName = _images.Save(logoFile, "municipalities", out string? error);
            if (error != null)
            {
                ModelState.AddModelError(nameof(municipality.LogoFileName), error);
                return View(municipality);
            }

            _context.Add(municipality);
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }

        return View(municipality);
    }

    public async Task<IActionResult> Edit(int? id)
    {
        if (id == null)
        {
            return NotFound();
        }

        var municipality = await _context.Municipalities.FindAsync(id);
        if (municipality == null)
        {
            return NotFound();
        }

        return View(municipality);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id, [Bind("MunicipalityId,Name,Province,ElectionDate,Description")] Municipality municipality, IFormFile? logoFile, bool removeLogo = false)
    {
        if (id != municipality.MunicipalityId)
        {
            return NotFound();
        }

        ModelState.Remove(nameof(Municipality.LogoFileName));
        if (ModelState.IsValid)
        {
            var existing = await _context.Municipalities.FindAsync(id);
            if (existing == null)
            {
                return NotFound();
            }

            existing.Name = municipality.Name;
            existing.Province = municipality.Province;
            existing.ElectionDate = municipality.ElectionDate;
            existing.Description = municipality.Description;

            if (removeLogo)
            {
                _images.Delete(existing.LogoFileName, "municipalities");
                existing.LogoFileName = null;
            }
            else if (logoFile != null && logoFile.Length > 0)
            {
                string fileName = _images.Save(logoFile, "municipalities", out string? error)!;
                if (error != null)
                {
                    ModelState.AddModelError(nameof(Municipality.LogoFileName), error);
                    return View(municipality);
                }

                _images.Delete(existing.LogoFileName, "municipalities");
                existing.LogoFileName = fileName;
            }

            _context.Update(existing);
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }

        return View(municipality);
    }

    public async Task<IActionResult> Delete(int? id)
    {
        if (id == null)
        {
            return NotFound();
        }

        var municipality = await _context.Municipalities
            .FirstOrDefaultAsync(m => m.MunicipalityId == id);
        if (municipality == null)
        {
            return NotFound();
        }

        return View(municipality);
    }

    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        var municipality = await _context.Municipalities.FindAsync(id);
        if (municipality != null)
        {
            _images.Delete(municipality.LogoFileName, "municipalities");
            _context.Municipalities.Remove(municipality);
        }

        await _context.SaveChangesAsync();
        return RedirectToAction(nameof(Index));
    }
}

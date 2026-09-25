using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Data;
using MunicipalElections.Models;
using MunicipalElections.Services;

namespace MunicipalElections.Areas.Admin.Controllers;

[Area("Admin")]
[Authorize(Roles = $"{Roles.SuperAdmin},{Roles.MunicipalityAdmin}")]
public class PositionsController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly MunicipalityAccessService _access;

    public PositionsController(ApplicationDbContext context, MunicipalityAccessService access)
    {
        _context = context;
        _access = access;
    }

    public async Task<IActionResult> Index()
    {
        var municipalityIds = await _access.GetMunicipalityIdsAsync(User);
        var positions = await _context.Positions
            .Where(p => municipalityIds.Contains(p.MunicipalityId))
            .Include(p => p.Municipality)
            .OrderBy(p => p.Municipality!.Name)
            .ThenBy(p => p.Name)
            .ToListAsync();
        return View(positions);
    }

    public async Task<IActionResult> Details(int? id)
    {
        if (id == null)
        {
            return NotFound();
        }

        var position = await _context.Positions
            .Include(p => p.Municipality)
            .Include(p => p.Candidates)
            .FirstOrDefaultAsync(p => p.PositionId == id);
        if (position == null || !await _access.CanManagePositionAsync(User, position.PositionId))
        {
            return NotFound();
        }

        return View(position);
    }

    public async Task<IActionResult> Create()
    {
        await PopulateMunicipalitiesDropDownAsync();
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create([Bind("Name,SeatsAvailable,MunicipalityId")] Position position)
    {
        if (!await _access.CanManageMunicipalityAsync(User, position.MunicipalityId))
        {
            return Forbid();
        }

        if (ModelState.IsValid)
        {
            _context.Add(position);
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }

        await PopulateMunicipalitiesDropDownAsync(position.MunicipalityId);
        return View(position);
    }

    public async Task<IActionResult> Edit(int? id)
    {
        if (id == null)
        {
            return NotFound();
        }

        var position = await _context.Positions.FindAsync(id);
        if (position == null || !await _access.CanManagePositionAsync(User, position.PositionId))
        {
            return NotFound();
        }

        await PopulateMunicipalitiesDropDownAsync(position.MunicipalityId);
        return View(position);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id, [Bind("PositionId,Name,SeatsAvailable,MunicipalityId")] Position position)
    {
        if (id != position.PositionId)
        {
            return NotFound();
        }

        if (!await _access.CanManagePositionAsync(User, position.PositionId) ||
            !await _access.CanManageMunicipalityAsync(User, position.MunicipalityId))
        {
            return Forbid();
        }

        if (ModelState.IsValid)
        {
            try
            {
                _context.Update(position);
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!PositionExists(position.PositionId))
                {
                    return NotFound();
                }

                throw;
            }

            return RedirectToAction(nameof(Index));
        }

        await PopulateMunicipalitiesDropDownAsync(position.MunicipalityId);
        return View(position);
    }

    public async Task<IActionResult> Delete(int? id)
    {
        if (id == null)
        {
            return NotFound();
        }

        var position = await _context.Positions
            .Include(p => p.Municipality)
            .FirstOrDefaultAsync(p => p.PositionId == id);
        if (position == null || !await _access.CanManagePositionAsync(User, position.PositionId))
        {
            return NotFound();
        }

        return View(position);
    }

    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        var position = await _context.Positions.FindAsync(id);
        if (position != null)
        {
            if (!await _access.CanManagePositionAsync(User, position.PositionId))
            {
                return Forbid();
            }

            _context.Positions.Remove(position);
        }

        await _context.SaveChangesAsync();
        return RedirectToAction(nameof(Index));
    }

    private async Task PopulateMunicipalitiesDropDownAsync(int? selectedId = null)
    {
        var municipalityIds = await _access.GetMunicipalityIdsAsync(User);
        ViewData["MunicipalityId"] = new SelectList(
            _context.Municipalities.Where(m => municipalityIds.Contains(m.MunicipalityId)).OrderBy(m => m.Name),
            nameof(Municipality.MunicipalityId),
            nameof(Municipality.Name),
            selectedId);
    }

    private bool PositionExists(int id) => _context.Positions.Any(e => e.PositionId == id);
}

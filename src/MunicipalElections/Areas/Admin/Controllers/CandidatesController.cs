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
public class CandidatesController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly MunicipalityAccessService _access;
    private readonly ImageFileService _images;

    public CandidatesController(ApplicationDbContext context, MunicipalityAccessService access, ImageFileService images)
    {
        _context = context;
        _access = access;
        _images = images;
    }

    public async Task<IActionResult> Index()
    {
        var municipalityIds = await _access.GetMunicipalityIdsAsync(User);
        var candidates = await _context.Candidates
            .Where(c => municipalityIds.Contains(c.Position!.MunicipalityId))
            .Include(c => c.Position)
                .ThenInclude(p => p!.Municipality)
            .OrderBy(c => c.Position!.Municipality!.Name)
            .ThenBy(c => c.Position!.Name)
            .ThenBy(c => c.Name)
            .ToListAsync();
        return View(candidates);
    }

    public async Task<IActionResult> Details(int? id)
    {
        if (id == null)
        {
            return NotFound();
        }

        var candidate = await _context.Candidates
            .Include(c => c.Position)
                .ThenInclude(p => p!.Municipality)
            .Include(c => c.Endorsements)
            .FirstOrDefaultAsync(c => c.CandidateId == id);
        if (candidate == null || !await _access.CanManageCandidateAsync(User, candidate.CandidateId))
        {
            return NotFound();
        }

        return View(candidate);
    }

    public async Task<IActionResult> Create()
    {
        await PopulatePositionDropDownAsync();
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(
        [Bind("Name,Profile,Website,Email,VideoUrl,SocialX,SocialFacebook,SocialInstagram,SocialLinkedIn,PositionId")] Candidate candidate,
        IFormFile? photoFile)
    {
        if (!await _access.CanManagePositionAsync(User, candidate.PositionId))
        {
            return Forbid();
        }

        ModelState.Remove(nameof(Candidate.PhotoFileName));
        ModelState.Remove(nameof(Candidate.DateCreated));

        if (ModelState.IsValid)
        {
            candidate.PhotoFileName = _images.Save(photoFile, "candidates", out string? error);
            if (error != null)
            {
                ModelState.AddModelError(nameof(Candidate.PhotoFileName), error);
                await PopulatePositionDropDownAsync(candidate.PositionId);
                return View(candidate);
            }

            candidate.DateCreated = DateTime.UtcNow;
            _context.Add(candidate);
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }

        await PopulatePositionDropDownAsync(candidate.PositionId);
        return View(candidate);
    }

    public async Task<IActionResult> Edit(int? id)
    {
        if (id == null)
        {
            return NotFound();
        }

        var candidate = await _context.Candidates.FindAsync(id);
        if (candidate == null || !await _access.CanManageCandidateAsync(User, candidate.CandidateId))
        {
            return NotFound();
        }

        await PopulatePositionDropDownAsync(candidate.PositionId);
        return View(candidate);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(
        int id,
        [Bind("CandidateId,Name,Profile,Website,Email,VideoUrl,SocialX,SocialFacebook,SocialInstagram,SocialLinkedIn,PositionId")] Candidate candidate,
        IFormFile? photoFile,
        bool removePhoto = false)
    {
        if (id != candidate.CandidateId)
        {
            return NotFound();
        }

        var existing = await _context.Candidates.FindAsync(id);
        if (existing == null || !await _access.CanManageCandidateAsync(User, id) ||
            !await _access.CanManagePositionAsync(User, candidate.PositionId))
        {
            return Forbid();
        }

        ModelState.Remove(nameof(Candidate.PhotoFileName));
        ModelState.Remove(nameof(Candidate.DateCreated));

        if (ModelState.IsValid)
        {
            existing.Name = candidate.Name;
            existing.Profile = candidate.Profile;
            existing.Website = candidate.Website;
            existing.Email = candidate.Email;
            existing.VideoUrl = candidate.VideoUrl;
            existing.SocialX = candidate.SocialX;
            existing.SocialFacebook = candidate.SocialFacebook;
            existing.SocialInstagram = candidate.SocialInstagram;
            existing.SocialLinkedIn = candidate.SocialLinkedIn;
            existing.PositionId = candidate.PositionId;

            if (removePhoto)
            {
                _images.Delete(existing.PhotoFileName, "candidates");
                existing.PhotoFileName = null;
            }
            else if (photoFile != null && photoFile.Length > 0)
            {
                
                string fileName = _images.Save(photoFile, "candidates", out string? error)!;
                if (error != null)
                {
                    ModelState.AddModelError(nameof(Candidate.PhotoFileName), error);
                    await PopulatePositionDropDownAsync(candidate.PositionId);
                    return View(candidate);
                }

                _images.Delete(existing.PhotoFileName, "candidates");
                existing.PhotoFileName = fileName;
            }

            _context.Update(existing);
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }

        await PopulatePositionDropDownAsync(candidate.PositionId);
        return View(candidate);
    }

    public async Task<IActionResult> Delete(int? id)
    {
        if (id == null)
        {
            return NotFound();
        }

        var candidate = await _context.Candidates
            .Include(c => c.Position)
                .ThenInclude(p => p!.Municipality)
            .FirstOrDefaultAsync(c => c.CandidateId == id);
        if (candidate == null || !await _access.CanManageCandidateAsync(User, candidate.CandidateId))
        {
            return NotFound();
        }

        return View(candidate);
    }

    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        var candidate = await _context.Candidates.FindAsync(id);
        if (candidate != null)
        {
            if (!await _access.CanManageCandidateAsync(User, id))
            {
                return Forbid();
            }

            _images.Delete(candidate.PhotoFileName, "candidates");
            _context.Candidates.Remove(candidate);
        }

        await _context.SaveChangesAsync();
        return RedirectToAction(nameof(Index));
    }


    private async Task PopulatePositionDropDownAsync(int? selectedPositionId = null)
    {
        var municipalityIds = await _access.GetMunicipalityIdsAsync(User);
        var allowedPositions = await _context.Positions
            .Where(p => municipalityIds.Contains(p.MunicipalityId))
            .Include(p => p.Municipality)
            .OrderBy(p => p.Municipality!.Name)
            .ThenBy(p => p.Name)
            .Select(p => new
            {
                p.PositionId,
                DisplayName = $"{p.Municipality!.Name} — {p.Name}"
            })
            .ToListAsync();

        ViewData["PositionId"] = new SelectList(allowedPositions, "PositionId", "DisplayName", selectedPositionId);
    }
}

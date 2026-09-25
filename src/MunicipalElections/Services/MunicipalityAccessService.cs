using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using MunicipalElections.Data;
using MunicipalElections.Models;
using Microsoft.EntityFrameworkCore;

namespace MunicipalElections.Services;

public static class Roles
{
    public const string SuperAdmin = "SuperAdmin";
    public const string MunicipalityAdmin = "MunicipalityAdmin";
}

public class MunicipalityAccessService
{
    private readonly ApplicationDbContext _db;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IHttpContextAccessor _http;
    private readonly ILogger<MunicipalityAccessService> _logger;

    public MunicipalityAccessService(
        ApplicationDbContext db,
        UserManager<ApplicationUser> userManager,
        IHttpContextAccessor http,
        ILogger<MunicipalityAccessService> logger)
    {
        _db = db;
        _userManager = userManager;
        _http = http;
        _logger = logger;
    }

    public bool IsSuperAdmin(ClaimsPrincipal user)
    {
        return user.Identity?.IsAuthenticated == true && user.IsInRole(Roles.SuperAdmin);
    }

    public async Task<List<int>> GetMunicipalityIdsAsync(ClaimsPrincipal user)
    {
        if (!user.Identity!.IsAuthenticated)
        {
            return new List<int>();
        }

        if (user.IsInRole(Roles.SuperAdmin))
        {
            return await _db.Municipalities.Select(m => m.MunicipalityId).ToListAsync();
        }

        string? userId = _userManager.GetUserId(user);
        if (userId is null)
        {
            return new List<int>();
        }

        return await _db.MunicipalityAdmins
            .Where(ma => ma.ApplicationUserId == userId)
            .Select(ma => ma.MunicipalityId)
            .ToListAsync();
    }

    public async Task<bool> CanManageMunicipalityAsync(ClaimsPrincipal user, int municipalityId)
    {
        if (user.IsInRole(Roles.SuperAdmin))
        {
            return true;
        }

        if (!user.IsInRole(Roles.MunicipalityAdmin))
        {
            return false;
        }

        string? userId = _userManager.GetUserId(user);
        return userId is not null &&
               await _db.MunicipalityAdmins
                   .AnyAsync(ma => ma.ApplicationUserId == userId && ma.MunicipalityId == municipalityId);
    }

    public async Task<bool> CanManagePositionAsync(ClaimsPrincipal user, int positionId)
    {
        if (user.IsInRole(Roles.SuperAdmin))
        {
            return true;
        }

        var municipalityId = await _db.Positions
            .Where(p => p.PositionId == positionId)
            .Select(p => p.MunicipalityId)
            .FirstOrDefaultAsync();

        return municipalityId != 0 && await CanManageMunicipalityAsync(user, municipalityId);
    }

    public async Task<bool> CanManageCandidateAsync(ClaimsPrincipal user, int candidateId)
    {
        if (user.IsInRole(Roles.SuperAdmin))
        {
            return true;
        }

        var municipalityId = await _db.Candidates
            .Where(c => c.CandidateId == candidateId)
            .Select(c => c.Position!.MunicipalityId)
            .FirstOrDefaultAsync();

        return municipalityId != 0 && await CanManageMunicipalityAsync(user, municipalityId);
    }
}

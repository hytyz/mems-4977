using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Models;
using MunicipalElections.Services;

namespace MunicipalElections.Data;

public static class DbInitializer
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();

        db.Database.Migrate();

        await EnsureRoleAsync(roleManager, Roles.SuperAdmin);
        await EnsureRoleAsync(roleManager, Roles.MunicipalityAdmin);

        const string seededPassword = "P@$$w0rd";
        var super = await EnsureUserAsync(userManager, "super", seededPassword, Roles.SuperAdmin);
        var pm = await EnsureUserAsync(userManager, "pm", seededPassword, Roles.MunicipalityAdmin);

        if (!db.Municipalities.Any())
        {
            var pittMeadows = new Municipality
            {
                Name = "Pitt Meadows",
                Province = "British Columbia",
                ElectionDate = new DateTime(2026, 10, 17),
                Description = "A family-friendly community where the mountains meet the Fraser River."
            };
            var mapleRidge = new Municipality
            {
                Name = "Maple Ridge",
                Province = "British Columbia",
                ElectionDate = new DateTime(2026, 10, 17),
                Description = "A growing riverside city known for its parks and trails."
            };
            var burnaby = new Municipality
            {
                Name = "Burnaby",
                Province = "British Columbia",
                ElectionDate = new DateTime(2026, 10, 17),
                Description = "The geographic heart of Metro Vancouver."
            };
            var surrey = new Municipality
            {
                Name = "Surrey",
                Province = "British Columbia",
                ElectionDate = new DateTime(2026, 10, 17),
                Description = "One of Canada's fastest-growing cities."
            };

            db.Municipalities.AddRange(pittMeadows, mapleRidge, burnaby, surrey);
            await db.SaveChangesAsync();
        }

        var pmEntity = db.Municipalities.First(m => m.Name == "Pitt Meadows");

        if (!db.Positions.Any())
        {
            db.Positions.AddRange(
                new Position { Name = "Mayor", SeatsAvailable = 1, MunicipalityId = pmEntity.MunicipalityId },
                new Position { Name = "Councilor", SeatsAvailable = 6, MunicipalityId = pmEntity.MunicipalityId },
                new Position { Name = "School Trustee", SeatsAvailable = 2, MunicipalityId = pmEntity.MunicipalityId }
            );
            await db.SaveChangesAsync();
        }

        var mayorPosition = db.Positions.First(p => p.Name == "Mayor" && p.MunicipalityId == pmEntity.MunicipalityId);
        var councilorPosition = db.Positions.First(p => p.Name == "Councilor" && p.MunicipalityId == pmEntity.MunicipalityId);
        var trusteePosition = db.Positions.First(p => p.Name == "School Trustee" && p.MunicipalityId == pmEntity.MunicipalityId);

        if (!db.Candidates.Any())
        {
            db.Candidates.AddRange(
                new Candidate
                {
                    Name = "Jordan Lee",
                    PositionId = mayorPosition.PositionId,
                    Profile = "Jordan has served on council for eight years and is committed to affordable housing and climate resilience.",
                    Email = "jordan.lee@example.com",
                    Website = "https://jordanlee.example.com",
                    SocialX = "https://x.com/jordanlee",
                    DateCreated = DateTime.UtcNow,
                    Endorsements =
                    {
                        new Endorsement { EndorserName = "Pitt Meadows Chamber of Commerce", Organization = "PMCC", Text = "A proven leader for our community." }
                    }
                },
                new Candidate
                {
                    Name = "Morgan Chen",
                    PositionId = mayorPosition.PositionId,
                    Profile = "A small-business owner championing local economic growth and public safety.",
                    Email = "morgan.chen@example.com",
                    DateCreated = DateTime.UtcNow
                },
                new Candidate
                {
                    Name = "Taylor Singh",
                    PositionId = councilorPosition.PositionId,
                    Profile = "Youth advocate and lifelong Pitt Meadows resident focused on recreation and transit.",
                    Website = "https://taylorsingh.example.com",
                    DateCreated = DateTime.UtcNow
                },
                new Candidate
                {
                    Name = "Alex Tran",
                    PositionId = councilorPosition.PositionId,
                    Profile = "Urban planner with a passion for walkable neighbourhoods.",
                    Email = "alex.tran@example.com",
                    DateCreated = DateTime.UtcNow
                },
                new Candidate
                {
                    Name = "Priya Patel",
                    PositionId = councilorPosition.PositionId,
                    Profile = "Teacher and parent advocating for schools and community services.",
                    DateCreated = DateTime.UtcNow
                },
                new Candidate
                {
                    Name = "Sam Nguyen",
                    PositionId = trusteePosition.PositionId,
                    Profile = "Education advocate focused on student well-being and modern learning spaces.",
                    Email = "sam.nguyen@example.com",
                    DateCreated = DateTime.UtcNow
                }
            );
            await db.SaveChangesAsync();
        }

        if (!db.MunicipalityAdmins.Any())
        {
            db.MunicipalityAdmins.Add(new MunicipalityAdmin
            {
                ApplicationUserId = pm.Id,
                MunicipalityId = pmEntity.MunicipalityId
            });
            await db.SaveChangesAsync();
        }
    }

    private static async Task EnsureRoleAsync(RoleManager<IdentityRole> roleManager, string roleName)
    {
        if (!await roleManager.RoleExistsAsync(roleName))
        {
            await roleManager.CreateAsync(new IdentityRole(roleName));
        }
    }

    private static async Task<ApplicationUser> EnsureUserAsync(
        UserManager<ApplicationUser> userManager,
        string userName,
        string password,
        string role)
    {
        var user = await userManager.FindByNameAsync(userName);
        if (user is null)
        {
            user = new ApplicationUser { UserName = userName, Email = $"{userName}@municipal.local", EmailConfirmed = true };
            var result = await userManager.CreateAsync(user, password);
            if (!result.Succeeded)
            {
                throw new InvalidOperationException($"Could not create user '{userName}': {string.Join(", ", result.Errors.Select(e => e.Description))}");
            }
        }
        else
        {
            var resetToken = await userManager.GeneratePasswordResetTokenAsync(user);
            await userManager.ResetPasswordAsync(user, resetToken, password);
        }

        if (!await userManager.IsInRoleAsync(user, role))
        {
            await userManager.AddToRoleAsync(user, role);
        }

        return user;
    }
}

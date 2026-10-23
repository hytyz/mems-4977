using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Models;
using MunicipalElections.Services;

namespace MunicipalElections.Data;

public static class DbInitializer
{
    private static readonly DateTime ElectionDate = new(2026, 10, 17);

    private static readonly (string Name, string Province, string Description, string Logo)[] SeedMunicipalities =
    [
        ("Pitt Meadows", "British Columbia", "A family-friendly community where the mountains meet the Fraser River.", "pitt-meadows.png"),
        ("Maple Ridge", "British Columbia", "A growing riverside city known for its parks and trails.", "maple-ridge.png"),
        ("Burnaby", "British Columbia", "The geographic heart of Metro Vancouver.", "burnaby.png"),
        ("Surrey", "British Columbia", "One of Canada's fastest-growing cities.", "surrey.png"),
    ];

    private static readonly (string Name, int Seats)[] SeedPositions =
    [
        ("Mayor", 1),
        ("Councillor", 6),
        ("School Trustee", 2),
    ];

    private sealed record SeedCandidate(
        string Name,
        string Municipality,
        string Position,
        string Photo,
        string? Email = null,
        string? Website = null,
        string Profile = "");

    // Twelve seeded candidates spread across every municipality and position
    // (the assignment requires a minimum of ten).
    private static readonly SeedCandidate[] SeedCandidates =
    [
        new("Jordan Lee", "Pitt Meadows", "Mayor", "jordan-lee.png",
            "jordan.lee@example.com", "https://jordanlee.example.com",
            "Jordan has served on council for eight years and is committed to affordable housing and climate resilience."),
        new("Morgan Chen", "Pitt Meadows", "Mayor", "morgan-chen.png",
            "morgan.chen@example.com", null,
            "A small-business owner championing local economic growth and public safety."),
        new("Taylor Singh", "Pitt Meadows", "Councillor", "taylor-singh.png",
            null, "https://taylorsingh.example.com",
            "Youth advocate and lifelong Pitt Meadows resident focused on recreation and transit."),
        new("Alex Tran", "Pitt Meadows", "Councillor", "alex-tran.png",
            "alex.tran@example.com", null,
            "Urban planner with a passion for walkable neighbourhoods."),
        new("Priya Patel", "Pitt Meadows", "Councillor", "priya-patel.png",
            null, null,
            "Teacher and parent advocating for schools and community services."),
        new("Sam Nguyen", "Pitt Meadows", "School Trustee", "sam-nguyen.png",
            "sam.nguyen@example.com", null,
            "Education advocate focused on student well-being and modern learning spaces."),
        new("Emily Carter", "Maple Ridge", "Mayor", "emily-carter.png",
            "emily.carter@example.com", "https://emilycarter.example.com",
            "Long-time Maple Ridge resident focused on sustainable growth and trail connectivity."),
        new("Daniel Brooks", "Maple Ridge", "Councillor", "daniel-brooks.png",
            "daniel.brooks@example.com", null,
            "Volunteer firefighter advocating for emergency services and seniors' programs."),
        new("Grace Kim", "Maple Ridge", "School Trustee", "grace-kim.png",
            null, null,
            "Parent and literacy specialist committed to inclusive classrooms."),
        new("Ravi Sharma", "Burnaby", "Mayor", "ravi-sharma.png",
            "ravi.sharma@example.com", "https://ravisharma.example.com",
            "Transit advocate with a decade of experience on regional committees."),
        new("Olivia Martin", "Burnaby", "Councillor", "olivia-martin.png",
            "olivia.martin@example.com", null,
            "Housing policy researcher focused on rental protections and density near transit."),
        new("Liam O'Connor", "Burnaby", "School Trustee", "liam-oconnor.png",
            null, null,
            "Former teacher championing trades education and after-school programs."),
    ];

    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();

        db.Database.Migrate();

        // Roles
        await EnsureRoleAsync(roleManager, Roles.SuperAdmin);
        await EnsureRoleAsync(roleManager, Roles.MunicipalityAdmin);

        // Users. Passwords are only set when the account is first created so a
        // seeded administrator can change theirs without it being reset on restart.
        const string seededPassword = "P@$$w0rd";
        var super = await EnsureUserAsync(userManager, "super", seededPassword, Roles.SuperAdmin);
        var pm = await EnsureUserAsync(userManager, "pm", seededPassword, Roles.MunicipalityAdmin);

        // Election data. Every step is idempotent so an existing database is
        // brought up to date instead of being skipped.
        await SeedElectionDataAsync(db);

        var pmEntity = await db.Municipalities.FirstAsync(m => m.Name == "Pitt Meadows");

        // Municipality admin mapping
        if (!await db.MunicipalityAdmins.AnyAsync(a => a.ApplicationUserId == pm.Id && a.MunicipalityId == pmEntity.MunicipalityId))
        {
            db.MunicipalityAdmins.Add(new MunicipalityAdmin
            {
                ApplicationUserId = pm.Id,
                MunicipalityId = pmEntity.MunicipalityId
            });
            await db.SaveChangesAsync();
        }

        _ = super;
    }

    private static async Task SeedElectionDataAsync(ApplicationDbContext db)
    {
        var municipalities = await db.Municipalities.ToListAsync();

        foreach (var seed in SeedMunicipalities)
        {
            var municipality = municipalities.FirstOrDefault(m => m.Name == seed.Name);
            if (municipality is null)
            {
                municipality = new Municipality
                {
                    Name = seed.Name,
                    Province = seed.Province,
                    ElectionDate = ElectionDate,
                    Description = seed.Description,
                    LogoFileName = seed.Logo
                };
                db.Municipalities.Add(municipality);
                municipalities.Add(municipality);
            }
            else if (string.IsNullOrWhiteSpace(municipality.LogoFileName))
            {
                municipality.LogoFileName = seed.Logo;
            }
        }

        await db.SaveChangesAsync();

        foreach (var municipality in municipalities)
        {
            foreach (var template in SeedPositions)
            {
                // "Councilor" was the original seed spelling; rename it to the
                // assignment's spelling instead of creating a duplicate position.
                var position = await db.Positions.FirstOrDefaultAsync(p =>
                    p.MunicipalityId == municipality.MunicipalityId &&
                    (p.Name == template.Name ||
                     (template.Name == "Councillor" && p.Name == "Councilor")));

                if (position is null)
                {
                    db.Positions.Add(new Position
                    {
                        Name = template.Name,
                        SeatsAvailable = template.Seats,
                        MunicipalityId = municipality.MunicipalityId
                    });
                }
                else if (position.Name != template.Name)
                {
                    position.Name = template.Name;
                }
            }
        }

        await db.SaveChangesAsync();

        foreach (var seed in SeedCandidates)
        {
            var municipality = municipalities.First(m => m.Name == seed.Municipality);
            var position = await db.Positions.FirstAsync(p =>
                p.MunicipalityId == municipality.MunicipalityId && p.Name == seed.Position);

            var candidate = await db.Candidates.FirstOrDefaultAsync(c =>
                c.Name == seed.Name && c.PositionId == position.PositionId);

            if (candidate is null)
            {
                candidate = new Candidate
                {
                    Name = seed.Name,
                    PositionId = position.PositionId,
                    Profile = string.IsNullOrWhiteSpace(seed.Profile) ? null : seed.Profile,
                    Email = seed.Email,
                    Website = seed.Website,
                    PhotoFileName = seed.Photo,
                    DateCreated = DateTime.UtcNow
                };
                db.Candidates.Add(candidate);
            }
            else if (string.IsNullOrWhiteSpace(candidate.PhotoFileName))
            {
                candidate.PhotoFileName = seed.Photo;
            }
        }

        await db.SaveChangesAsync();

        // A couple of endorsements keep the (bonus) web feature meaningful on a
        // fresh database without duplicating them on later startups.
        var jordan = await db.Candidates
            .Include(c => c.Endorsements)
            .FirstOrDefaultAsync(c => c.Name == "Jordan Lee");

        if (jordan is not null && jordan.Endorsements.Count == 0)
        {
            jordan.Endorsements.Add(new Endorsement
            {
                EndorserName = "Pitt Meadows Chamber of Commerce",
                Organization = "PMCC",
                Text = "A proven leader for our community."
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

        if (!await userManager.IsInRoleAsync(user, role))
        {
            await userManager.AddToRoleAsync(user, role);
        }

        return user;
    }
}

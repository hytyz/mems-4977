using Microsoft.AspNetCore.Hosting;
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
        ("Richmond", "British Columbia", "An island city at the mouth of the Fraser River.", "richmond.png"),
    ];

    private static readonly (string Name, int Seats)[] SeedPositions =
    [
        ("Mayor", 1),
        ("Councillor", 6),
        ("School Trustee", 2),
    ];

    private static readonly Dictionary<(string Municipality, string Position), int> SeatOverrides = new()
    {
        [("Pitt Meadows", "Councillor")] = 5,
    };

    private sealed record SeedCandidate(
        string Name,
        string Municipality,
        string Position,
        string Photo,
        string? Email = null,
        string? Website = null,
        string Profile = "");

    private static readonly SeedCandidate[] SeedCandidates =
    [
        new("Jordan Lee", "Pitt Meadows", "Mayor", "jordan-lee.jpg",
            "jordan.lee@example.com", "https://jordanlee.example.com",
            "Jordan has served on council for eight years and is committed to affordable housing and climate resilience."),
        new("Morgan Chen", "Pitt Meadows", "Mayor", "morgan-chen.jpg",
            "morgan.chen@example.com", null,
            "A small-business owner championing local economic growth and public safety."),
        new("Taylor Singh", "Pitt Meadows", "Councillor", "taylor-singh.jpg",
            null, "https://taylorsingh.example.com",
            "Youth advocate and lifelong Pitt Meadows resident focused on recreation and transit."),
        new("Alex Tran", "Pitt Meadows", "Councillor", "alex-tran.jpg",
            "alex.tran@example.com", null,
            "Urban planner with a passion for walkable neighbourhoods."),
        new("Priya Patel", "Pitt Meadows", "Councillor", "priya-patel.jpg",
            null, null,
            "Teacher and parent advocating for schools and community services."),
        new("Sam Nguyen", "Pitt Meadows", "School Trustee", "sam-nguyen.jpg",
            "sam.nguyen@example.com", null,
            "Education advocate focused on student well-being and modern learning spaces."),

        new("Marcus Bell", "Pitt Meadows", "Councillor", "marcus-bell.png",
            "marcus.bell@example.com", null,
            "Retired engineer focused on dike upgrades and flood preparedness along the Fraser."),
        new("Farah Siddiqui", "Pitt Meadows", "Councillor", "farah-siddiqui.png",
            null, "https://farahsiddiqui.example.com",
            "Small-farm owner advocating for protecting agricultural land and local food."),
        new("Noah Lindqvist", "Pitt Meadows", "Councillor", "noah-lindqvist.png",
            "noah.lindqvist@example.com", null,
            "Paramedic and coach focused on community safety and youth sports facilities."),
        new("Chloe Dubois", "Pitt Meadows", "School Trustee", "chloe-dubois.png",
            "chloe.dubois@example.com", null,
            "French-immersion parent pushing for more program spaces and smaller class sizes."),
        new("Ethan Park", "Pitt Meadows", "School Trustee", "ethan-park.png",
            null, null,
            "Accountant committed to transparent school budgets and safe routes to school."),

        new("Dana Whitfield", "Maple Ridge", "Mayor", "dana-whitfield.jpg",
            "dana.whitfield@example.com", "https://danawhitfield.example.com",
            "Two-term councillor running on sustainable growth and better trail connectivity."),
        new("Liam Bouchard", "Maple Ridge", "Mayor", "liam-bouchard.jpg",
            "liam.bouchard@example.com", null,
            "Local contractor promising faster permits and more rental housing."),
        new("Elena Markovic", "Maple Ridge", "Councillor", "elena-markovic.jpg",
            "elena.markovic@example.com", null,
            "Environmental scientist focused on protecting the Kanaka Creek watershed."),
        new("Grace Okafor", "Maple Ridge", "Councillor", "grace-okafor.jpg",
            null, "https://graceokafor.example.com",
            "Nurse advocating for a walk-in clinic and stronger seniors' services."),
        new("Marcus Hale", "Maple Ridge", "Councillor", "marcus-hale.jpg",
            "marcus.hale@example.com", null,
            "Volunteer firefighter focused on emergency preparedness and road safety."),
        new("Owen Fraser", "Maple Ridge", "Councillor", "owen-fraser.jpg",
            null, null,
            "Youth hockey coach pushing for more recreation space and safer bike routes."),
        new("Ravi Dhillon", "Maple Ridge", "School Trustee", "ravi-dhillon.jpg",
            "ravi.dhillon@example.com", null,
            "Parent and engineer committed to STEM programs and modern school buildings."),
        new("Sophie Lam", "Maple Ridge", "School Trustee", "sophie-lam.jpg",
            null, null,
            "Literacy specialist championing inclusive classrooms and early reading support."),
        new("Helen Zhao", "Burnaby", "Mayor", "helen-zhao.jpg",
            "helen.zhao@example.com", "https://helenzhao.example.com",
            "Transit advocate with a decade of experience on regional committees."),
        new("Thomas Wright", "Burnaby", "Mayor", "thomas-wright.jpg",
            "thomas.wright@example.com", null,
            "Former school principal running on community safety and fiscal responsibility."),
        new("Amara Diallo", "Burnaby", "Councillor", "amara-diallo.jpg",
            "amara.diallo@example.com", null,
            "Housing policy researcher focused on rental protections near SkyTrain stations."),
        new("Daniel Abara", "Burnaby", "Councillor", "daniel-abara.jpg",
            null, "https://danielabara.example.com",
            "Small-business owner working to revitalize the Hastings and Kingsway corridors."),
        new("Isabel Santos", "Burnaby", "Councillor", "isabel-santos.jpg",
            "isabel.santos@example.com", null,
            "Community organizer focused on childcare spaces and newcomer services."),
        new("Kevin Park", "Burnaby", "Councillor", "kevin-park.jpg",
            null, null,
            "Civil engineer prioritizing sidewalks, cycling routes and road maintenance."),
        new("Peter Kowalski", "Burnaby", "Councillor", "peter-kowalski.jpg",
            "peter.kowalski@example.com", null,
            "Retired firefighter advocating for parks, seniors' programs and public safety."),
        new("Mei Tanaka", "Burnaby", "School Trustee", "mei-tanaka.jpg",
            "mei.tanaka@example.com", null,
            "Former teacher championing trades education and after-school programs."),
        new("Nadia Rahman", "Burnaby", "School Trustee", "nadia-rahman.jpg",
            null, "https://nadiarahman.example.com",
            "Parent advocate focused on mental-health supports for students."),
        new("Catherine Yuen", "Richmond", "Mayor", "catherine-yuen.jpg",
            "catherine.yuen@example.com", "https://catherineyuen.example.com",
            "Long-time city councillor focused on dike upgrades and affordable housing."),
        new("Graham Sterling", "Richmond", "Mayor", "graham-sterling.jpg",
            "graham.sterling@example.com", null,
            "Business leader running on economic development and efficient city services."),
        new("Aisha Farouk", "Richmond", "Councillor", "aisha-farouk.jpg",
            "aisha.farouk@example.com", null,
            "Lawyer advocating for tenant protections and accessible city hall services."),
        new("Benjamin Cho", "Richmond", "Councillor", "benjamin-cho.jpg",
            null, "https://benjamincho.example.com",
            "Urban planner focused on transit-oriented growth around the Canada Line."),
        new("Dev Malhotra", "Richmond", "Councillor", "dev-malhotra.jpg",
            "dev.malhotra@example.com", null,
            "Farmer committed to preserving agricultural land and supporting local markets."),
        new("Vivian Leung", "Richmond", "Councillor", "vivian-leung.jpg",
            null, null,
            "Arts administrator pushing for more community and cultural spaces."),
        new("Lorraine Pascal", "Richmond", "School Trustee", "lorraine-pascal.jpg",
            "lorraine.pascal@example.com", null,
            "Retired school counsellor focused on student wellness and inclusion."),
        new("Tobias Reinhardt", "Richmond", "School Trustee", "tobias-reinhardt.jpg",
            null, null,
            "Parent and IT professional championing digital-learning resources."),
        new("Brent Lawson", "Surrey", "Mayor", "brent-lawson.jpg",
            "brent.lawson@example.com", "https://brentlawson.example.com",
            "Former RCMP officer running on public safety and a fully staffed police service."),
        new("Harpreet Gill", "Surrey", "Mayor", "harpreet-gill.jpg",
            "harpreet.gill@example.com", null,
            "Councillor focused on SkyTrain expansion and affordable family housing."),
        new("Anita Verma", "Surrey", "Councillor", "anita-verma.jpg",
            "anita.verma@example.com", null,
            "Social worker advocating for youth programs and homelessness prevention."),
        new("Claire Donovan", "Surrey", "Councillor", "claire-donovan.jpg",
            null, "https://clairedonovan.example.com",
            "Environmental educator focused on protecting the urban tree canopy."),
        new("Colin Mercer", "Surrey", "Councillor", "colin-mercer.jpg",
            "colin.mercer@example.com", null,
            "Small-business owner pushing for faster permits and local hiring."),
        new("Michael Osei", "Surrey", "Councillor", "michael-osei.jpg",
            null, null,
            "Engineer prioritizing roads, sidewalks and safer school zones."),
        new("Jasmine Sandhu", "Surrey", "School Trustee", "jasmine-sandhu.jpg",
            "jasmine.sandhu@example.com", null,
            "Parent advocate fighting overcrowding and portables in Surrey schools."),
        new("Rachel Kim", "Surrey", "School Trustee", "rachel-kim.jpg",
            null, "https://rachelkim.example.com",
            "Former teacher championing early literacy and English-language learner support."),
    ];

    private static readonly (string Name, string Municipality)[] RetiredSeedCandidates =
    [
        ("Emily Carter", "Maple Ridge"),
        ("Daniel Brooks", "Maple Ridge"),
        ("Grace Kim", "Maple Ridge"),
        ("Ravi Sharma", "Burnaby"),
        ("Olivia Martin", "Burnaby"),
        ("Liam O'Connor", "Burnaby"),
        ("Nadia Rahman", "Pitt Meadows"),
        ("Owen Fraser", "Pitt Meadows"),
    ];

    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var webRoot = scope.ServiceProvider.GetRequiredService<IWebHostEnvironment>().WebRootPath;

        db.Database.Migrate();

        await EnsureRoleAsync(roleManager, Roles.SuperAdmin);
        await EnsureRoleAsync(roleManager, Roles.MunicipalityAdmin);

        const string seededPassword = "P@$$w0rd";
        var super = await EnsureUserAsync(userManager, "super", seededPassword, Roles.SuperAdmin);
        var pm = await EnsureUserAsync(userManager, "pm", seededPassword, Roles.MunicipalityAdmin);

        await SeedElectionDataAsync(db, webRoot);

        var pmEntity = await db.Municipalities.FirstAsync(m => m.Name == "Pitt Meadows");

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

    private static async Task SeedElectionDataAsync(ApplicationDbContext db, string webRoot)
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
            else if (ImageMissing(webRoot, "municipalities", municipality.LogoFileName))
            {
                municipality.LogoFileName = seed.Logo;
            }
        }

        await db.SaveChangesAsync();

        foreach (var municipality in municipalities)
        {
            foreach (var template in SeedPositions)
            {
                var seats = SeatOverrides.GetValueOrDefault((municipality.Name, template.Name), template.Seats);
                var position = await db.Positions.FirstOrDefaultAsync(p =>
                    p.MunicipalityId == municipality.MunicipalityId &&
                    (p.Name == template.Name ||
                     (template.Name == "Councillor" && p.Name == "Councilor")));

                if (position is null)
                {
                    db.Positions.Add(new Position
                    {
                        Name = template.Name,
                        SeatsAvailable = seats,
                        MunicipalityId = municipality.MunicipalityId
                    });
                }
                else
                {
                    if (position.Name != template.Name)
                    {
                        position.Name = template.Name;
                    }

                    if (seats != template.Seats && position.SeatsAvailable == template.Seats)
                    {
                        position.SeatsAvailable = seats;
                    }
                }
            }
        }

        await db.SaveChangesAsync();

        foreach (var (name, municipalityName) in RetiredSeedCandidates)
        {
            var retired = await db.Candidates
                .Where(c => c.Name == name && c.Position!.Municipality!.Name == municipalityName)
                .ToListAsync();
            db.Candidates.RemoveRange(retired);
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
            else if (ImageMissing(webRoot, "candidates", candidate.PhotoFileName))
            {
                candidate.PhotoFileName = seed.Photo;
            }
        }

        await db.SaveChangesAsync();

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

    private static bool ImageMissing(string webRoot, string folder, string? fileName) =>
        string.IsNullOrWhiteSpace(fileName)
        || !File.Exists(Path.Combine(webRoot, "uploads", folder, fileName));

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

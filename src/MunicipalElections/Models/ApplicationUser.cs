using Microsoft.AspNetCore.Identity;

namespace MunicipalElections.Models;

public class ApplicationUser : IdentityUser
{
    public ICollection<MunicipalityAdmin> MunicipalityAdmins { get; set; } = new List<MunicipalityAdmin>();
}

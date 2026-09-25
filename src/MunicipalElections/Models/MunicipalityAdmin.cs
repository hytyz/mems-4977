namespace MunicipalElections.Models;

public class MunicipalityAdmin
{
    public string ApplicationUserId { get; set; } = string.Empty;
    public ApplicationUser? ApplicationUser { get; set; }

    public int MunicipalityId { get; set; }
    public Municipality? Municipality { get; set; }
}

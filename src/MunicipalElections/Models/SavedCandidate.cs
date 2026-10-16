using System.ComponentModel.DataAnnotations;

namespace MunicipalElections.Models;

public class SavedCandidate
{
    public int Id { get; set; }

    [Required]
    [MaxLength(450)]
    public string UserId { get; set; } = string.Empty;

    public int CandidateId { get; set; }

    public DateTime DateSaved { get; set; } = DateTime.UtcNow;

    public ApplicationUser? User { get; set; }
    public Candidate? Candidate { get; set; }
}

using System.ComponentModel.DataAnnotations;

namespace MunicipalElections.Models;

public class Endorsement
{
    public int EndorsementId { get; set; }

    [Required(ErrorMessage = "Endorser name is required.")]
    [StringLength(100, ErrorMessage = "Endorser name cannot exceed 100 characters.")]
    public string EndorserName { get; set; } = string.Empty;

    [StringLength(150, ErrorMessage = "Organization cannot exceed 150 characters.")]
    public string? Organization { get; set; }

    [StringLength(1000, ErrorMessage = "Endorsement text cannot exceed 1000 characters.")]
    public string? Text { get; set; }

    public int CandidateId { get; set; }
    public Candidate? Candidate { get; set; }
}

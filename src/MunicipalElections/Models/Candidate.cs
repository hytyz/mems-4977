using System.ComponentModel.DataAnnotations;

namespace MunicipalElections.Models;

public class Candidate
{
    public int CandidateId { get; set; }

    [Required(ErrorMessage = "Candidate name is required.")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "Candidate name must be between 2 and 100 characters.")]
    public string Name { get; set; } = string.Empty;

    [StringLength(2000, ErrorMessage = "Biography cannot exceed 2000 characters.")]
    public string? Profile { get; set; }

    public string? PhotoFileName { get; set; }

    [Url(ErrorMessage = "Website must be a valid URL.")]
    [StringLength(300, ErrorMessage = "Website URL cannot exceed 300 characters.")]
    public string? Website { get; set; }

    [EmailAddress(ErrorMessage = "Email must be a valid email address.")]
    [StringLength(254, ErrorMessage = "Email cannot exceed 254 characters.")]
    public string? Email { get; set; }

    public DateTime DateCreated { get; set; } = DateTime.UtcNow;

    public int PositionId { get; set; }
    public Position? Position { get; set; }

    [Url(ErrorMessage = "Video URL must be a valid URL.")]
    [StringLength(300)]
    public string? VideoUrl { get; set; }

    [Url(ErrorMessage = "X (Twitter) URL must be a valid URL.")]
    [StringLength(300)]
    public string? SocialX { get; set; }

    [Url(ErrorMessage = "Facebook URL must be a valid URL.")]
    [StringLength(300)]
    public string? SocialFacebook { get; set; }

    [Url(ErrorMessage = "Instagram URL must be a valid URL.")]
    [StringLength(300)]
    public string? SocialInstagram { get; set; }

    [Url(ErrorMessage = "LinkedIn URL must be a valid URL.")]
    [StringLength(300)]
    public string? SocialLinkedIn { get; set; }

    public ICollection<Endorsement> Endorsements { get; set; } = new List<Endorsement>();
}

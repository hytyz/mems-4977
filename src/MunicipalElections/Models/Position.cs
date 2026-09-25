using System.ComponentModel.DataAnnotations;

namespace MunicipalElections.Models;

public class Position
{
    public int PositionId { get; set; }

    [Required(ErrorMessage = "Position name is required.")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "Position name must be between 2 and 100 characters.")]
    public string Name { get; set; } = string.Empty;

    [Required(ErrorMessage = "Number of available seats is required.")]
    [Range(1, 100, ErrorMessage = "Seats available must be between 1 and 100.")]
    public int SeatsAvailable { get; set; }

    public int MunicipalityId { get; set; }
    public Municipality? Municipality { get; set; }

    public ICollection<Candidate> Candidates { get; set; } = new List<Candidate>();
}

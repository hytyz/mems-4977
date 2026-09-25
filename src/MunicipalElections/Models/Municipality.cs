using System.ComponentModel.DataAnnotations;

namespace MunicipalElections.Models;

public class Municipality
{
    public int MunicipalityId { get; set; }

    [Required(ErrorMessage = "Municipality name is required.")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "Municipality name must be between 2 and 100 characters.")]
    public string Name { get; set; } = string.Empty;

    [Required(ErrorMessage = "Province is required.")]
    [StringLength(50, MinimumLength = 2, ErrorMessage = "Province must be between 2 and 50 characters.")]
    public string Province { get; set; } = string.Empty;

    [Required(ErrorMessage = "Election date is required.")]
    [DataType(DataType.Date)]
    public DateTime ElectionDate { get; set; }

    [StringLength(2000, ErrorMessage = "Description cannot exceed 2000 characters.")]
    public string? Description { get; set; }

    public string? LogoFileName { get; set; }

    public ICollection<Position> Positions { get; set; } = new List<Position>();
    public ICollection<MunicipalityAdmin> MunicipalityAdmins { get; set; } = new List<MunicipalityAdmin>();
}

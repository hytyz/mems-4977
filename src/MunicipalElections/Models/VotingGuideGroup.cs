namespace MunicipalElections.Models;

public class VotingGuideGroup
{
    public Municipality Municipality { get; set; } = new();
    public List<Candidate> Candidates { get; set; } = new();
}

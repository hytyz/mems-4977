using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Data;
using MunicipalElections.Models;
using MunicipalElections.Services;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace MunicipalElections.Controllers;

public class VotingGuideController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly VotingGuideService _guide;
    private readonly IWebHostEnvironment _env;

    public VotingGuideController(ApplicationDbContext context, VotingGuideService guide, IWebHostEnvironment env)
    {
        _context = context;
        _guide = guide;
        _env = env;
    }

    public async Task<IActionResult> Index()
    {
        var model = await LoadSelectedCandidatesAsync();
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Add(int candidateId)
    {
        _guide.Add(candidateId);
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Remove(int candidateId)
    {
        _guide.Remove(candidateId);
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Clear()
    {
        _guide.Clear();
        return RedirectToAction(nameof(Index));
    }

    public async Task<IActionResult> Print()
    {
        var model = await LoadSelectedCandidatesAsync();
        return View(model);
    }

    public async Task<IActionResult> ExportPdf()
    {
        QuestPDF.Settings.License = LicenseType.Community;

        var model = await LoadSelectedCandidatesAsync();

        var document = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Margin(48);
                page.Size(PageSizes.A4);

                page.Header().PaddingBottom(8).Column(column =>
                {
                    column.Item().Text("Municipal Elections Management System")
                        .FontSize(18).Bold();
                    column.Item().Text($"Personal Voting Guide — Printed {DateTime.Now:MMMM d, yyyy}");
                });

                page.Content().Column(content =>
                {
                    int index = 0;
                    foreach (var group in model)
                    {
                        content.Item().PaddingTop(12).Text($"{group.Municipality.Name} — Election: {group.Municipality.ElectionDate:MMMM d, yyyy}")
                            .FontSize(13).Bold();

                        foreach (var candidate in group.Candidates)
                        {
                            index++;
                            content.Item().PaddingTop(8).PaddingLeft(8).BorderBottom(1).BorderColor(Colors.Grey.Lighten2).Column(row =>
                            {
                                row.Item().Text($"{index}. {candidate.Name}").Bold();
                                row.Item().Text($"Position: {candidate.Position!.Name} ({candidate.Position.SeatsAvailable} seat(s))");
                                if (!string.IsNullOrWhiteSpace(candidate.Profile))
                                {
                                    row.Item().Text(candidate.Profile);
                                }
                            });
                        }
                    }
                });
            });
        });

        using var stream = new MemoryStream();
        document.GeneratePdf(stream);
        return File(stream.ToArray(), "application/pdf", "voting-guide.pdf");
    }

    private async Task<List<VotingGuideGroup>> LoadSelectedCandidatesAsync()
    {
        var ids = _guide.GetIds();
        var candidates = await _context.Candidates
            .Where(c => ids.Contains(c.CandidateId))
            .Include(c => c.Position)
                .ThenInclude(p => p!.Municipality)
            .ToListAsync();

        return candidates
            .GroupBy(c => c.Position!.Municipality!)
            .Select(g => new VotingGuideGroup
            {
                Municipality = g.Key,
                Candidates = g.OrderBy(c => c.Position!.Name).ThenBy(c => c.Name).ToList()
            })
            .OrderBy(g => g.Municipality.Name)
            .ToList();
    }
}


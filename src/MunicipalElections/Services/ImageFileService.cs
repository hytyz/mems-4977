using MunicipalElections.Data;

namespace MunicipalElections.Services;

public class ImageFileService
{
    private const long MaxBytes = 5 * 1024 * 1024;
    private static readonly string[] AllowedExtensions = [".jpg", ".jpeg", ".png", ".gif", ".webp"];

    private readonly IWebHostEnvironment _env;

    public ImageFileService(IWebHostEnvironment env)
    {
        _env = env;
    }

    public string? Save(IFormFile? file, string subfolder, out string? error)
    {
        error = null;
        if (file is null || file.Length == 0)
        {
            return null;
        }

        if (file.Length > MaxBytes)
        {
            error = "Image must be 5 MB or smaller.";
            return null;
        }

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!AllowedExtensions.Contains(extension))
        {
            error = "Only JPG, JPEG, PNG, GIF and WEBP images are allowed.";
            return null;
        }

        string fileName = $"{Guid.NewGuid():N}{extension}";
        string uploadsRoot = Path.Combine(_env.WebRootPath, "uploads", subfolder);
        Directory.CreateDirectory(uploadsRoot);
        string filePath = Path.Combine(uploadsRoot, fileName);

        using var stream = new FileStream(filePath, FileMode.Create);
        file.CopyTo(stream);

        return fileName;
    }

    public void Delete(string? fileName, string subfolder)
    {
        if (string.IsNullOrWhiteSpace(fileName))
        {
            return;
        }

        string filePath = Path.Combine(_env.WebRootPath, "uploads", subfolder, fileName);
        if (File.Exists(filePath))
        {
            File.Delete(filePath);
        }
    }
}

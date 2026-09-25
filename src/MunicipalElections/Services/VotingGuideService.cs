using Microsoft.Extensions.Caching.Distributed;
using System.Text.Json;

namespace MunicipalElections.Services;

public class VotingGuideService
{
    private const string SessionKey = "VotingGuide";

    private readonly IHttpContextAccessor _http;

    public VotingGuideService(IHttpContextAccessor http)
    {
        _http = http;
    }

    public List<int> GetIds()
    {
        var session = _http.HttpContext!.Session;
        string? json = session.GetString(SessionKey);
        if (string.IsNullOrEmpty(json))
        {
            return new List<int>();
        }

        try
        {
            return JsonSerializer.Deserialize<List<int>>(json) ?? new List<int>();
        }
        catch (JsonException)
        {
            return new List<int>();
        }
    }

    public bool Contains(int candidateId) => GetIds().Contains(candidateId);

    public void Add(int candidateId)
    {
        var ids = GetIds();
        if (!ids.Contains(candidateId))
        {
            ids.Add(candidateId);
            Save(ids);
        }
    }

    public void Remove(int candidateId)
    {
        var ids = GetIds();
        if (ids.Remove(candidateId))
        {
            Save(ids);
        }
    }

    public void Clear()
    {
        _http.HttpContext!.Session.Remove(SessionKey);
    }

    private void Save(List<int> ids)
    {
        _http.HttpContext!.Session.SetString(SessionKey, JsonSerializer.Serialize(ids));
    }
}

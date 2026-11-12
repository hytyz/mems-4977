using System.IdentityModel.Tokens.Jwt;
using System.Security.Cryptography;
using System.Text.Json;
using Microsoft.IdentityModel.Tokens;

namespace MunicipalElections.Auth;

public sealed class FirebaseTokenService : IDisposable
{
    private const string Audience =
        "https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit";

    private static readonly TimeSpan Lifetime = TimeSpan.FromMinutes(55);

    private readonly string? _serviceAccountEmail;
    private readonly RSA? _rsa;
    private readonly SigningCredentials? _credentials;

    public FirebaseTokenService(IConfiguration config, ILogger<FirebaseTokenService> logger)
    {
        var section = config.GetSection("Firebase");
        var email = section["ServiceAccountEmail"];
        var privateKey = section["PrivateKey"];

        var json = section["ServiceAccountJson"];
        if (!string.IsNullOrWhiteSpace(json))
        {
            try
            {
                using var document = JsonDocument.Parse(json);
                email = document.RootElement.GetProperty("client_email").GetString();
                privateKey = document.RootElement.GetProperty("private_key").GetString();
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Firebase:ServiceAccountJson is not a valid service-account key file.");
            }
        }

        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(privateKey))
        {
            logger.LogWarning(
                "Firebase service account is not configured; /api/auth/firebase-token will return 503.");
            return;
        }

        try
        {
            var rsa = RSA.Create();
            rsa.ImportFromPem(privateKey.Replace("\\n", "\n"));
            _rsa = rsa;
            _serviceAccountEmail = email.Trim();
            _credentials = new SigningCredentials(new RsaSecurityKey(rsa), SecurityAlgorithms.RsaSha256);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "The Firebase service-account private key could not be read.");
        }
    }

    public bool IsConfigured => _credentials is not null;

    public string CreateCustomToken(string uid)
    {
        if (_credentials is null || _serviceAccountEmail is null)
        {
            throw new InvalidOperationException("Firebase service account is not configured.");
        }

        var now = DateTimeOffset.UtcNow;
        var payload = new JwtPayload
        {
            { "iss", _serviceAccountEmail },
            { "sub", _serviceAccountEmail },
            { "aud", Audience },
            { "iat", now.ToUnixTimeSeconds() },
            { "exp", now.Add(Lifetime).ToUnixTimeSeconds() },
            { "uid", uid }
        };

        var token = new JwtSecurityToken(new JwtHeader(_credentials), payload);
        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public void Dispose() => _rsa?.Dispose();
}

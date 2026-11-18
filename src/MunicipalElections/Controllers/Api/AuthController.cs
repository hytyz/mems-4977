using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using MunicipalElections.Auth;
using MunicipalElections.DTOs.Api;
using MunicipalElections.Models;

namespace MunicipalElections.Controllers.Api;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly JwtTokenService _jwt;
    private readonly FirebaseTokenService _firebase;

    public AuthController(
        UserManager<ApplicationUser> userManager,
        SignInManager<ApplicationUser> signInManager,
        JwtTokenService jwt,
        FirebaseTokenService firebase)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _jwt = jwt;
        _firebase = firebase;
    }

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> Register(AuthRequest request)
    {
        var email = request.Email.Trim();
        var fullName = request.FullName.Trim();

        if (fullName.Length == 0)
        {
            ModelState.AddModelError(nameof(request.FullName), "Name is required.");
            return ValidationProblem(ModelState);
        }

        var existing = await _userManager.FindByEmailAsync(email);
        if (existing is not null)
        {
            return Problem(
                statusCode: StatusCodes.Status400BadRequest,
                title: "Registration failed",
                detail: "An account with this email already exists.");
        }

        var user = new ApplicationUser
        {
            UserName = email,
            Email = email,
            EmailConfirmed = true
        };

        var result = await _userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
        {
            return Problem(
                statusCode: StatusCodes.Status400BadRequest,
                title: "Registration failed",
                detail: string.Join(" ", result.Errors.Select(e => e.Description)));
        }

        await _userManager.AddClaimAsync(user, new Claim(ClaimTypes.Name, fullName));

        var token = _jwt.CreateToken(user.Id, user.Email ?? email, fullName);
        return Ok(new AuthResponse(token, user.Email ?? email, fullName));
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> Login(AuthLoginRequest request)
    {
        var email = request.Email.Trim();
        var user = await _userManager.FindByEmailAsync(email);
        if (user is null)
        {
            return BuildUnauthorized();
        }

        var signIn = await _signInManager.CheckPasswordSignInAsync(user, request.Password, lockoutOnFailure: false);
        if (!signIn.Succeeded)
        {
            return BuildUnauthorized();
        }

        var claims = await _userManager.GetClaimsAsync(user);
        var fullName = claims.FirstOrDefault(c => c.Type == ClaimTypes.Name)?.Value
            ?? user.UserName
            ?? user.Email
            ?? email;

        var token = _jwt.CreateToken(user.Id, user.Email ?? email, fullName);
        return Ok(new AuthResponse(token, user.Email ?? email, fullName));
    }

    [HttpGet("firebase-token")]
    [Authorize(AuthenticationSchemes = ApiAuth.JwtScheme)]
    public async Task<ActionResult<FirebaseTokenResponse>> FirebaseToken()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var user = userId is null ? null : await _userManager.FindByIdAsync(userId);
        if (user is null || string.IsNullOrWhiteSpace(user.Email))
        {
            return BuildUnauthorized("This account is no longer available. Please sign in again.");
        }

        if (!_firebase.IsConfigured)
        {
            return Problem(
                statusCode: StatusCodes.Status503ServiceUnavailable,
                title: "Firebase is not configured",
                detail: "The server has no Firebase service account, so candidate selections are unavailable.");
        }

        var token = _firebase.CreateCustomToken(user.Id, user.Email);
        return Ok(new FirebaseTokenResponse(token, user.Id, user.Email));
    }

    private static ActionResult BuildUnauthorized(string detail = "Invalid email or password.") =>
        new UnauthorizedObjectResult(new
        {
            status = 401,
            title = "Authentication failed",
            detail
        });
}

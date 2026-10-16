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
[AllowAnonymous]
public class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly JwtTokenService _jwt;

    public AuthController(
        UserManager<ApplicationUser> userManager,
        SignInManager<ApplicationUser> signInManager,
        JwtTokenService jwt)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _jwt = jwt;
    }

    [HttpPost("register")]
    public async Task<ActionResult<AuthResponse>> Register(AuthRequest request)
    {
        var email = request.Email.Trim();

        // Identity is configured with RequireUniqueEmail = false, so the API
        // enforces uniqueness itself with a clear error message.
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

        // ApplicationUser has no FullName property; persist the display name
        // as a "name" claim so login can return it.
        if (!string.IsNullOrWhiteSpace(request.FullName))
        {
            await _userManager.AddClaimAsync(user, new Claim(ClaimTypes.Name, request.FullName.Trim()));
        }

        var token = _jwt.CreateToken(user.Id, user.Email ?? email, request.FullName.Trim());
        return Ok(new AuthResponse(token, user.Email ?? email, request.FullName.Trim()));
    }

    [HttpPost("login")]
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

    private static ActionResult BuildUnauthorized() => new UnauthorizedObjectResult(new
    {
        status = 401,
        title = "Authentication failed",
        detail = "Invalid email or password."
    });
}

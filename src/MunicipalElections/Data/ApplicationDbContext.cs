using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Models;

namespace MunicipalElections.Data;

public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Municipality> Municipalities => Set<Municipality>();
    public DbSet<Position> Positions => Set<Position>();
    public DbSet<Candidate> Candidates => Set<Candidate>();
    public DbSet<Endorsement> Endorsements => Set<Endorsement>();
    public DbSet<MunicipalityAdmin> MunicipalityAdmins => Set<MunicipalityAdmin>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<Municipality>(entity =>
        {
            entity.HasIndex(m => m.Name).IsUnique();
            entity.Property(m => m.Name).HasMaxLength(100);
            entity.Property(m => m.Province).HasMaxLength(50);
            entity.Property(m => m.Description).HasMaxLength(2000);
            entity.Property(m => m.LogoFileName).HasMaxLength(300);
        });

        builder.Entity<Position>(entity =>
        {
            entity.Property(p => p.Name).HasMaxLength(100);
            entity.HasOne(p => p.Municipality)
                .WithMany(m => m.Positions)
                .HasForeignKey(p => p.MunicipalityId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<Candidate>(entity =>
        {
            entity.Property(c => c.Name).HasMaxLength(100);
            entity.Property(c => c.Profile).HasMaxLength(2000);
            entity.Property(c => c.PhotoFileName).HasMaxLength(300);
            entity.Property(c => c.Website).HasMaxLength(300);
            entity.Property(c => c.Email).HasMaxLength(254);
            entity.Property(c => c.VideoUrl).HasMaxLength(300);
            entity.Property(c => c.SocialX).HasMaxLength(300);
            entity.Property(c => c.SocialFacebook).HasMaxLength(300);
            entity.Property(c => c.SocialInstagram).HasMaxLength(300);
            entity.Property(c => c.SocialLinkedIn).HasMaxLength(300);
            entity.HasOne(c => c.Position)
                .WithMany(p => p.Candidates)
                .HasForeignKey(c => c.PositionId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<Endorsement>(entity =>
        {
            entity.Property(e => e.EndorserName).HasMaxLength(100);
            entity.Property(e => e.Organization).HasMaxLength(150);
            entity.Property(e => e.Text).HasMaxLength(1000);
            entity.HasOne(e => e.Candidate)
                .WithMany(c => c.Endorsements)
                .HasForeignKey(e => e.CandidateId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<MunicipalityAdmin>(entity =>
        {
            entity.HasKey(ma => new { ma.ApplicationUserId, ma.MunicipalityId });
            entity.HasOne(ma => ma.ApplicationUser)
                .WithMany(u => u.MunicipalityAdmins)
                .HasForeignKey(ma => ma.ApplicationUserId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(ma => ma.Municipality)
                .WithMany(m => m.MunicipalityAdmins)
                .HasForeignKey(ma => ma.MunicipalityId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}

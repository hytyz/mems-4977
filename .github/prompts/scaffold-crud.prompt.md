# Scaffold CRUD

Generate an ASP.NET Core MVC controller with async CRUD actions for an EF Core entity.
- Place admin controllers under Areas/Admin/Controllers with namespace MunicipalElections.Areas.Admin.Controllers.
- Add [Authorize(Roles = "SuperAdmin,MunicipalityAdmin")] (SuperAdmin only for Municipality).
- Scoped users must only see/edit data in their assigned municipalities.
- Include server-side validation and matching Bootstrap views with client-side validation.

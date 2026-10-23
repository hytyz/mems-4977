Municipal Elections Management System
=====================================

Team
----
Polina Omelyantseva

Contributions
-------------
Polina Omelyantseva:
- Designed the EF Core Code First domain model (Municipality, Position, Candidate, Endorsement, MunicipalityAdmin)
- Scaffolded the ASP.NET Core MVC solution and generated the InitialCreate migration with the EF Core CLI
- Implemented ASP.NET Core Identity authentication/authorization with SuperAdmin and municipality-scoped admin roles
- Built public candidate directory (search, filter, pagination), candidate comparison, and dark mode
- Built the session-based personal voting guide with printer view and PDF export
- Implemented admin area CRUD for municipalities, positions, and candidates, including image upload
- Created the dev container, helper scripts, and this documentation
- Deployed the application to Azure App Service with the az CLI

Major challenges encountered
----------------------------
- .NET SDK was not installed on my linux laptop, so all development ran inside a Podman
  dev container using the mcr.microsoft.com/dotnet/sdk:10.0 image. This was much faster than a full ide install on Linux. 
- The ASP.NET code generator does not support scaffolding into an Area directly;
  Admin controllers were generated into the target folder/namespace and their views
  were authored by hand.

Deployed application URL
------------------------
https://mems-assignment-app.azurewebsites.net

Github Repository URL
------------------------
https://github.com/hytyz/mems-4977/tree/master
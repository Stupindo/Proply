# Use the official .NET 9 SDK image as the build environment.
# 'AS build' names this stage, so we can refer to it later.
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy the project file and restore dependencies.
# This is done in a separate layer to leverage Docker's layer caching.
# Dependencies are only re-downloaded if the .csproj file changes.
COPY ["Proply.API/Proply.API.csproj", "Proply.API/"]
RUN dotnet restore "Proply.API/Proply.API.csproj"

# Copy the rest of the source code.
COPY . .
WORKDIR "/src/Proply.API"

# Build the application in Release configuration.
RUN dotnet build "Proply.API.csproj" -c Release -o /app/build

# Publish the application from the build stage.
FROM build AS publish
RUN dotnet publish "Proply.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# --- Final Stage ---
# Use the smaller ASP.NET 9 runtime image for the final production image.
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app

# Copy the published output from the 'publish' stage.
COPY --from=publish /app/publish .

# Expose port 8080 for the application. This is the default port for .NET containers.
EXPOSE 8080
ENTRYPOINT ["dotnet", "Proply.API.dll"]
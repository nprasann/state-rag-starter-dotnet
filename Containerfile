FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY state-rag-starter-dotnet.sln ./
COPY src/StateRagStarter.Api/StateRagStarter.Api.csproj src/StateRagStarter.Api/
RUN dotnet restore src/StateRagStarter.Api/StateRagStarter.Api.csproj

COPY src/StateRagStarter.Api/ src/StateRagStarter.Api/
RUN dotnet publish src/StateRagStarter.Api/StateRagStarter.Api.csproj \
    --configuration Release \
    --output /app/publish \
    --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "StateRagStarter.Api.dll"]

# Sessions

## Purpose
- Public .NET starter API for state-aware retrieval augmented generation experiments.
- Demonstrates jurisdiction/state filtering before LLM answer generation.
- Keeps the baseline dependency-light with no external NuGet packages.
- Provides container, Bicep, and Azure DevOps deployment scaffolding.
- Serves as a portable foundation for future persistence, retrieval, and LLM integrations.

## Architecture Snapshot
- Main components:
  - ASP.NET Core Minimal API in `src/StateRagStarter.Api/Program.cs`.
  - In-memory `StateDocumentStore` backed by `ConcurrentDictionary`.
  - OCI-compatible container build through `Containerfile`.
  - Azure infrastructure scaffold in `infra/bicep/main.bicep`.
  - Azure DevOps pipeline in `azure-pipelines.yml`.
- High-level data flow:
  - Client sends HTTP JSON request.
  - API validates input and routes to in-memory store.
  - Store optionally filters documents by state.
  - Keyword scoring selects matching source documents.
  - API returns placeholder answer plus source records.
- Runtime model:
  - Targets .NET 10.
  - Runs locally on Kestrel.
  - Container listens on port `8080`.
  - Local `dotnet run` commonly listens on `http://localhost:5000`.
  - Cloud scaffold targets Azure Container Apps.

## Current Implemented State
- Existing folders/files:
  - `src/StateRagStarter.Api/`
  - `docs/architecture.md`
  - `docs/azure-devops.md`
  - `infra/bicep/main.bicep`
  - `azure-pipelines.yml`
  - `Containerfile`
  - `.dockerignore`
  - `README.md`
  - `CONTRIBUTING.md`
  - `LICENSE`
  - `state-rag-starter-dotnet.sln`
- Working features:
  - `GET /` returns API discovery JSON.
  - `GET /health` returns service health JSON.
  - `GET /documents` lists seeded documents.
  - `GET /documents?state=CA` filters documents by state.
  - `POST /documents` adds or updates in-memory documents.
  - `POST /query` returns keyword-matched source records with placeholder answer text.
  - `dotnet build` succeeds with .NET 10.
- Known assumptions:
  - Data is not persisted after process restart.
  - LLM, model, embeddings, and AI API are not configured.
  - Azure SQL is scaffolded as infrastructure but not wired into application storage.
  - Azure DevOps pipeline expects a valid Azure service connection.
  - Pipeline requires `sqlAdminPassword` as a secret variable when deploying database resources.
  - Bicep and Azure pipeline deployment require validation in an Azure-enabled environment.

## Open Work / Next Steps
- Add tests for API endpoints and retrieval behavior.
- Add source citation fields and snippets to query responses.
- Introduce storage abstraction before adding a database provider.
- Implement SQL Server or Azure SQL persistence behind the storage abstraction.
- Add configuration-driven storage provider selection.
- Validate Bicep template with Azure CLI or Azure DevOps.
- Run Azure DevOps pipeline in a sandbox subscription.
- Add LLM answer-generation service behind an interface.
- Add embeddings and vector search after persistence is stable.
- Add authentication and authorization if the API becomes externally accessible.
- Add OpenAPI documentation if external package approval allows it.

## Decisions
- Use .NET 10 and ASP.NET Core Minimal API.
- Keep baseline free of external NuGet packages.
- Use Kestrel as the application server.
- Use in-memory storage for the initial runnable baseline.
- Return placeholder answer text until an LLM provider is explicitly added.
- Use state filtering as a first-class retrieval input.
- Use an OCI-compatible `Containerfile` for Podman and registry builds.
- Use Bicep for Azure infrastructure as code.
- Use Azure Container Apps as the cloud container target.
- Include Azure SQL in infrastructure scaffold, but do not wire application persistence yet.
- Use Azure DevOps YAML for build, deploy, smoke test, and destroy workflows.
- Keep this sessions file append-only going forward.

## Session Log
- Date: 2026-04-30
- Summary:
  - Added sanitized session-continuation documentation for future AI/code sessions.
  - Captured current repo architecture, implemented state, assumptions, decisions, and next steps.
- Decisions:
  - Keep session notes technical and public-repo safe.
  - Avoid duplicating detailed setup instructions already present in README and docs.
  - Keep entries short and append-only.
- Files modified:
  - `docs/sessions.md`
- Validation:
  - Repo inspected before writing.
  - File kept under 200 lines.
  - No source code pasted.
  - No private prompts, real data, personal strategy, or internal references included.

- Date: 2026-04-30
- Summary:
  - Added public README stack/version badges near the project title.
  - Matched the compact badge style used by related public repositories.
  - Kept the update limited to documentation.
- Decisions:
  - Used stack and version values already present in repository files.
  - Avoided changing runtime code, dependencies, or deployment configuration.
- Files modified:
  - `README.md`
- Validation:
  - `git diff -- README.md`
  - `git status --short`
  - Manual review for public-repo-safe content.

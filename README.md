# State RAG Starter for .NET

An open-source .NET starter API for experimenting with state-aware retrieval augmented generation.

This project is intentionally small at the baseline: it stores documents in memory, filters them by U.S. state, and returns matching source records. It is a clean foundation for adding an LLM, embeddings, vector search, persistence, and citations.

## Software Stack

| Area | Software |
| --- | --- |
| Language | C# |
| Runtime | .NET 10 |
| Web framework | ASP.NET Core Minimal API |
| Web server | Kestrel |
| API style | HTTP JSON API |
| Storage | In-memory `ConcurrentDictionary` |
| Retrieval | Simple keyword scoring |
| LLM | Not wired yet |
| Model | Not configured yet |
| AI API | Not configured yet |
| Vector database | Not configured yet |
| Package dependencies | No external NuGet packages |
| License | MIT |

## Current AI/LLM Status

The current version does **not** call an LLM yet. The `/query` endpoint performs a lightweight retrieval step and returns matching source documents with a placeholder answer.

Recommended next integrations:

| Capability | Suggested option |
| --- | --- |
| Chat/completion model | OpenAI GPT model, Azure OpenAI model, or another hosted LLM |
| Embeddings model | OpenAI embeddings, Azure OpenAI embeddings, or local embeddings |
| Vector search | PostgreSQL + pgvector, Qdrant, Weaviate, Azure AI Search, or Pinecone |
| Persistence | SQLite for local development, PostgreSQL for production |

The architecture notes are in [docs/architecture.md](docs/architecture.md).

## API Endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/health` | Service health check |
| `GET` | `/documents` | List stored documents |
| `GET` | `/documents?state=CA` | List stored documents filtered by state |
| `POST` | `/documents` | Add or update state-specific source text |
| `POST` | `/query` | Retrieve relevant state-specific sources |

`http://localhost:5000` is intentionally not a web page. This is an API project, so use `/health`, `/documents`, or `/query`.

## Prerequisites

- Git
- .NET 10 SDK
- Optional: Visual Studio Code with the C# Dev Kit extension

Check your .NET installation:

```bash
dotnet --info
dotnet --list-sdks
```

## macOS Setup

### Install with Homebrew

```bash
brew update
brew install dotnet-sdk
dotnet --info
```

If `dotnet` is not found after installation, close and reopen Terminal. On Apple Silicon Macs, Homebrew commonly installs command-line tools under `/opt/homebrew/bin`.

### Install with Microsoft Installer

1. Go to [dotnet.microsoft.com/download/dotnet](https://dotnet.microsoft.com/download/dotnet).
2. Download the .NET SDK for macOS.
3. Open the `.pkg` installer.
4. Restart Terminal.
5. Run:

```bash
dotnet --info
```

## Windows Setup

### Install with winget

Open PowerShell:

```powershell
winget install Microsoft.DotNet.SDK.10
dotnet --info
```

### Install with Microsoft Installer

1. Go to [dotnet.microsoft.com/download/dotnet](https://dotnet.microsoft.com/download/dotnet).
2. Download the .NET SDK for Windows.
3. Run the installer.
4. Open a new PowerShell window.
5. Run:

```powershell
dotnet --info
```

## Linux Setup

Microsoft publishes distro-specific .NET install instructions. Start here:

[Install .NET on Linux](https://learn.microsoft.com/en-us/dotnet/core/install/linux)

For Ubuntu, the flow is typically:

```bash
sudo apt-get update
sudo apt-get install -y dotnet-sdk-10.0
dotnet --info
```

If your distro does not have the Microsoft package feed configured yet, follow the Microsoft Linux install page for your distribution and version.

## Run from Terminal

From the project root:

```bash
dotnet restore
dotnet build
dotnet run --project src/StateRagStarter.Api
```

The API prints a local URL, usually:

```text
http://localhost:5000
```

Try the health endpoint:

```bash
curl http://localhost:5000/health
```

List seeded documents:

```bash
curl http://localhost:5000/documents
```

Query the seeded documents:

```bash
curl -X POST http://localhost:5000/query \
  -H "Content-Type: application/json" \
  -d '{"question":"What should I know about California leave rules?","state":"CA","topK":3}'
```

Add a document:

```bash
curl -X POST http://localhost:5000/documents \
  -H "Content-Type: application/json" \
  -d '{"state":"TX","title":"Texas Example","content":"Texas-specific source content goes here.","tags":["texas","example"]}'
```

## Run from VS Code

1. Install [Visual Studio Code](https://code.visualstudio.com/).
2. Install the **C# Dev Kit** extension.
3. Open this repository folder in VS Code.
4. Open the integrated terminal with `Control` + `` ` `` on macOS/Linux or `Ctrl` + `` ` `` on Windows.
5. Run:

```bash
dotnet restore
dotnet run --project src/StateRagStarter.Api
```

For debugging:

1. Open `src/StateRagStarter.Api/Program.cs`.
2. Press `F5`.
3. If VS Code asks to create debug assets, accept.
4. Choose the API project.

## Production Hosting Notes

ASP.NET Core uses Kestrel as the application web server.

Common hosting patterns:

| Environment | Typical front end | App server |
| --- | --- | --- |
| Local development | Browser or curl | Kestrel |
| Windows production | IIS reverse proxy | Kestrel |
| Linux production | Nginx or Apache reverse proxy | Kestrel |
| Containers/cloud | Load balancer or ingress | Kestrel |

## Repository Layout

```text
.
├── docs/
│   └── architecture.md
├── src/
│   └── StateRagStarter.Api/
│       ├── Program.cs
│       └── StateRagStarter.Api.csproj
├── CONTRIBUTING.md
├── LICENSE
├── README.md
└── state-rag-starter-dotnet.sln
```

## Next Open-Source Milestones

- Add a root endpoint with API discovery JSON.
- Add persistent storage with SQLite or PostgreSQL.
- Add embeddings and vector search.
- Add an LLM answer-generation service.
- Add source citations to generated answers.
- Add tests with xUnit.
- Add Docker support.
- Add GitHub Actions for CI.

## License

MIT

# State RAG Starter for .NET

An open-source .NET starter API for experimenting with state-aware retrieval augmented generation.

The first version is intentionally simple: it stores documents in memory, filters by U.S. state, and returns matching sources. That keeps the project easy to run before you connect an LLM, embeddings, or a vector database.

## Is .NET possible on Mac?

Yes. .NET is fully supported on macOS, and you can build/run .NET apps from both VS Code and the terminal.

As of April 28, 2026, Microsoft lists .NET 10 as the latest .NET version. This starter targets `net10.0`.

Official docs:

- [Install .NET on macOS](https://learn.microsoft.com/en-us/dotnet/core/install/macos)
- [Check installed .NET versions](https://learn.microsoft.com/en-us/dotnet/core/install/how-to-detect-installed-versions)

## Install .NET on macOS

### Option A: Microsoft installer

1. Go to [dotnet.microsoft.com/download/dotnet](https://dotnet.microsoft.com/download/dotnet).
2. Download the latest .NET SDK for macOS, not just the runtime.
3. Open the `.pkg` installer and finish installation.
4. Open a new terminal window.
5. Verify:

```bash
dotnet --info
dotnet --list-sdks
```

### Option B: Homebrew

If you use Homebrew:

```bash
brew install dotnet-sdk
dotnet --info
```

If `dotnet` is still not found, restart the terminal or check that `/usr/local/share/dotnet` or `/opt/homebrew/bin` is on your `PATH`.

## Run from Terminal

From the project root:

```bash
dotnet restore
dotnet build
dotnet run --project src/StateRagStarter.Api
```

The API will print a local URL, usually something like:

```text
http://localhost:5000
```

Try the health endpoint:

```bash
curl http://localhost:5000/health
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
3. Open this folder in VS Code.
4. Open the integrated terminal with `Control` + `` ` ``.
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

## API endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/health` | Service health check |
| `GET` | `/documents?state=CA` | List stored documents, optionally filtered by state |
| `POST` | `/documents` | Add or update state-specific source text |
| `POST` | `/query` | Retrieve relevant state-specific sources |

## Next open-source milestones

- Add persistent storage with PostgreSQL or SQLite.
- Add embeddings and vector search.
- Add source citations to generated answers.
- Add tests with xUnit.
- Add Docker support.
- Add GitHub Actions for CI.

## License

MIT

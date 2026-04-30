using System.Collections.Concurrent;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<StateDocumentStore>();
builder.Services.AddEndpointsApiExplorer();

var app = builder.Build();

app.MapGet("/", () => Results.Ok(new
{
    name = "State RAG Starter for .NET",
    version = "0.1.0",
    runtime = $".NET {Environment.Version}",
    framework = "ASP.NET Core Minimal API",
    storage = "In-memory",
    llm = "Not configured",
    model = "Not configured",
    aiApi = "Not configured",
    endpoints = new[]
    {
        "GET /",
        "GET /health",
        "GET /documents",
        "GET /documents?state=CA",
        "POST /documents",
        "POST /query"
    }
}));

app.MapGet("/health", () => Results.Ok(new
{
    status = "ok",
    service = "state-rag-starter",
    utc = DateTimeOffset.UtcNow
}));

app.MapPost("/documents", (UpsertDocumentRequest request, StateDocumentStore store) =>
{
    if (string.IsNullOrWhiteSpace(request.State) || string.IsNullOrWhiteSpace(request.Content))
    {
        return Results.BadRequest(new { error = "State and content are required." });
    }

    var document = store.Upsert(request);
    return Results.Created($"/documents/{document.Id}", document);
});

app.MapGet("/documents", (string? state, StateDocumentStore store) =>
{
    return Results.Ok(store.List(state));
});

app.MapPost("/query", (QueryRequest request, StateDocumentStore store) =>
{
    if (string.IsNullOrWhiteSpace(request.Question))
    {
        return Results.BadRequest(new { error = "Question is required." });
    }

    var answer = store.Query(request);
    return Results.Ok(answer);
});

app.Run();

public sealed record UpsertDocumentRequest(
    string? Id,
    string State,
    string? Title,
    string Content,
    string[]? Tags);

public sealed record QueryRequest(
    string Question,
    string? State,
    int? TopK);

public sealed record StateDocument(
    string Id,
    string State,
    string Title,
    string Content,
    string[] Tags,
    DateTimeOffset UpdatedAt);

public sealed record QueryResponse(
    string Question,
    string? State,
    string Answer,
    IReadOnlyCollection<StateDocument> Sources);

public sealed class StateDocumentStore
{
    private readonly ConcurrentDictionary<string, StateDocument> documents = new();

    public StateDocumentStore()
    {
        Upsert(new UpsertDocumentRequest(
            "ca-leave-basics",
            "CA",
            "California Leave Basics",
            "California has state-specific leave rules. Always verify current law and cite official sources before advising users.",
            ["california", "leave", "employment"]));

        Upsert(new UpsertDocumentRequest(
            "ny-privacy-basics",
            "NY",
            "New York Privacy Basics",
            "New York privacy and data rules may differ from federal rules. A state-aware RAG system should filter context by jurisdiction.",
            ["new-york", "privacy", "data"]));
    }

    public StateDocument Upsert(UpsertDocumentRequest request)
    {
        var id = string.IsNullOrWhiteSpace(request.Id)
            ? Guid.NewGuid().ToString("n")
            : request.Id.Trim();

        var document = new StateDocument(
            id,
            request.State.Trim().ToUpperInvariant(),
            string.IsNullOrWhiteSpace(request.Title) ? "Untitled document" : request.Title.Trim(),
            request.Content.Trim(),
            request.Tags?.Where(tag => !string.IsNullOrWhiteSpace(tag)).Select(tag => tag.Trim()).ToArray() ?? [],
            DateTimeOffset.UtcNow);

        documents[id] = document;
        return document;
    }

    public IReadOnlyCollection<StateDocument> List(string? state)
    {
        var query = documents.Values.AsEnumerable();

        if (!string.IsNullOrWhiteSpace(state))
        {
            query = query.Where(document => document.State.Equals(state.Trim(), StringComparison.OrdinalIgnoreCase));
        }

        return query.OrderBy(document => document.State).ThenBy(document => document.Title).ToArray();
    }

    public QueryResponse Query(QueryRequest request)
    {
        var topK = Math.Clamp(request.TopK ?? 3, 1, 10);
        var terms = request.Question
            .Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(term => term.Trim('.', ',', '?', '!', ';', ':').ToLowerInvariant())
            .Where(term => term.Length > 2)
            .Distinct()
            .ToArray();

        var candidates = List(request.State)
            .Select(document => new
            {
                Document = document,
                Score = Score(document, terms)
            })
            .Where(result => result.Score > 0)
            .OrderByDescending(result => result.Score)
            .Take(topK)
            .Select(result => result.Document)
            .ToArray();

        var answer = candidates.Length == 0
            ? "I do not have enough state-specific context to answer yet. Add relevant documents, then ask again."
            : "I found state-specific context that may answer this question. Review the sources and replace this placeholder with your LLM answer generation step.";

        return new QueryResponse(request.Question, request.State?.Trim().ToUpperInvariant(), answer, candidates);
    }

    private static int Score(StateDocument document, IReadOnlyCollection<string> terms)
    {
        var searchableText = $"{document.State} {document.Title} {document.Content} {string.Join(' ', document.Tags)}".ToLowerInvariant();
        return terms.Count(searchableText.Contains);
    }
}

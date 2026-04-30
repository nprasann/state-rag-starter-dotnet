---
name: dotnet-aspnetcore-notes
description: Repo-specific implementation guidance for the .NET ASP.NET Core RAG starter.
---

## When to Use
Use alongside a shared skill when working in the .NET RAG repo.

## Stack Assumptions
- C#
- ASP.NET Core Web API
- Dependency Injection
- Options/configuration pattern
- Service interfaces for RAG workflows
- Vector DB client such as Qdrant
- Unit/integration testing with standard .NET test tooling

## Implementation Rules
- Keep controllers thin.
- Put business logic in services.
- Use interfaces for embedding providers, vector stores, and document processing.
- Register dependencies in the composition root.
- Use strongly typed options for configuration.
- Do not hardcode provider names, endpoints, or secrets.
- Prefer async APIs for I/O-bound work.
- Keep DTOs separate from domain/service models where useful.

## Suggested Layering
- Controllers: HTTP contract
- Services: ingestion/retrieval orchestration
- Providers: embedding/model integrations
- Repositories/clients: vector DB access
- Options: configuration binding
- Tests: unit tests for services, integration tests for APIs

## Validation
Prefer:
- dotnet build
- dotnet test
- focused unit tests for services
- integration smoke tests for API endpoints
- mocked providers for deterministic tests

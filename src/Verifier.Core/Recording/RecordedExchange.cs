namespace Verifier.Core.Recording;

/// <summary>One request and its response: a single line of requests.jsonl.</summary>
public sealed record RecordedExchange(
    string SessionId,
    long Sequence,
    RecordedRequest Request,
    RecordedResponse Response,
    TimeSpan Duration);

public sealed record RecordedRequest(
    string Method,
    string Path,
    string? Query,
    IReadOnlyDictionary<string, string[]> Headers,
    string? Body);

public sealed record RecordedResponse(
    int StatusCode,
    IReadOnlyDictionary<string, string[]> Headers,
    string? Body);

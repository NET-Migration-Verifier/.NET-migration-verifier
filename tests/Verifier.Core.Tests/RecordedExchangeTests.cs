using System.Text.Json;
using Verifier.Core.Recording;

namespace Verifier.Core.Tests;

public class RecordedExchangeTests
{
    [Fact]
    public void RoundTripsThroughJson()
    {
        var exchange = new RecordedExchange(
            "session-1",
            1,
            new RecordedRequest("POST", "/api/orders", "page=2",
                new Dictionary<string, string[]> { ["Content-Type"] = ["application/json"] },
                """{"item":42}"""),
            new RecordedResponse(201,
                new Dictionary<string, string[]> { ["Location"] = ["/api/orders/7"] },
                """{"id":7}"""),
            TimeSpan.FromMilliseconds(35));

        var json = JsonSerializer.Serialize(exchange);
        var back = JsonSerializer.Deserialize<RecordedExchange>(json)!;

        Assert.Equal(exchange.SessionId, back.SessionId);
        Assert.Equal(exchange.Request.Path, back.Request.Path);
        Assert.Equal(exchange.Request.Headers["Content-Type"], back.Request.Headers["Content-Type"]);
        Assert.Equal(exchange.Response.StatusCode, back.Response.StatusCode);
        Assert.Equal(exchange.Response.Body, back.Response.Body);
        Assert.Equal(exchange.Duration, back.Duration);
        Assert.DoesNotContain('\n', json);
    }
}

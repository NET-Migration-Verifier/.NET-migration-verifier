var builder = WebApplication.CreateBuilder(args);

builder.Services.AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"));

var app = builder.Build();

// TODO(weeks 3-7): middleware that records each request/response pair, with redaction, to requests.jsonl.
app.MapReverseProxy();

app.Run();

# .NET-migration-verifier

Records how a legacy ASP.NET app responds to real requests, replays them against the migrated .NET 10 app, and reports every behavioral difference. See [the technical build plan](NET%20Migration%20Verification%20Technical%20Build%20Plan.md). Phases, dates and the requirements process are in [docs/roadmap.md](docs/roadmap.md), the week-by-week plan and working cadence in [docs/delivery-plan.md](docs/delivery-plan.md), and the external facts the requirements rest on in [docs/product-context.md](docs/product-context.md).

## Layout

| Project | Purpose |
| --- | --- |
| `src/Verifier.Cli` | Command-line entry point (System.CommandLine) |
| `src/Verifier.Core` | Recording format, replay, normalization, diff |
| `src/Verifier.Capture` | YARP reverse proxy that records traffic in front of the legacy app |
| `tests/Verifier.Core.Tests` | xUnit tests |

## Build

Requires the .NET 10 SDK (pinned in `global.json`).

```bash
dotnet build
dotnet test
dotnet run --project src/Verifier.Cli -- --help
dotnet run --project src/Verifier.Capture   # proxies to http://localhost:8080 (see appsettings.json)
```

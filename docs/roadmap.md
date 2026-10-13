# Roadmap

How the [technical build plan](../NET%20Migration%20Verification%20Technical%20Build%20Plan.md) turns into work: what a requirement is, how a decision gets made, and who owns which kind of issue.

The schedule lives in [delivery-plan.md](delivery-plan.md): four weeks, three phases, a daily standup that every decision flows through. Market and competitive context is in [product-context.md](product-context.md).

## How requirements work

- **One GitHub issue per requirement** (`R-xxx`, label `requirement`) with a statement, acceptance criteria, its source in the build plan, and open questions.
- **One GitHub issue per open decision** (`D-xx`, label `decision`) with options and a recommendation. A decision is closed with a comment stating what was chosen, and the affected requirements are then updated.
- **One GitHub issue per task** (`T<phase>.<n>`, label `task`) with the requirements it serves and an estimate.
- **One issue per day** for the standup (label `standup`): agenda, decided, dispatched, landed.
- **Status labels:** every requirement starts as `status: draft` and becomes `status: locked` (in this cycle) or `status: deferred` (next cycle) during the requirements week. After lock, changing a requirement means opening a new issue that references the old one, so the history stays visible.

Numbering: `R-0xx` applies everywhere, `R-1xx` to `R-6xx` group by the area they belong to - test bed, capture and replay, normalize and diff, database, evidence and CI, packaging. Those groups no longer map to calendar phases; the calendar is in the delivery plan. Cross-cutting requirements carry the `cross-cutting` label, and requirements about what the user sees and does also carry `ux`.

## Who owns what

| Role | Owns | Never does |
| --- | --- | --- |
| CEO / CTO | Every decision. Locking and deferring requirements. Closing `decision` issues | - |
| Product owner (`.claude/agents/product-owner.md`) | Writing and refining `R-xxx` and `D-xx`, checking them against the build plan and scope | Lock, defer, or close a decision |
| UX specialist (`.claude/agents/ux-specialist.md`) | The users' side of a requirement: CLI, config, errors, report, install | Same |
| Scrum master (`.claude/agents/scrum-master.md`) | `T-xxx` tasks, the standup record, the schedule, the exit gates | Write requirements or code |

## Phases

| Phase | Dates | Exit |
| --- | --- | --- |
| Requirements | Wed 14 - Tue 20 Oct 2026 | No decision open, every requirement locked or deferred, ten daily targets written, the Windows machine serving the legacy app |
| Development | Wed 21 Oct - Tue 3 Nov 2026 | The core loop finds at least 9 of the 10 planted bugs with fewer than 5 false-alarm groups |
| System testing | Wed 4 - Tue 10 Nov 2026 | A full run from install to report with no step that needs someone who built it |

Day-by-day detail, the shape of a standup, and what the CEO has to supply are in [delivery-plan.md](delivery-plan.md).

## Learning track

What each area teaches, for someone coming from Go and C++.

| Area | C# and .NET topics |
| --- | --- |
| Scaffold | C# syntax through the scaffold code: records, nullable reference types, `var`, lambdas, class vs struct. `dotnet build/test/run` |
| Test bed | Reading ASP.NET MVC on .NET Framework (controllers, Razor views, Web.config, Global.asax), EF6, Autofac. Then the port: EF6 to EF Core, Web.config to appsettings.json, Autofac to built-in DI, Newtonsoft to System.Text.Json, `Startup` to `Program.cs` |
| Capture and replay | ASP.NET Core middleware pipeline, `async`/`await` and `Task` (compared with goroutines), streams, `HttpClient`, System.Text.Json, YARP |
| Normalize and diff | Tree walking with `JsonNode`, AngleSharp DOM, LINQ, interfaces and generics, test-first development with xUnit |
| Report | Razor templates |

Deferred areas keep their learning value for the next cycle: SQL Server backup/restore and Change Data Capture, WireMock.Net, Playwright, Docker, Kerberos and Negotiate authentication, self-contained single-file publishing and Windows services.

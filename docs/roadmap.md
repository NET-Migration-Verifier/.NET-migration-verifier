# Roadmap

How the [technical build plan](../NET%20Migration%20Verification%20Technical%20Build%20Plan.md) turns into work: seven phases, each with requirements tracked on GitHub and an exit test that must pass before the next phase starts.

## How requirements work

- **One GitHub issue per requirement** (`R-xxx`, label `requirement`) with a statement, acceptance criteria, its source in the build plan, and open questions.
- **One GitHub issue per open decision** (`D-xx`, label `decision`) with options and a recommendation. A decision is closed with a comment stating what was chosen, and the affected requirements are then updated.
- **One milestone per phase.** A requirement's milestone is the phase that builds it.
- **Status labels:** every issue starts as `status: draft`. In Phase 0 each one becomes `status: locked` (agreed) or `status: deferred` (not in v1). After lock, changing a requirement means opening a new issue that references the old one, so the history stays visible.

Numbering: `R-0xx` applies to every phase, and `R-1xx` to `R-6xx` belong to Phases 1 to 6. Cross-cutting requirements carry the `cross-cutting` label; requirements about what the user sees and does also carry `ux`.

Market and competitive context for these requirements is in [product-context.md](product-context.md). The week-by-week plan, the standup and review cadence and the definition of done are in [delivery-plan.md](delivery-plan.md); the scrum master agent operates it.

## Phases

| Phase | Weeks | Dates | Milestone | Exit test |
| --- | --- | --- | --- | --- |
| 0. Requirements | 0 | 19–25 Oct 2026 | [Phase 0](https://github.com/Shridhar2104/.NET-migration-verifier/milestone/1) | Every requirement locked or deferred; no decision issue open; Windows environment ready |
| 1. Test bed | 1–3 | 26 Oct – 15 Nov 2026 | [Phase 1](https://github.com/Shridhar2104/.NET-migration-verifier/milestone/2) | Both eShop versions run, and the planted-bug list is written |
| 2. Capture and replay | 4–7 | 16 Nov – 13 Dec 2026 | [Phase 2](https://github.com/Shridhar2104/.NET-migration-verifier/milestone/3) | A recorded 20-minute session replays against both versions with no crashes |
| 3. Normalize, diff, report | 8–12 | 14 Dec 2026 – 17 Jan 2027 | [Phase 3](https://github.com/Shridhar2104/.NET-migration-verifier/milestone/4) | Finds at least 9 of 10 planted bugs with fewer than 5 false alarms. **First paid assessment can start.** |
| 4. Database side effects | 13–18 | 18 Jan – 28 Feb 2027 | [Phase 4](https://github.com/Shridhar2104/.NET-migration-verifier/milestone/5) | Catches a planted bug that writes a wrong value while returning an identical page |
| 5. Evidence and CI | 19–22 | 1 – 28 Mar 2027 | [Phase 5](https://github.com/Shridhar2104/.NET-migration-verifier/milestone/6) | A design partner runs it in their own pipeline without help |
| 6. Ship v1 | 23–24 | 29 Mar – 11 Apr 2027 | [Phase 6](https://github.com/Shridhar2104/.NET-migration-verifier/milestone/7) | A second client installs and gets a first report in under 2 days |

The days before 19 Oct are free reading time (see "Before Phase 0" below).

## Phase 0: requirements week

Tracking issue: [#44](https://github.com/Shridhar2104/.NET-migration-verifier/issues/44).

Goal: by Friday 23 Oct every issue in the repo is `status: locked` or `status: deferred`, and every `decision` issue is closed.

| Day | Focus | Issues to review and lock |
| --- | --- | --- |
| Mon 19 Oct | The whole pipeline, and the rules that apply everywhere. Provision the Windows machine (D-01 is decided), and settle the schedule question before anything else is locked. | D-09 (#54), D-11 (#56), R-001–R-004 (#9–#12), R-005–R-007 (#58–#60) |
| Tue 20 Oct | The test bed. Read the legacy eShop source on GitHub: controllers, Web.config, EF6 models. List every route. | D-06 (#7), D-07 (#8), R-101–R-104 (#13–#16) |
| Wed 21 Oct | Capture and replay. Trace one request through the proxy on paper. | D-08 (#53), R-201–R-208 (#17–#24), R-210 (#47), R-211 (#61) |
| Thu 22 Oct | Normalize, diff, report: the core of the product. Diff two JSON responses by hand and write down which differences are noise. | R-301–R-306 (#25–#30), R-308 (#62) |
| Fri 23 Oct | Database, evidence, shipping. Final pass: lock or defer everything. | D-10 (#55), D-12 (#57), R-401–R-604 (#31–#43), R-506 (#63), R-507 (#64) |

For each issue, ask three things: is every acceptance criterion testable, is anything missing, and does it belong in v1?

## Learning track

What each phase teaches, for someone coming from Go and C++.

| Phase | C# and .NET topics |
| --- | --- |
| Before 0 | C# syntax through the scaffold code: records, nullable reference types, `var`, lambdas, class vs struct. `dotnet build/test/run`. |
| 0 | Reading code: ASP.NET MVC on .NET Framework (controllers, Razor views, Web.config, Global.asax), EF6, Autofac. |
| 1 | .NET Framework vs .NET 10: EF6 → EF Core, Web.config → appsettings.json, Autofac → built-in DI, Newtonsoft → System.Text.Json, `Startup` → `Program.cs`. |
| 2 | ASP.NET Core middleware pipeline, `async`/`await` and `Task` (compared with goroutines), streams, `HttpClient`, System.Text.Json, YARP, SQLite, AES-GCM Kerberos and Negotiate authentication, SPNs, Active Directory basics. |
| 3 | Tree walking with `JsonNode`, AngleSharp DOM, LINQ, interfaces and generics, test-first development with xUnit. |
| 4 | SQL Server backup/restore, Change Data Capture, `Microsoft.Data.SqlClient`, WireMock.Net. |
| 5 | Razor templates, Playwright, CI pipelines, Docker. |
| 6 | Self-contained single-file publishing, Windows services, signing. |

## Before Phase 0 (13–18 Oct)

- Read the build plan end to end.
- Read the scaffold in `src/` and `tests/`, and run `dotnet build` and `dotnet test`.
- Skim the open issues so Monday starts with questions, not first reads.

# Product context

Facts outside the codebase that the requirements depend on. Checked on 13 Oct 2026; each claim has a source, so it can be re-checked when it matters.

## Why now

**The port is being automated; the verification is not.** Microsoft's GitHub Copilot modernization for .NET is generally available and does Framework-to-.NET 10 upgrades agentically inside Visual Studio, across MVC, Razor Pages, Web API, Blazor, WPF, class libraries and console apps. The slow, expensive, risky half of a migration is moving from "write the new code" to "prove the new code behaves like the old code". That second half is this product.

It also changes what a realistic test bed looks like. An AI-driven port is what customers will actually have, so R-102 (#14) porting eShop with an agent is a faithful reproduction, and the mistakes the agent makes are the most realistic planted bugs available (D-06 #7, D-07 #8).

**Deadline pressure exists but is uneven.** .NET Framework 4.6.2 goes out of support on 12 January 2027, in the middle of Phase 4. That is a real forced-migration date for anyone still on 4.6.2. But 4.7 through 4.8.1 have no end date of their own: they follow the lifecycle of the Windows version they are installed on, so most Framework apps are not facing a hard cutoff. Sell on risk of behavioural regression, not on an end-of-life clock, except to the 4.6.2 holdouts where the clock is real and close.

For comparison, .NET 10 is the current LTS: supported from November 2025 to November 2028, which is where the tech stack's LTS claim comes from.

## Prior art

**Diffy (Twitter, 2015)** is where the core idea comes from, and its published lesson is the one this product is organised around: two services rarely return byte-identical responses, so a diffing pipeline that does not cancel noise produces a sea of false positives nobody triages. Diffy cancels noise by looking at the aggregate frequency of each error type across all requests seen; this product's R-302 (#26) does it by replaying the legacy app against itself, which is a stronger signal because it isolates volatility in the same code rather than inferring it from aggregates.

**The current traffic-replay tools do not reach this market.**

| Tool | Capture | Where it runs | Gap for a .NET Framework migration |
| --- | --- | --- | --- |
| Keploy | eBPF, open source | Linux | eBPF does not capture IIS on Windows Server; no SQL Server side effects |
| Speedscale | eBPF, commercial SaaS | Kubernetes | The legacy app is on IIS and is not going into Kubernetes before it is migrated |
| GoReplay | libpcap, OSS plus a Pro tier at $2,950/year | Linux-first | HTTP replay only: no mocking, no transforms, no evidence report |

None of them covers Windows and IIS capture, Kerberos replay, SQL Server row-level side effects, or an evidence report an auditor can tie to a hash of what was tested. That combination, not the differ, is the defensible part. The second defensible part is the rule library (R-304, #28), which only grows by doing assessments.

## Technical facts the requirements rest on

**YARP does not buffer bodies.** YARP provides no request or response body transforms, and Microsoft's guidance is that middleware should avoid touching the bodies because they are not buffered; enabling buffering costs memory and latency. Capture therefore has to tee the stream to disk while forwarding. This is why R-201 (#17) can promise under 20 ms median latency, and why R-211 (#61) exists to make everything that cannot be recorded visible instead of silently empty.

**Kerberos tickets are opaque to the proxy.** A ticket is encrypted for the app's service account, so the proxy cannot read the username. IIS 8.5 and later can log a request header as a custom field in the W3C log alongside the built-in `cs-username`, and `flushByEntrycountW3CLog` controls log buffering, which makes an exact proxy-to-user join possible with no change to the customer's app. See D-08 (#53).

**CDC and Change Tracking are not interchangeable.** Change Data Capture runs on Enterprise, Developer and Standard (Standard since SQL Server 2016 SP1) but not Express or Web, needs SQL Server Agent, and records column values before and after. Change Tracking runs on every edition including Express, needs no Agent, and records only that a row changed and which columns, not the values. R-403 (#33) needs values. See D-10 (#55).

**AltCover instruments by IL weaving, not by the profiling API,** which is why it works on .NET Framework. Two consequences under IIS: the worker process needs write access to the results file, and coverage is flushed on graceful shutdown unless the pause/resume feature is used. Strong-named assemblies need handling, because weaving invalidates the signature. See R-504 (#38).

**Playwright is heavy for an air-gapped product.** Chromium plus native dependencies adds roughly 300-550 MB to a package, and the browser is downloaded from the internet on first use. That collides with R-601 (#40) and R-603 (#42). See D-12 (#57).

**System.CommandLine 2.0 is stable** since November 2025, released alongside .NET 10, so the long beta-API churn is no longer a risk to the CLI choice in the tech stack.

**eShopModernizing, verified from the source:** the repository was archived by its owner on 7 May 2024, so it is read-only and we fork it. `eShopLegacyMVCSolution/src/eShopLegacyMVC` targets .NET Framework 4.7.2 with EntityFramework 6, Autofac, Newtonsoft.Json 12 and log4net. `eShopLegacyMVCSolution/eShopPorted` targets `net461` with ASP.NET Core 2.2 and EF Core 2.2, keeping Autofac and Newtonsoft: a halfway port that skips exactly the migration steps that produce behavioural differences.

## Sources

- [Modernize .NET Anywhere with GitHub Copilot (.NET Blog)](https://devblogs.microsoft.com/dotnet/modernize-dotnet-anywhere-with-ghcp/) and [Analyze applications and migrate by using GitHub Copilot modernization](https://learn.microsoft.com/en-us/azure/developer/github-copilot-app-modernization/overview)
- [.NET Framework official support policy](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-framework) and [Microsoft .NET Framework lifecycle](https://learn.microsoft.com/en-us/lifecycle/products/microsoft-net-framework)
- [Diffy: testing services without writing tests (Twitter Engineering)](https://blog.twitter.com/2015/diffy-testing-services-without-writing-tests)
- [Keploy vs Speedscale](https://keploy.io/compare/speedscale), [GoReplay](https://goreplay.org/)
- [YARP middleware](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/yarp/middleware?view=aspnetcore-10.0) and [YARP request and response transforms](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/yarp/transforms?view=aspnetcore-10.0)
- [Enhanced logging for IIS 8.5](https://learn.microsoft.com/en-us/iis/get-started/whats-new-in-iis-85/enhanced-logging-for-iis85) and [custom fields in log files](https://learn.microsoft.com/en-us/iis/configuration/system.applicationHost/sites/siteDefaults/logFile/customFields/)
- [Track data changes (SQL Server)](https://learn.microsoft.com/en-us/sql/relational-databases/track-changes/track-data-changes-sql-server?view=sql-server-ver17) and [comparing change data capture and change tracking](https://learn.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/cc280519(v=sql.105))
- [AltCover](https://github.com/SteveGilham/altcover) and its [use cases wiki](https://github.com/SteveGilham/altcover/wiki/Use-Cases)
- [System.CommandLine 2.0.0-beta5 and the path to a stable release](https://github.com/dotnet/command-line-api/issues/2576)
- [dotnet-architecture/eShopModernizing](https://github.com/dotnet-architecture/eShopModernizing)

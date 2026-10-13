# .NET Migration Verification: Technical Build Plan

Oct 13, 2026 · @logiance

## Summary

**Version 1 is a self-hosted command-line tool, written in C#, that records how a legacy ASP.NET app responds to real requests, replays the same requests against the migrated .NET 10 app, and produces an evidence report of every behavioral difference.** One founder can build it in about 24 weeks, with a usable internal version by week 12 to deliver the first paid assessments.

The core idea is borrowed from differential testing (the approach Twitter open-sourced as Diffy): run the same input through two versions and compare outputs. The key trick is replaying the legacy app against itself first. Anything that differs between two runs of the *same* code is noise (timestamps, IDs, ordering) and gets filtered out automatically, so only real behavior changes reach the report.

**What v1 verifies:** HTTP responses (status, headers, body) for ASP.NET MVC and Web API apps, and from week 13, the SQL Server rows each request writes.

**Design principles:**

1. **Runs entirely on the customer's infrastructure.** No traffic or data ever leaves their network, which is what gets you through enterprise security reviews.
2. **Non-invasive.** No changes to the legacy app's code; capture happens in a proxy in front of it.
3. **Built once, configured per client.** Everything client-specific lives in a config file, never in forked code.
4. **Evidence first.** Every output is reproducible and traceable to a recorded request, because the report is what customers pay for.

## Architecture

**Eight steps in one pipeline; the highlighted normalize step is what separates a usable product from a flood of false alarms.**

&#91;embedded content: Version 1 architecture · everything runs on the customer's infrastructure\]

## Component design

### 1. Capture

A reverse proxy sits in front of the legacy app (in staging by default) and records every request and response. Build it on YARP, Microsoft's open-source reverse proxy library for .NET, so it runs as a Windows service next to IIS or as a container.

- **Records:** method, path, query, headers, body, timing, and a sequence number per session, so stateful flows (log in, add to cart, check out) replay in order.
- **Redacts at source:** configurable rules mask passwords, tokens, card numbers and personal fields before anything is written to disk.
- **Optional in-process module (later):** an `IHttpModule` for .NET Framework apps that adds what a proxy cannot see, such as the authenticated user and which SQL statements each request ran.

Capture is only as good as the traffic it sees, so v1 also accepts existing test suites, Postman collections and HAR files as input.

### 2. Recording format

One recording is a folder: `requests.jsonl` (one request and response per line), large bodies as separate files, and a `manifest.json` (app version, capture window, redaction rules applied, file hashes). Index it with SQLite for fast lookup. Keep the format documented and stable: customers will store recordings as audit evidence.

### 3. Replay

The replayer sends recorded requests to three targets: the legacy app twice (to learn noise) and the migrated app once.

- **Starting state:** before each run, restore the same SQL Server database snapshot, so every target begins identical.
- **Session handling:** rewrite cookies, session IDs and anti-forgery tokens on the fly, because tokens issued by one run are invalid in another.
- **Downstream calls:** route the app's outbound HTTP calls to a mock server (WireMock.Net) that returns the responses recorded during capture.
- **Order:** replay each session sequentially; run independent sessions in parallel only when they do not touch the same data.

### 4. Normalization

The step that decides whether customers trust the tool. Two mechanisms:

1. **Learned noise:** compare legacy run A with legacy run B; any JSON path, header or HTML node that differs between them is marked volatile and ignored when comparing against the migrated app.
2. **Rules:** a config file of ignore paths (JSONPath, XPath, CSS selectors), regex masks, order-insensitive arrays, numeric tolerances and known-equivalent serialization differences, such as `/Date(...)/` versus ISO dates, which is the classic Newtonsoft-to-System.Text.Json change in Framework-to-Core migrations.

Ship a built-in rule library of known Framework-to-.NET 10 differences. That library grows with every customer and becomes the technical moat.

### 5. Diff and grouping

Compare normalized outputs structurally (JSON tree, XML tree, HTML DOM, then plain text as a fallback). Give each difference a signature: endpoint pattern, path in the response, and type of change. Group identical signatures, so 4,000 raw mismatches become 12 root causes such as "`/api/orders/*` returns dates in a different format." An optional summary step can run each group through an LLM using the customer's own API key or a local model, never yours (deferred to v1.1).

### 6. Database side effects (from week 13)

Enable SQL Server Change Data Capture or Change Tracking on the snapshot during replay, read the rows each request inserted, updated or deleted, and diff those changes between legacy and migrated runs. This catches the most dangerous bugs: a page that looks right but writes the wrong value.

### 7. Coverage

Instrument the legacy app with AltCover, which supports both .NET Framework and modern .NET, during the self-replay runs. The report then shows which code was exercised by recorded traffic and which was never tested, so gaps are explicit rather than silently assumed safe.

### 8. Outputs

- **Evidence report:** HTML plus PDF, with a summary verdict, root-cause groups, sample request and response pairs for each, coverage, and a hash of the recording, so the report can be tied to exactly what was tested.
- **CI gate:** exit codes and a JUnit-format results file for GitHub Actions and Azure DevOps; fails the build on any new unaccepted difference.
- **Accept list:** reviewers mark intended changes as accepted, with a reason; accepted differences stay in the report as an audit trail.
- **MCP server (later):** lets coding agents run verification and read results while they fix migration bugs.

## Tech stack and packaging

**Build everything in C# on .NET 10.** Your buyers are .NET teams; a tool in their own language is easier to trust, extend and approve, and it can load .NET Framework assemblies and run on Windows next to IIS.

| Layer | Choice | Why |
| --- | --- | --- |
| Language and runtime | C# on .NET 10 (LTS to Nov 2028) | Same ecosystem as buyers; cross-platform |
| Capture proxy | YARP | Production-grade reverse proxy maintained by Microsoft |
| CLI | System.CommandLine | Standard .NET command-line parsing |
| Recording index | SQLite (Microsoft.Data.Sqlite) | Zero-setup, single file, easy to archive |
| Downstream mocks | WireMock.Net | Mature HTTP mocking for .NET |
| JSON and XML diff | System.Text.Json tree walking plus custom differ | Full control over signatures and grouping |
| HTML diff | AngleSharp for DOM parsing | Compares structure, not raw text |
| Database restore and changes | SQL Server backup/restore plus Change Data Capture | Built into SQL Server |
| Coverage | AltCover | Supports .NET Framework and modern .NET |
| Report | Razor templates to HTML, Playwright to PDF | One template, two formats |
| Test bed | Microsoft's eShopModernizing sample (legacy MVC and WebForms on .NET Framework) | Realistic legacy app to port and verify |

**Packaging:**

- A single self-contained executable for Windows and Linux (no runtime install needed).
- A Docker image for running replays in CI.
- A Windows service installer for the capture proxy.
- An offline license key file checked locally, so the tool works in air-gapped networks.
- Versioned releases with a changelog; every client runs the same build.

## Build sequence for a solo founder

**Build in the order customers feel value: HTTP verification first, database side effects second, automation and polish last.** Each phase ends with a test you must pass before moving on. A one-week Phase 0 (week of 19 Oct 2026) locks the requirements first; week 1 starts 26 Oct 2026, the internal version is usable around mid-January 2027 and v1 ships around mid-April 2027. Requirements are tracked as GitHub issues, one milestone per phase; see `docs/roadmap.md`.

| Weeks | Phase | What you build | Exit test |
| --- | --- | --- | --- |
| 0 | Requirements | Write every requirement as a GitHub issue with acceptance criteria; resolve open decisions; set up the Windows environment | Every requirement is labelled `status: locked` or deferred, and no decision issue is open |
| 1–3 | Test bed | Run Microsoft's legacy eShop MVC sample on .NET Framework; port it to .NET 10 with an AI coding agent; plant 10 known behavior bugs in the port; add a Windows-authentication (Kerberos) variant in a test Active Directory domain | Both versions run locally (including the Kerberos variant), and you have a written list of the 10 planted bugs |
| 4–7 | Capture and replay | YARP capture proxy, recording format with redaction and encryption at rest, sequential replay with cookie and token rewriting, Kerberos replay as mapped test accounts | A recorded 20-minute session replays against both versions with no crashes |
| 8–12 | Normalize, diff, report | Self-replay noise learning, rule file, JSON/HTML differ, root-cause grouping, HTML report | Finds at least 9 of 10 planted bugs with fewer than 5 false alarms; **first paid assessment can start** |
| 13–18 | Database side effects | Snapshot restore per run, Change Data Capture reader, row-level diff, WireMock.Net downstream mocks | Catches a planted bug that writes a wrong value while returning an identical page |
| 19–22 | Evidence and CI | PDF report, accept list with reasons, coverage via AltCover, CI exit codes and JUnit output, Docker image | A design partner runs it in their own pipeline without your help |
| 23–24 | Ship v1 | Installers, offline licensing, docs, built-in rule library from partner findings | Second client installs and gets a first report in under 2 days |

Use an AI coding agent throughout for boilerplate, tests and the eShop port; keep the differ, normalization and grouping logic hand-reviewed, because false alarms are the product's main failure mode.

Run real assessments from week 12 using the internal version. Every false alarm a real app produces becomes a new normalization rule or a test case; that feedback is worth more than any feature you could build alone.

## Hard technical problems

**Most of the engineering risk sits in making replays faithful and keeping false alarms low; the diffing itself is the easy part.**

| Problem | Why it is hard | How to solve it |
| --- | --- | --- |
| Windows authentication | Kerberos and NTLM tickets cannot be replayed | Replay as dedicated test accounts; the replayer obtains fresh Kerberos tickets per session and maps recorded users to test users. In v1, Kerberos only (Phase 2); NTLM is not a goal |
| Session state and anti-forgery tokens | Values issued in one run are rejected in another | Track tokens per session: read each new value from the target's response and substitute it into later requests |
| Time-dependent logic | "Orders from the last 7 days" changes with the clock | Phase 3: self-replay and time-derived field rules catch time printed in responses; runs execute back to back. Phase 4: shift snapshot dates (and dates in recorded requests) to replay time. Date shifting protects coverage, not the false alarm rate, so it is the first item cut if Phase 4 slips |
| Non-deterministic ordering | Unordered queries return rows in any order | Learned automatically by self-replay; fall back to order-insensitive comparison rules |
| Concurrency | Parallel replay of sessions touching the same data gives inconsistent results | Default to sequential per session; parallelize only sessions with no shared tables |
| Writes to external systems | Replaying could send real emails or payments | Downstream calls always go to mocks during replay; block outbound network by default |
| Expected changes | Some differences are intended (new error format, faster response) | The accept list records them with a reason, so they stop failing the build but stay in the report |
| Rare code paths | Recorded traffic misses edge cases | Coverage report shows the gaps; later, generate requests for uncovered endpoints from routes and models |
| Huge legacy apps | Thousands of endpoints and gigabytes of traffic | Sample by endpoint pattern (e.g. first 200 unique shapes per endpoint) instead of replaying everything |

The metric to watch from day one is the **false alarm rate**: the share of reported root-cause groups a reviewer marks as not a real difference. Target under 10% before charging for the product, and track it per release.

## Security and privacy by design

Enterprise security reviews are the biggest blocker for a tool that records traffic, so these are product features, not afterthoughts.

- **No data leaves the customer.** The tool has no cloud backend; recordings, replays and reports stay on their machines.
- **Staging first.** The default setup records staging or test traffic; production capture is opt-in and documented separately.
- **Redaction before storage.** Sensitive fields are masked at capture time, and the manifest records which rules ran.
- **Encryption at rest.** Recordings are encrypted with a key the customer controls (built in weeks 4–7, before the first paid assessment).
- **No outbound calls during replay.** Network egress is blocked except to configured targets and mocks.
- **No telemetry by default.** Any usage reporting is opt-in and documented field by field.
- **Tamper-evident evidence.** Reports include hashes of the recording and configuration, so an auditor can confirm what was tested.
- **A short security pack.** A two-page architecture and data-flow description answers most vendor questionnaires before they are sent.

## Out of scope for version 1

Saying no to these keeps v1 shippable by one person in 24 weeks:

- WebForms UI and WCF services (no direct path to modern .NET, and very different capture needs)
- Message queues and background jobs
- Databases other than SQL Server
- Java, Node or Python apps
- A hosted cloud version or web dashboard
- Automatic fixing of the differences found
- Generating new test traffic for untested paths (coverage shows the gaps; generation comes later)

Each becomes a candidate for version 2 only when at least three paying customers ask for it.

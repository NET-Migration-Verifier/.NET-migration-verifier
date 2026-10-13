# Delivery plan

14 Oct to 24 Nov 2026. Three phases, a daily standup that every decision flows through, and no days off. [`roadmap.md`](roadmap.md) says how requirements and decisions work; this file says how a day runs and what each phase has to produce. The scrum master agent (`.claude/agents/scrum-master.md`) operates it.

This replaces the 24-week sequential plan. The architecture in the build plan does not change; what changes is how much of it this cycle contains and how fast decisions get made.

## The shape

42 days, 7 days a week.

| Phase | Dates | Days | Produces |
| --- | --- | --- | --- |
| **Requirements** | Wed 14 - Tue 20 Oct | 7 | Every requirement locked or out, every decision closed, twenty-four daily targets written, infrastructure running |
| **Development** | Wed 21 Oct - Fri 13 Nov | 24 | The product, built against the targets set in the requirements week |
| **System testing** | Sat 14 - Fri 20 Nov | 7 | The product used as a customer would use it, gaps found, gaps closed |
| **Margin** | Sat 21 - Tue 24 Nov | 4 | The only slack in the cycle |

**Full scope.** All 47 requirements are in this cycle. Nothing is deferred, including the two that earlier decisions had pushed out: R-209 (#46) Postman and test-suite import, and R-307 (#49) the LLM summary of difference groups.

**The rate this implies, stated plainly so it can be checked.** The original plan budgeted 24 weeks of solo work - about 120 working days - for this scope. It now has 24 development days. Every day has to produce what that plan budgeted five days for, and roughly two requirements have to land per day.

That is the target the plan is built on, and it is deliberately aggressive. What makes it conceivable is that agents work in parallel on separate requirements while the CEO decides; what caps it is that the differ, the noise learning and the grouping need hand review, and that review does not parallelise.

**The tripwire.** After day 3 (Fri 23 Oct), compare requirements actually closed against the nine the map below expects by then. That ratio is the real rate. If it is under half, the choice comes to the standup that morning: cut scope, extend the cycle, or accept a lower bar at the exit gate. Finding out on day 3 costs three days; finding out on day 20 costs the cycle.

The four margin days stay margin. If they start being spent in the first week, that is the same signal.

## How a day runs

The standup is not a status report. It is where the product gets decided. Everything flows through the CEO, and the agents work from the direction given in it.

```
  evening before     Scrum master posts tomorrow's agenda on the day's standup issue:
                     open decisions, yesterday's unresolved blockers, today's target,
                     anything the agents turned up
         |
  standup            CEO works through the agenda. Discussion, direction, viewpoints.
                     Every item ends in one of: decided / needs research / deferred to a named day.
                     Decisions are written into the issue as they are made, not afterwards.
         |
  dispatch           Agents are invoked with the CEO's direction attached, not just the task.
                     Each dispatch is recorded: which agent, what question, what direction.
         |
  work               Agents research and build. The CEO is available for the questions only
                     they can answer; everything else waits for tomorrow's standup.
         |
  end of day         Scrum master closes the day's issue: what landed, what did not, what
                     carries to tomorrow's agenda.
```

One issue per day, labelled `standup`, titled `Standup: <Day DD Mon YYYY>`, with four sections: **Agenda**, **Decided**, **Dispatched**, **Landed**. The issue is closed at the end of the day. It is the permanent record of what was decided and why, which matters more here than in a slow plan, because in six weeks there is no time to rediscover a decision.

**The rule that does not change: nothing is reported that cannot be pointed at.** A commit, a closed issue, a merged PR, or command output that was actually seen.

Every seventh day the standup also carries the week's review: what the week was supposed to produce against what it produced, and a call - on track, at risk, or slipped - with a reason and a proposal. "At risk" is said the day it becomes true.

## Phase 1 - Requirements - Wed 14 to Tue 20 Oct

Seven days. The output is not a document, it is a locked set of requirements and a day-by-day target list the build can execute without stopping to ask what was meant.

| Day | Topic | Has to end with |
| --- | --- | --- |
| Wed 14 Oct | **Scope.** D-13: decided - everything is in, all 47 requirements, nothing deferred | The rate that implies written down, and the day-3 tripwire agreed |
| Thu 15 Oct | **Test bed, Windows auth and the bug list.** D-06, D-07. Taken early because the test bed is the long pole: two versions of a real app, both behind Kerberos, have to exist before the product has anything to compare | R-101 to R-105 locked; the ten planted bugs defined, one of them identity-dependent; the eShop fork and the domain controller both started the same day |
| Fri 16 Oct | **Capture and replay.** D-08 (how capture learns which user made a request), D-09 (config format), the recording format, what a session is, how tokens get rewritten | R-201 to R-208 and R-210 locked or out |
| Sat 17 Oct | **The core: normalize, diff, group.** What counts as noise, what a signature is. This is where the product lives or dies, and where false alarms come from | R-301 to R-305 locked or out |
| Sun 18 Oct | **What the user touches.** The report, the CLI, the config, traceability, and how the false alarm rate gets measured | R-306, R-005, R-002, R-003, R-004 locked |
| Mon 19 Oct | **Loose ends.** Anything that came back as "needs research", and every requirement not yet locked or deferred | Zero `status: draft` issues left, zero `decision` issues open |
| Tue 20 Oct | **Daily targets.** Turn the locked set into twenty-four days of targets, one per development day, each with a check that says it is done | A target per day, agreed, on the board |

Running in parallel from day 1, not after: infrastructure. See the list below.

**Exit:** no `decision` issue open, every requirement `status: locked` or `status: deferred`, twenty-four daily targets written, and the Windows machine serving the legacy app.

## Phase 2 - Development - Wed 21 Oct to Fri 13 Nov

Twenty-four days, one target per day. The map below is the plan; the target issues get written on Tue 20 Oct once the requirements are locked, because writing them before that just means rewriting them.

Standups continue daily and keep the same shape: the agenda is yesterday's carry-over, today's target, and anything the build turned up that needs a decision.

| Day | Date | Target | Requirements |
| --- | --- | --- | --- |
| 1 | Wed 21 Oct | Legacy eShop MVC serving pages on full IIS against SQL Server with seeded data | R-101 (#13) |
| 2 | Thu 22 Oct | The .NET 10 port, agent-driven: EF6 to EF Core, Web.config to appsettings, Autofac to built-in DI, Newtonsoft to System.Text.Json | R-102 (#14) |
| 3 | Fri 23 Oct | Port finished and route-compared against the legacy list; setup and reset scripts | R-102 (#14), R-104 (#16) |
| 4 | Sat 24 Oct | Both apps behind Kerberos on real DNS names with SPNs; `klist` shows a ticket, not NTLM | R-105 (#48) |
| 5 | Sun 25 Oct | Ten planted bugs committed one per commit, plus the sealed set, plus the written bug list | R-103 (#15) |
| 6 | Mon 26 Oct | YARP capture proxy streaming bodies to disk; the recording folder and manifest | R-201 (#17), R-203 (#19) |
| 7 | Tue 27 Oct | Redaction at capture time; encryption at rest with a customer-held key | R-202 (#18), R-205 (#21) |
| 8 | Wed 28 Oct | SQLite index over a recording; unrecordable traffic detected and counted | R-204 (#20), R-211 (#61) |
| 9 | Thu 29 Oct | HAR import and Postman collection import, both redacted on the way in | R-207 (#23), R-209 (#46) |
| 10 | Fri 30 Oct | Session, cookie and anti-forgery token rewriting. The riskiest single day in the build | R-206 (#22) |
| 11 | Sat 31 Oct | Sequential replay against legacy A, legacy B and the migrated app | R-208 (#24) |
| 12 | Sun 1 Nov | Kerberos replay: recorded users mapped to test accounts, fresh tickets per account | R-210 (#47) |
| 13 | Mon 2 Nov | Structural differ: JSON, XML, HTML DOM, text fallback, status and headers | R-301 (#25) |
| 14 | Tue 3 Nov | Noise learned by replaying the legacy app against itself | R-302 (#26) |
| 15 | Wed 4 Nov | Normalization rules from config, and the built-in rule library seeded from the port's own differences | R-303 (#27), R-304 (#28) |
| 16 | Thu 5 Nov | Root-cause grouping and signatures; sampling for large recordings | R-305 (#29), R-308 (#62) |
| 17 | Fri 6 Nov | HTML evidence report, and the false alarm rate measured for the first time | R-306 (#30), R-004 (#12) |
| 18 | Sat 7 Nov | Database snapshot restore per run; change feed enabled and rows attributed per request | R-401 (#31), R-402 (#32) |
| 19 | Sun 8 Nov | Row-level diff between runs; outbound calls to WireMock.Net with egress blocked | R-403 (#33), R-404 (#34) |
| 20 | Mon 9 Nov | Date shifting from capture time to replay time; optional LLM summary of groups | R-405 (#50), R-307 (#49) |
| 21 | Tue 10 Nov | PDF report; accept list with reasons and reviewer verdicts | R-501 (#35), R-503 (#37) |
| 22 | Wed 11 Nov | CI gate with exit codes and JUnit; Docker image; AltCover coverage under IIS | R-502 (#36), R-505 (#39), R-504 (#38) |
| 23 | Thu 12 Nov | Preflight `doctor` and support bundle; MCP server; self-contained executables | R-506 (#63), R-507 (#64), R-601 (#40) |
| 24 | Fri 13 Nov | Windows service installer; offline licence; docs, security pack, versioned release | R-602 (#41), R-603 (#42), R-604 (#43) |

Running across every day, not scheduled on one: R-001 (#9) no egress, R-002 (#10) the config file, R-003 (#11) traceability, R-005 (#58) the CLI surface, R-006 (#59) recording retention and deletion, R-007 (#60) the production opt-in.

**Where this map is thinnest:** days 22 to 24. AltCover under IIS is the one item the build plan itself calls a spike, and it sits on the same day as Docker and the CI gate; installers, licensing and signing sit on the last day with nothing behind them. If anything slips, it lands here, and this is the first place the margin gets spent.

Unit tests are written as part of the work, not after it. Definition of done for a day's target: merged through a PR, `dotnet build` and `dotnet test` green with the output seen, and the acceptance criteria it serves ticked in the requirement issue or the gap named.

**Exit:** the core loop runs end to end on the test bed, including a Kerberos session replayed as mapped test accounts and a database side-effect check, and finds at least 9 of the 10 planted bugs with fewer than 5 false-alarm groups.

## Phase 3 - System testing - Sat 14 to Fri 20 Nov

Not unit testing, which already happened. This week the product is used the way a customer would use it, by us, as the customer: install it, point it at an app, capture, replay, read the report, decide whether the differences are real.

What gets judged: whether a person who did not build it can get from install to first report, whether the report answers the question it exists to answer, where the CLI and the config fight back, and what the false alarm rate is on traffic nobody tuned for.

What comes out: a ranked gap list, and as many of those gaps closed as the week allows. Gaps left open are written down as known limitations rather than left to be rediscovered.

**Exit:** a full run from install to report with no step that needs someone who built it, and the gap list triaged into closed or recorded.

## What the CEO has to supply

The build is blocked on infrastructure that has lead time and that no agent can provision. In a 24-week plan a week's slip here was an annoyance; here it comes straight out of the build.

| What | Why it blocks | When |
| --- | --- | --- |
| Windows machine with Visual Studio 2022 and full IIS | The legacy app is .NET Framework and runs nowhere else. Every phase after requirements depends on it. IIS Express is not enough: it falls back to NTLM on localhost, so Kerberos needs full IIS | **Day 1.** The single point of failure in this plan |
| Windows edition and Hyper-V confirmed on that machine | **Critical path now that Kerberos is in scope.** No Hyper-V means no domain controller VM, which means no Kerberos at all. A Home edition cannot run it and the upgrade has its own lead time | **Day 1, before anything else.** Run `Get-ComputerInfo \| select WindowsProductName, CsTotalPhysicalMemory` and `Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V` |
| SQL Server Developer edition, SQL Server Agent enabled | The legacy app needs a real database. Developer covers both options in D-10, so it is not blocked on any decision | Day 1 |
| Active Directory domain controller VM, Windows Server evaluation ISO, two test accounts in different roles | Required, not optional: R-105 and R-210 are in scope. DNS names and SPNs are needed too, because Kerberos does not work against `localhost` or an IP | Started Thu 15 Oct, working before the build reaches Kerberos |
| A decision on RAM | SQL Server, the legacy app, the port and a 2-4 GB domain controller VM on one 16 GB box. This was tight before Kerberos; it is tighter now, and ordering RAM has shipping lead time | **Day 1.** The DC VM is what pushes it over |

Everything else the CEO supplies is direction, in the standup, daily.

## Known risks

1. **Twenty-four build days against a scope estimated at a hundred and twenty.** Scope was not cut, so the whole plan rests on sustaining roughly five times a traditional day's output. The day-3 tripwire exists to find out whether that is real while there is still time to act on the answer.
2. **Kerberos is the largest single thing in scope and it is mostly infrastructure.** It cannot be built by an agent working alone, it cannot be tested without a domain, and its hardest part - learning which user made a recorded request, because the ticket is encrypted for the app's service account - is still an open decision (D-08, #53). If Hyper-V turns out to be unavailable, Kerberos is gone and the ten added days should go back.
3. **The CEO is the bottleneck by design.** Everything flows through one person, which is what keeps the product coherent and also what caps throughput. The agenda has to be ready before the standup, or the standup becomes the research.
4. **Forty-two days with no day off, and the quality bottleneck is judgement.** The differ, the noise learning and the grouping are the parts the build plan says to keep hand-reviewed, and review is the first thing fatigue degrades. The four margin days exist partly for this.
5. **Infrastructure is unstarted.** As of 14 Oct none of the environment items are done and the legacy app has never run. Every day it stays unstarted comes out of the build days, not out of the requirements week.
6. **The test bed is itself a build**, and now a bigger one: two versions of a real app, both behind Windows authentication in a test domain. Without it there is nothing to compare, which is why it is day 2 of the requirements week.

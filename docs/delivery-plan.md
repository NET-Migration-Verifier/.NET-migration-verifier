# Delivery plan

The 24-week plan week by week, and the cadence that keeps it honest. [`roadmap.md`](roadmap.md) says what each phase is and how requirements work; this file says what happens in each week and how progress is recorded. The scrum master agent (`.claude/agents/scrum-master.md`) operates it.

One founder, 24 weeks, no slack. Every week below is a full week of work, so anything added has to be paid for by something removed.

## Cadence

| When | What | Where |
| --- | --- | --- |
| Every weekday | Standup: since yesterday, today, blocked, phase burn | A comment on the week's `standup` issue |
| Friday | Weekly review: planned vs done, phase burn, on track / at risk / slipped | Closes the week's standup issue, opens next week's |
| End of a phase | Exit gate: the exit test, the evidence, pass or fail | A comment on the phase's tracking issue |

**The rule for all three: nothing is reported that cannot be pointed at.** A commit, a closed issue, a merged PR, or command output that was actually seen. "Unknown" is an acceptable status; an invented one is not.

## Work items

| Kind | Label | Who owns it | Numbering |
| --- | --- | --- | --- |
| Requirement | `requirement` | Product owner | `R-0xx` cross-cutting, `R-1xx`-`R-6xx` by phase |
| Open decision | `decision` | Product owner writes, CEO decides | `D-xx` |
| Task | `task` | Scrum master | `T<phase>.<n>` |
| Standup week | `standup` | Scrum master | by date |
| Blocker | `blocker` | Scrum master | on the issue it blocks |

A task serves at least one requirement; a task with no requirement behind it is scope creep. Tasks are created one phase ahead, not for all 24 weeks, because work six months out gets rewritten before it gets done.

**Definition of done** for a task: merged through a PR (never straight to `main`), `dotnet build` and `dotnet test` pass with the output seen, the acceptance criteria it serves are ticked in the requirement issue or explicitly listed as not reached, and the task is closed with a comment naming the PR.

## Week by week

Dates are Monday to Sunday. "Exit" rows are gates: the phase does not end until the test passes.

### Phase 0 · Requirements · week of 19 Oct 2026

| Week | Dates | Goal | Issues |
| --- | --- | --- | --- |
| 0 | 19-25 Oct | Lock or defer every requirement, close every decision, provision the Windows machine and the AD test domain | #44, D-06 to D-12 (#7, #8, #53-#57) |

**Exit:** every issue is `status: locked` or `status: deferred`, no `decision` issue is open, the Windows environment is ready.

### Phase 1 · Test bed · weeks 1-3

| Week | Dates | Goal | Requirements |
| --- | --- | --- | --- |
| 1 | 26 Oct - 1 Nov | Legacy eShop MVC running on full IIS with SQL Server and seeded data; every route written down; the AD domain controller built | R-101 (#13), R-105 (#48) |
| 2 | 2-8 Nov | The .NET 10 port, built with an AI coding agent, serving the same routes against the same schema | R-102 (#14) |
| 3 | 9-15 Nov | Kerberos on both apps; 10 planted bugs plus the sealed set; one-command setup and reset scripts | R-103 (#15), R-104 (#16), R-105 (#48) |

**Exit:** both versions run locally including the Kerberos variant, and the planted-bug list is written.

The estimates on the board add up to 15.5 days against the 15 working days in this phase, and the load is uneven: week 1 is exactly full, week 2 has half a day spare, **week 3 is a day over**. The domain controller (T1.8, #72) is already pulled into week 1 because it has lead time and depends on nothing. The day that is still over has to come from somewhere: the candidate is T1.11 (#75), the sealed bug set, which is blocked on D-06 (#7), is mostly agent work, and can slip into the first days of Phase 2 without touching the Phase 1 exit test.

### Phase 2 · Capture and replay · weeks 4-7

| Week | Dates | Goal | Requirements |
| --- | --- | --- | --- |
| 4 | 16-22 Nov | YARP proxy records every exchange by streaming bodies to disk; the recording folder format and manifest | R-201 (#17), R-203 (#19), R-211 (#61) |
| 5 | 23-29 Nov | Redaction at capture time, SQLite index, encryption at rest | R-202 (#18), R-204 (#20), R-205 (#21) |
| 6 | 30 Nov - 6 Dec | Sequential replay against three targets; cookie, session and anti-forgery token rewriting | R-206 (#22), R-208 (#24) |
| 7 | 7-13 Dec | Kerberos replay as mapped test accounts; buffer for the week this costs | R-210 (#47) |

**Exit:** a recorded 20-minute session replays against both versions with no crashes.

Carries the Kerberos week that D-03 added. Per D-11 (#56), HAR import moves to week 12 and parallel replay leaves the v1 scope to pay for it.

### Phase 3 · Normalize, diff, report · weeks 8-12

| Week | Dates | Goal | Requirements |
| --- | --- | --- | --- |
| 8 | 14-20 Dec | Structural differ: JSON, XML, HTML DOM, text fallback, status and headers | R-301 (#25) |
| 9 | 21-27 Dec | Noise learned by replaying legacy against itself | R-302 (#26) |
| 10 | 28 Dec - 3 Jan | Normalization rules from config; the first built-in rules | R-303 (#27), R-304 (#28) |
| 11 | 4-10 Jan | Root-cause grouping and signatures; sampling for large recordings | R-305 (#29), R-308 (#62) |
| 12 | 11-17 Jan | HTML evidence report; HAR import; the false alarm rate measured for the first time | R-306 (#30), R-207 (#23), R-004 (#12) |

**Exit:** finds at least 9 of the 10 planted bugs with fewer than 5 false-alarm groups. **The first paid assessment can start.**

Weeks 9 and 10 are Christmas and New Year. This is the phase with the revenue date at the end and it is the phase most likely to lose capacity to the calendar. Decide the realistic capacity for those two weeks in week 8, not in January.

### Phase 4 · Database side effects · weeks 13-18

| Week | Dates | Goal | Requirements |
| --- | --- | --- | --- |
| 13 | 18-24 Jan | Snapshot restore before every run, automated and logged | R-401 (#31) |
| 14 | 25-31 Jan | Change feed enabled and row changes attributed per request | R-402 (#32) |
| 15 | 1-7 Feb | Row-level diff reusing the noise learner and the rule engine | R-403 (#33) |
| 16 | 8-14 Feb | WireMock.Net downstream mocks; outbound egress blocked and reported | R-404 (#34) |
| 17 | 15-21 Feb | Date shifting from capture time to replay time | R-405 (#50) |
| 18 | 22-28 Feb | Feed the first paid assessment's false alarms back into rules and tests | R-004 (#12), R-304 (#28) |

**Exit:** catches a planted bug that writes a wrong value while returning an identical page.

R-405 is the first thing to cut if this phase runs late: it protects coverage, not the false alarm rate.

### Phase 5 · Evidence and CI · weeks 19-22

| Week | Dates | Goal | Requirements |
| --- | --- | --- | --- |
| 19 | 1-7 Mar | PDF report; accept list with reasons and reviewer verdicts | R-501 (#35), R-503 (#37) |
| 20 | 8-14 Mar | CI gate: exit codes, JUnit output, example pipelines, Docker image | R-502 (#36), R-505 (#39) |
| 21 | 15-21 Mar | Coverage of the legacy app via AltCover under IIS | R-504 (#38) |
| 22 | 22-28 Mar | Preflight `doctor` and support bundle; a design partner runs it unaided | R-506 (#63) |

**Exit:** a design partner runs it in their own pipeline without help.

### Phase 6 · Ship v1 · weeks 23-24

| Week | Dates | Goal | Requirements |
| --- | --- | --- | --- |
| 23 | 29 Mar - 4 Apr | Self-contained executables, Windows service installer, offline licence | R-601 (#40), R-602 (#41), R-603 (#42) |
| 24 | 5-11 Apr | Docs, security pack, built-in rule library from partner findings, versioned release | R-604 (#43) |

**Exit:** a second client installs and gets a first report in under 2 days.

## Known schedule risks

Carried here so they are visible every week, not rediscovered.

1. **No slack anywhere.** 24 weeks, 24 weeks of work. The first unplanned week comes out of Phase 6 or out of the ship date.
2. **Phase 2 carries Kerberos** (D-03) and is still four weeks. D-11 (#56) proposes what pays for it and is unanswered.
3. **Phase 3 spans Christmas and New Year** and ends on the only date with revenue attached (17 Jan 2027).
4. **Phase 1 depends on infrastructure with lead time**: the Windows machine and the Active Directory test domain. Both are needed before 26 Oct.
5. **Three spikes are scheduled as if they are known work**: AltCover under IIS (week 21), CDC latency per request (week 14), and reading the authenticated user from IIS logs (week 4, D-08 #53). Each could be a day or could be a week.

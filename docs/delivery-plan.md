# Delivery plan

Four weeks, three phases, one daily standup that everything flows through. [`roadmap.md`](roadmap.md) says how requirements and decisions work; this file says how a day runs, how a week runs, and what each phase has to produce. The scrum master agent (`.claude/agents/scrum-master.md`) operates it.

This replaces the 24-week sequential plan. The architecture in the build plan does not change; what changes is how much of it v1 contains and how fast decisions get made.

## The shape

| Phase | Dates | Working days | Produces |
| --- | --- | --- | --- |
| **Requirements** | Wed 14 - Tue 20 Oct 2026 | 5 | Every requirement locked or out, every decision closed, daily targets for the build written, infrastructure running |
| **Development** | Wed 21 Oct - Fri 6 Nov 2026 | 13 | The product, built against the targets set in the requirements phase |
| **System testing** | Mon 9 - Fri 13 Nov 2026 | 5 | The product used as a customer would use it, gaps found, gaps closed |

The month runs from today to **Sat 14 Nov 2026**, which is 23 working days. All 23 are allocated above and the last working day is Fri 13 Nov, so the deadline itself is the only margin. There is no spare week anywhere: a day lost is a day taken from the build.

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

One issue per day, labelled `standup`, titled `Standup: <Day DD Mon YYYY>`, with four sections: **Agenda**, **Decided**, **Dispatched**, **Landed**. The issue is closed at the end of the day. It is the permanent record of what was decided and why, which matters more here than in a slow plan, because in four weeks there is no time to rediscover a decision.

**The rule that does not change: nothing is reported that cannot be pointed at.** A commit, a closed issue, a merged PR, or command output that was actually seen.

## How a week runs

Friday: what the week was supposed to produce against what it produced, and a call - on track, at risk, or slipped - with a reason and a proposal, not a colour. In a four-week plan a lost week is a quarter of the project, so "at risk" has to be said the day it becomes true.

## Phase 1 - Requirements - Wed 14 to Tue 20 Oct

Five days. The output is not a document, it is a locked set of requirements and a day-by-day target list that the development phase can execute without stopping to ask what was meant.

| Day | Topic | Has to end with |
| --- | --- | --- |
| Wed 14 Oct | **Scope.** D-13: what this month's product contains and what it does not. Nothing else can be decided until this is | The in/out list locked; everything out labelled `status: deferred` |
| Thu 15 Oct | **Capture and replay.** D-08 (who the user is), D-09 (config format), the recording format, what a session is | R-201 to R-208 locked or out |
| Fri 16 Oct | **The core: normalize, diff, group.** What counts as noise, what a signature is, what the report has to show. This is where the product lives or dies | R-301 to R-306, R-308 locked or out |
| Mon 19 Oct | **Test bed and the bug list.** D-06, D-07. What the ten planted bugs are, because they define what "working" means | R-101 to R-105 locked; the bug list written |
| Tue 20 Oct | **Daily targets.** Turn the locked set into thirteen days of targets, one per development day, each with a check that says it is done | A target per day, agreed, on the board |

Running in parallel from day 1, not after: infrastructure. See the list below.

**Exit:** no `decision` issue open, every requirement `status: locked` or `status: deferred`, thirteen daily targets written, and the Windows machine serving the legacy app.

## Phase 2 - Development - Wed 21 Oct to Fri 6 Nov

Thirteen working days, one target per day, set on 20 Oct. Standups continue daily and keep the same shape: the agenda is yesterday's carry-over, today's target, and anything the build turned up that needs a decision.

Unit tests are written as part of the work, not after it. Definition of done for a day's target: merged through a PR, `dotnet build` and `dotnet test` green with the output seen, and the acceptance criteria it serves ticked in the requirement issue or the gap named.

**Exit:** the core loop runs end to end on the test bed and finds at least 9 of the 10 planted bugs with fewer than 5 false-alarm groups. That gate is unchanged from the original plan, because it is the only measure that says the product works rather than merely runs.

## Phase 3 - System testing - Mon 9 to Fri 13 Nov

Not unit testing, which already happened. This week the product is used the way a customer would use it, by us, as the customer: install it, point it at an app, capture, replay, read the report, decide whether the differences are real.

What gets judged: whether a person who did not build it can get from install to first report, whether the report answers the question it exists to answer, where the CLI and the config fight back, and what the false alarm rate is on traffic nobody tuned for.

What comes out: a ranked gap list, and as many of those gaps closed as the week allows. Gaps left open are written down as known limitations rather than left to be rediscovered.

**Exit:** a full run from install to report with no step that needs someone who built it, and the gap list triaged into closed or recorded.

## What the CEO has to supply

The build is blocked on infrastructure that has lead time and that no agent can provision. In a 24-week plan a week's slip here was an annoyance; in a thirteen-day build it is the project.

| What | Why it blocks | When |
| --- | --- | --- |
| Windows machine with Visual Studio 2022 and full IIS | The legacy app is .NET Framework and runs nowhere else. Every phase after requirements depends on it | **Day 1.** The single point of failure in this plan |
| SQL Server Developer edition, SQL Server Agent enabled | The legacy app needs a real database. Developer covers both options in D-10, so it is not blocked on that decision | Day 1 |
| Windows edition and Hyper-V confirmed on that machine | A Home edition has no Hyper-V, and the upgrade has its own lead time | Day 1, so a surprise surfaces now and not in week 2 |
| A decision on RAM | SQL Server plus the legacy app plus the port on one 16 GB box is tight, and ordering RAM has shipping lead time | Day 1, if it is needed at all |
| Active Directory test domain | Only if Kerberos survives D-13. It is several days of work on its own | Decided day 1, built only if in scope |

Everything else the CEO supplies is direction, in the standup, daily.

## Known risks

1. **Thirteen development days against a scope estimated at twenty-four weeks.** D-13 is the mechanism for dealing with that. If the in/out list is not cut hard on day 1, the plan fails in the last week instead of on day 1, which is the expensive way to find out.
2. **The CEO is the bottleneck by design.** Everything flows through one person, which is what keeps the product coherent and also what caps throughput. The agenda has to be ready before the standup, or the standup becomes the research.
3. **Infrastructure is unstarted.** As of 14 Oct none of the environment items are done and the legacy app has never run. Every day it stays unstarted comes out of the thirteen build days, not out of the requirements week.
4. **The test bed is itself a build.** Getting Microsoft's eShop running on .NET Framework and porting it to .NET 10 is real work, and it is a prerequisite for everything else, because without two versions of an app there is nothing to compare.
5. **Agents produce volume, not judgement.** The differ, the noise learning and the grouping are where false alarms come from, and the build plan's own advice is to keep them hand-reviewed. That review is CEO time, inside the same thirteen days.

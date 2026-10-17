# Product flow

How a verification run actually moves, from the legacy app's live traffic to a report an auditor can tie to a hash. The step numbers match the component design in [the technical build plan](../NET%20Migration%20Verification%20Technical%20Build%20Plan.md).

Everything below runs on the customer's own infrastructure. There is no cloud backend and no outbound call during replay except to configured targets and mocks.

## The verification pipeline

```mermaid
graph TD
    SRC["Real traffic, test suites,<br/>Postman collections, HAR files"]
    SRC --> CAP["1. Capture<br/>YARP reverse proxy<br/>redacts before anything is written"]
    CAP -->|"forwards"| LEGACY["Legacy ASP.NET app on IIS<br/>no code changes"]
    CAP -->|"tees to disk"| REC["2. Recording<br/>requests.jsonl, large bodies,<br/>manifest.json, SQLite index"]
    REC --> REPLAY["3. Replay<br/>same SQL Server snapshot per run<br/>cookies and anti-forgery tokens rewritten"]
    REPLAY -.->|"outbound calls mocked"| MOCK["WireMock.Net"]
    REPLAY --> A["Legacy app, run A"]
    REPLAY --> B["Legacy app, run B"]
    REPLAY --> MIG["Migrated .NET 10 app"]
    A --> NOISE["A vs B: every path that differs<br/>is volatile, so it is ignored"]
    B --> NOISE
    NOISE --> NORM["4. Normalize<br/>learned noise plus the rule library"]
    MIG --> NORM
    REPLAY --> CDC["6. Database side effects<br/>Change Data Capture, row-level diff"]
    REPLAY --> COV["7. Coverage<br/>AltCover on the legacy runs"]
    NORM --> DIFF["5. Diff and group<br/>one signature per difference<br/>thousands of mismatches to a dozen root causes"]
    CDC --> DIFF
    DIFF --> OUT["8. Outputs<br/>HTML and PDF evidence report,<br/>accept list, CI gate"]
    COV --> OUT
```

The branch that matters is the one through runs A and B. Replaying the legacy app against itself is what tells the tool which differences are noise, before the migrated app is ever compared. Without it, every timestamp, generated ID and unordered list shows up as a finding and nobody triages the report.

Steps 6 and 7 arrive in Phase 4 and Phase 5; see [the roadmap](roadmap.md).

## What the operator does

```mermaid
graph TD
    I["Install<br/>single executable,<br/>or Windows service for capture"] --> C["Configure<br/>one config file per client"]
    C --> R["Record staging traffic"]
    R --> V["Run verify<br/>replay and diff"]
    V --> REV["Review the root-cause groups"]
    REV --> Q{"Real behaviour change?"}
    Q -->|"yes"| FIX["Fix the migrated app"]
    FIX --> V
    Q -->|"no"| ACC["Accept with a reason,<br/>or add a normalization rule"]
    ACC --> GATE["CI gate<br/>exit code plus JUnit results"]
    REV --> REP["Evidence report<br/>hashed to the recording and config"]
```

Accepted differences stay in the report as an audit trail; they stop failing the build without disappearing. Every false alarm an operator marks here is the number to watch: the share of reported groups that were not real differences, target under 10%.

# Windows machine setup

Provisioning the one Windows machine the test bed runs on. D-01 ([#2](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/2)) settled it as a physical machine with 16 GB RAM, not a cloud VM and not a VM on the Mac.

This runbook is the written form of what [T1.1](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/65) to [T1.3](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/67) need in place before they start. The setup scripts T1.12 ([#76](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/76)) delivers are what these steps turn into, so keep the two in step rather than letting them drift.

**Every step names the evidence it produces.** Per `docs/delivery-plan.md`, nothing is reported that cannot be pointed at, so the evidence is the point of the step, not paperwork after it.

## 0. Preflight

```powershell
# From an elevated PowerShell prompt, in the repository root
powershell -ExecutionPolicy Bypass -File .\scripts\test-bed\preflight.ps1 -DataDrive D:
```

Read-only — it installs nothing. It prints a table and writes `scripts/test-bed/preflight-report.md`, which is the evidence for the standup. Run it now to see what is missing, and again at the end to show it is not.

## Disk layout

When the system drive is short of space, the data goes on a second drive, and only the installs stay on the system drive. The current machine uses `D:`; pass `-DataDrive D:` to every preflight run so each drive is checked against its own share.

| Drive | Holds | Space |
| --- | --- | --- |
| System (`C:`) | Visual Studio, SQL Server binaries, .NET SDKs | 40 GB free |
| Data (`D:`) | Domain controller VM, SQL Server data, log and backup files, both apps | 110 GB free |

Point each piece at the data drive as it is installed, because moving it afterwards is harder than choosing the path up front:

- **Hyper-V**, after step 1's reboot: `Set-VMHost -VirtualMachinePath 'D:\TestBed\Hyper-V' -VirtualHardDiskPath 'D:\TestBed\Hyper-V\Virtual Hard Disks'`
- **SQL Server**, in step 5's setup, on the Database Engine Configuration → Data Directories tab: set the data root to `D:\TestBed\SQL`, which puts the data, log, tempdb and backup folders under it.
- **The apps**: clone the eShop forks and set the IIS site paths under `D:\TestBed\Apps`.

## 1. Windows edition and Hyper-V

**First, because it has the longest lead time and everything Kerberos depends on it.**

Hyper-V hosts the Active Directory domain controller ([T1.8](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/72)). Windows Home does not have Hyper-V, and the edition upgrade is its own delay.

```powershell
Get-ComputerInfo | Select-Object WindowsProductName, CsTotalPhysicalMemory
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All   # reboots
```

**Evidence:** `Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All` reports `Enabled` after the reboot.

**Decide the RAM question here too.** 16 GB is the floor, and it is tight: SQL Server, the legacy app, the port and a 2-4 GB domain controller VM share this machine. If RAM is being ordered, order it today — shipping is lead time on the critical path.

## 2. IIS, full, not IIS Express

IIS Express falls back to NTLM on localhost, which breaks the Kerberos work in week 3 ([T1.3](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/67), [R-105](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/48)).

```powershell
Enable-WindowsOptionalFeature -Online -All -FeatureName `
    IIS-WebServerRole, IIS-WebServer, IIS-ASPNET45, IIS-WindowsAuthentication, IIS-HttpLogging, IIS-ManagementConsole
```

`IIS-HttpLogging` is not optional here: D-08 ([#53](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/53)) reads the authenticated user out of the W3C log, joined on a request id the capture proxy injects. No logging, no user attribution, no Kerberos replay.

**Evidence:** `(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\InetStp').VersionString` reports 8.5 or later.

## 3. .NET Framework 4.8 Developer Pack

`eShopLegacyMVC` targets .NET Framework 4.7.2 ([T1.1](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/65)); the 4.8 developer pack covers it and is what Visual Studio builds against.

**Evidence:** the `Release` value under `HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full` is 461808 or higher.

## 4. Visual Studio 2022, ASP.NET workload

```powershell
winget install --id Microsoft.VisualStudio.2022.Community
```

Then add **ASP.NET and web development** in the Visual Studio Installer. This is the largest download of the whole setup; start it before the steps below rather than after.

**Evidence:** the solution in step 7 builds with no errors.

## 5. SQL Server Developer edition, with Agent running

Developer edition, not Express. D-10 ([#55](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/55)) chose Change Data Capture for Phase 4, and Express and Web editions do not have it. Developer is free and has the full feature set.

```powershell
Set-Service -Name SQLSERVERAGENT -StartupType Automatic
Start-Service -Name SQLSERVERAGENT
```

Agent matters as much as the edition: without it the CDC capture job never runs and the change tables stay **silently empty**, which is the worst way for Phase 4 to fail.

Install SQL Server Management Studio alongside it — the seeding and backup work in [T1.2](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/66) is much easier with it.

**Evidence:** `Get-Service SQLSERVERAGENT` reports `Running`, and the instance's `Edition` registry value says Developer.

## 6. .NET 10 SDK and Git

The .NET 10 SDK builds both the port ([R-102](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/14)) and the verifier itself; the version is pinned in `global.json`.

**Evidence:** `dotnet --list-sdks` shows a 10.x SDK, and `git --version` returns.

## 7. Prove it

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-bed\preflight.ps1 -DataDrive D:
```

Zero FAIL rows. Paste `preflight-report.md` into the current standup issue. That is the "Windows environment is ready" half of the Phase 0 exit gate; the rest of the gate is the requirements being locked.

## 8. Then, and only then

| Next | Task | Note |
| --- | --- | --- |
| Fork and build the legacy app | [T1.1](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/65) | `dotnet-architecture/eShopModernizing` is archived; fork it into our org |
| Point it at SQL Server | [T1.2](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/66) | `UseMockData` stays false — Phase 4 needs real writes |
| Host it on IIS | [T1.3](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/67) | Includes the 30-minute D-08 log-join check, done while IIS is open anyway |
| Domain controller VM | [T1.8](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/72) | Has lead time; must be ready before week 3. Give it 2-4 GB |

Kerberos note carried from D-08, worth reading before T1.9 rather than during it: the capture proxy sits in the request path, so the client obtains its ticket for the **proxy's** hostname while the backend IIS has to decrypt it. That needs the SPN for the proxy's hostname registered to the app pool identity, with `useAppPoolCredentials` set accordingly. Without it every request through the proxy returns 401, and the symptom does not point at the cause.

# Windows machine setup

Provisioning the one Windows machine the test bed runs on. D-01 ([#2](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/2)) settled it as a physical machine with 16 GB RAM, not a cloud VM and not a VM on the Mac. The machine runs Windows 11 Home, which has no Hyper-V and cannot join a domain, and there is no budget for a Pro upgrade. So the host only builds, and everything that needs a domain runs in two free VirtualBox VMs on Windows Server 2025 Evaluation.

This runbook is the written form of what [T1.1](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/65) to [T1.3](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/67) and [T1.8](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/72) need in place before they start. The setup scripts T1.12 ([#76](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/76)) delivers are what these steps turn into, so keep the two in step rather than letting them drift.

**Every step names the evidence it produces.** Per `docs/delivery-plan.md`, nothing is reported that cannot be pointed at, so the evidence is the point of the step, not paperwork after it.

## Layout

| Machine | Runs | RAM | Disk |
| --- | --- | --- | --- |
| Host, Windows 11 Home | Visual Studio, .NET SDKs, Git, VirtualBox | what is left, about 7 GB | `C:` for installs, 40 GB free |
| `dc01`, Server Core | Active Directory and DNS for `testbed.local` | 2 GB | about 30 GB on `D:` |
| `app01`, Server with Desktop Experience, joined to the domain | Full IIS, SQL Server Developer with Agent, both eShop versions | 6 GB | about 60 GB on `D:` |

The requirements do not change, only where they are met: full IIS rather than IIS Express, Kerberos ([R-105](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/48)), SQL Server Agent for CDC (D-10, [#55](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/55)) and W3C logging (D-08, [#53](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/53)). Kerberos now crosses a real network between domain members, which is closer to what customers have than a single box.

Two things to keep in mind throughout:

- **RAM is tight.** Shut down VMs you are not using, cap SQL Server's memory (step 6), and close browser tabs while both VMs run. Swapping makes replay timings noisy.
- **The host is not a domain member,** so it cannot obtain a Kerberos ticket. Windows quietly falls back to NTLM instead of failing, so Kerberos tests run from inside a domain-joined VM, and each one is checked with `klist`.

## 0. Preflight

The script runs in two places, and each role checks only what that machine needs:

```powershell
# On the host, from an elevated PowerShell prompt, in the repository root
powershell -ExecutionPolicy Bypass -File .\scripts\test-bed\preflight.ps1 -Role Host -DataDrive D:

# Inside app01, from an elevated prompt, once the repository is copied or cloned there
powershell -ExecutionPolicy Bypass -File .\scripts\test-bed\preflight.ps1 -Role AppServer
```

Read-only — it installs nothing. It prints a table and writes `scripts/test-bed/preflight-report.md`, which is the evidence for the standup. Run it now to see what is missing, and again at the end to show it is not. `-Role AllInOne` keeps the original single-machine checks, for a Pro machine with Hyper-V.

## 1. Host: VirtualBox, with VMs on `D:`

```powershell
winget install Oracle.VirtualBox
& "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" setproperty machinefolder 'D:\TestBed\VMs'
```

CPU virtualisation must be on in the BIOS (SVM on AMD, VT-x on Intel). It is on this machine.

**Evidence:** the host preflight shows VirtualBox and VirtualBox machine folder as PASS.

## 2. Windows Server 2025 Evaluation ISO

Download the ISO from the Microsoft Evaluation Center into `D:\TestBed\ISO`. It is free and fully featured for 180 days, and `slmgr /rearm` extends it, up to five times. The licence runs out around mid-April 2027, close to the v1 ship date, so set a reminder for 1 Apr 2027 to check `slmgr /dlv` on both VMs.

**Evidence:** the ISO is on `D:\TestBed\ISO`.

## 3. `dc01`: domain controller

**First of the VMs, because it has the longest lead time and everything Kerberos depends on it.**

`scripts/test-bed/new-vms.ps1` creates both VMs on the `TestBed` NAT Network (`10.10.10.0/24`) and installs them unattended, `dc01` as **Server Core** with 2 GB RAM. The guests' VBoxService may come up stopped; if `VBoxManage guestcontrol` reports "guest execution service is not ready", run `Restart-Service VBoxService` from an elevated prompt in the guest and set it to restart on failure:

```powershell
sc.exe failure VBoxService reset= 86400 actions= restart/5000/restart/5000/restart/30000
```

`dc01` needs a fixed address outside the DHCP range, so first move the NAT Network's DHCP range up, on the host:

```powershell
& "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" dhcpserver modify --network TestBed --server-ip 10.10.10.2 --netmask 255.255.255.0 --lower-ip 10.10.10.100 --upper-ip 10.10.10.254 --enable
```

Then, on `dc01` (it is already named `dc01` by the unattended install):

```powershell
New-NetIPAddress -InterfaceAlias Ethernet -IPAddress 10.10.10.10 -PrefixLength 24 -DefaultGateway 10.10.10.1
Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses 8.8.8.8,1.1.1.1
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName testbed.local -DomainNetbiosName TESTBED -InstallDns   # reboots
```

Promotion points `dc01`'s DNS at itself and keeps 8.8.8.8 and 1.1.1.1 as forwarders. For a few minutes after the reboot `Get-ADDomain` fails with "Unable to find a default server" while SYSVOL initialises; wait for `nltest /dsgetdc:testbed.local` to succeed.

**Evidence:** `Get-ADDomain` on `dc01` returns `testbed.local`, and `nltest /dsgetdc:testbed.local` returns `dc01.testbed.local` at `10.10.10.10`.

## 4. `app01`: application server, joined to the domain

`new-vms.ps1` creates `app01` with 6 GB RAM and Desktop Experience, already named `app01`, on the same NAT Network (`Ethernet`) plus a VirtualBox **host-only** adapter (`Ethernet 2`), since the host cannot reach a VM on a NAT Network. From an elevated prompt on `app01`, point its DNS at `dc01`, keep the host-only address out of the domain's DNS, and join:

```powershell
sc.exe failure VBoxService reset= 86400 actions= restart/5000/restart/5000/restart/30000
Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses 10.10.10.10
Set-DnsClient -InterfaceAlias 'Ethernet 2' -RegisterThisConnectionsAddress $false
Add-Computer -DomainName testbed.local -Credential TESTBED\tbadmin -Restart
```

The join can still register the host-only address. If `Resolve-DnsName app01.testbed.local` on `dc01` returns `192.168.56.x`, delete that A record on `dc01` with `Remove-DnsServerResourceRecord -ZoneName testbed.local -Name app01 -RRType A -RecordData <address>`.

On the host, from an elevated prompt, add `app01`'s host-only address to the hosts file. That is the path the host publishes builds and browses over.

```powershell
Add-Content C:\Windows\System32\drivers\etc\hosts "`r`n192.168.56.101`tapp01.testbed.local"
```

**Evidence:** the app server preflight shows Domain membership as PASS, `Test-ComputerSecureChannel` on `app01` returns `True`, and on the host `Test-NetConnection app01.testbed.local -Port 5985` succeeds.

Once `app01` is in the domain, steps 5 and 6 do not need its console. `VBoxManage guestcontrol` into `app01` runs with a filtered, non-admin token, but from `dc01` a remote session as the domain Administrator is fully elevated:

```powershell
# on dc01
Invoke-Command -ComputerName app01.testbed.local -Credential TESTBED\Administrator -FilePath .\step.ps1
```

## 5. `app01`: IIS, full, not IIS Express

IIS Express falls back to NTLM on localhost, which breaks the Kerberos work in week 3 ([T1.3](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/67), [R-105](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/48)).

```powershell
Install-WindowsFeature Web-Server, Web-Asp-Net45, Web-Windows-Auth, Web-Http-Logging, Web-Mgmt-Console
```

Then install the **.NET 10 Hosting Bundle** and run `iisreset`, so the port can run on IIS behind Windows Authentication too.

`Web-Http-Logging` is not optional here: D-08 ([#53](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/53)) reads the authenticated user out of the W3C log, joined on a request id the capture proxy injects. No logging, no user attribution, no Kerberos replay.

**Evidence:** the app server preflight shows IIS, IIS Windows Authentication, IIS HTTP Logging and ASP.NET Core Hosting Bundle as PASS.

## 6. `app01`: SQL Server Developer edition, with Agent running

Developer edition, not Express. D-10 ([#55](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/55)) chose Change Data Capture for Phase 4, and Express and Web editions do not have it. SQL Server 2025 splits Developer into Standard Developer and Enterprise Developer; both are free and both have CDC.

Download the bootstrapper from the [winget manifest](https://github.com/microsoft/winget-pkgs/tree/master/manifests/m/Microsoft/SQLServer/2025/Developer) URL and check its SHA256 against the manifest, then fetch the media and install the engine quietly:

```powershell
.\SQL2025-SSEI-StdDev.exe /ACTION=Download /MEDIAPATH=C:\SQLMedia /MEDIATYPE=ISO /QUIET
$drive = (Mount-DiskImage C:\SQLMedia\SQLServer2025-x64-ENU-StdDev.iso -PassThru | Get-Volume).DriveLetter
& "${drive}:\setup.exe" /Q /ACTION=Install /IACCEPTSQLSERVERLICENSETERMS /SUPPRESSPRIVACYSTATEMENTNOTICE `
    /FEATURES=SQLENGINE /INSTANCENAME=MSSQLSERVER `
    /SQLSVCACCOUNT="NT Service\MSSQLSERVER" /AGTSVCACCOUNT="NT Service\SQLSERVERAGENT" `
    /SQLSVCSTARTUPTYPE=Automatic /AGTSVCSTARTUPTYPE=Automatic `
    /SQLSYSADMINACCOUNTS="TESTBED\tbadmin" "TESTBED\Domain Admins" `
    /SQLMAXMEMORY=2560 /TCPENABLED=1 /UPDATEENABLED=0
Set-Service -Name SQLSERVERAGENT -StartupType Automatic
Start-Service -Name SQLSERVERAGENT
New-NetFirewallRule -Name TestBed-SQL-1433 -DisplayName 'SQL Server 1433 (test bed)' -Direction Inbound `
    -Protocol TCP -LocalPort 1433 -RemoteAddress 10.10.10.0/24, 192.168.56.0/24 -Action Allow
```

Agent matters as much as the edition: without it the CDC capture job never runs and the change tables stay **silently empty**, which is the worst way for Phase 4 to fail.

`/SQLMAXMEMORY=2560` caps the instance at about 2.5 GB (**Server Properties → Memory → Maximum server memory** afterwards), or SQL Server takes the whole VM and IIS starts paging.

Install SQL Server Management Studio on the host and connect to `app01` — the seeding and backup work in [T1.2](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/66) is much easier with it.

**Evidence:** the app server preflight shows SQL Server edition and SQL Server Agent as PASS, and a Windows-authenticated connection from `dc01` to `app01` reports `auth_scheme` `KERBEROS` in `sys.dm_exec_connections`.

## 7. Host: .NET Framework 4.8 Developer Pack

`eShopLegacyMVC` targets .NET Framework 4.7.2 ([T1.1](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/65)); the 4.8 developer pack covers it and is what Visual Studio builds against. Windows Server 2025 already has the 4.8.1 runtime, so `app01` needs nothing extra.

The Visual Studio ASP.NET workload in step 8 installs it, so check before downloading anything.

**Evidence:** `Test-Path "${env:ProgramFiles(x86)}\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8\mscorlib.dll"` returns `True`. The runtime `Release` value under `HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full` (461808 or higher) only shows the runtime, which is there without the developer pack.

## 8. Host: Visual Studio 2022, ASP.NET workload

```powershell
winget install --id Microsoft.VisualStudio.2022.Community
```

Then add **ASP.NET and web development** in the Visual Studio Installer. This is the largest download of the whole setup; start it before the VM steps rather than after. `C:` is short of space, so on the installer's **Installation locations** tab move the download cache and shared components to `D:`.

If `C:` drops under the preflight floor later (the page file grows once the VMs take 8 GB of RAM), move the caches rather than deleting them. From an elevated prompt, with Visual Studio closed:

```powershell
reg add HKLM\SOFTWARE\Microsoft\VisualStudio\Setup /v CachePath /d D:\VisualStudio\Cache /f
robocopy C:\ProgramData\Microsoft\VisualStudio\Packages D:\VisualStudio\Cache /E /MOVE
```

Without elevation: `npm config set cache D:\Cache\npm`, a user `PIP_CACHE_DIR` of `D:\Cache\pip`, user `TEMP` and `TMP` of `D:\Temp`, and `wsl --manage Ubuntu --move D:\WSL\Ubuntu`. On this machine those freed about 10 GB.

Build on the host, then publish to `app01` over its admin share or Web Deploy. The apps live under `C:\TestBed\Apps` on `app01`.

**Evidence:** the solution in step 10 builds with no errors.

## 9. Host: .NET 10 SDK and Git

The .NET 10 SDK builds both the port ([R-102](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/14)) and the verifier itself; the version is pinned in `global.json`.

```powershell
winget install Microsoft.DotNet.SDK.10
```

**Evidence:** `dotnet --list-sdks` shows a 10.x SDK, and `git --version` returns.

## 10. Prove it

```powershell
# On the host
powershell -ExecutionPolicy Bypass -File .\scripts\test-bed\preflight.ps1 -Role Host -DataDrive D:
# Inside app01
powershell -ExecutionPolicy Bypass -File .\scripts\test-bed\preflight.ps1 -Role AppServer
```

Zero FAIL rows in both. Paste both `preflight-report.md` files into the current standup issue. That is the "Windows environment is ready" half of the Phase 0 exit gate; the rest of the gate is the requirements being locked.

## 11. Then, and only then

| Next | Task | Note |
| --- | --- | --- |
| Fork and build the legacy app | [T1.1](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/65) | `dotnet-architecture/eShopModernizing` is archived; fork it into our org |
| Point it at SQL Server | [T1.2](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/66) | `UseMockData` stays false — Phase 4 needs real writes |
| Host it on IIS | [T1.3](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/67) | On `app01`. Includes the 30-minute D-08 log-join check, done while IIS is open anyway |
| Domain controller VM | [T1.8](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/72) | Steps 3-4 above; must be ready before week 3. Also settle where the Kerberos test client runs |

Kerberos note carried from D-08, worth reading before T1.9 rather than during it: the capture proxy sits in the request path, so the client obtains its ticket for the **proxy's** hostname while the backend IIS has to decrypt it. That needs the SPN for the proxy's hostname registered to the app pool identity, with `useAppPoolCredentials` set accordingly. Without it every request through the proxy returns 401, and the symptom does not point at the cause.

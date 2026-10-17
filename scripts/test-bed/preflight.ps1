#Requires -Version 5.1
<#
.SYNOPSIS
    Checks the Windows machine against everything the test bed needs, and writes the result as evidence.

.DESCRIPTION
    Read-only. Installs nothing and changes nothing. Run it before provisioning to see what is
    missing, and again after, to produce the evidence the Phase 0 exit gate asks for.

    Every check names what it found, what is needed and how to fix it, so the output can be pasted
    into a GitHub issue as it stands.

.PARAMETER ReportPath
    Where to write the markdown report. Defaults to preflight-report.md next to this script.

.PARAMETER DataDrive
    The drive that holds the domain controller VM, SQL Server data and the apps, such as D:.
    Defaults to the system drive. When it is a different drive, the system drive only needs room
    for the installs, and each drive is checked against its own share.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\preflight.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\preflight.ps1 -DataDrive D:
#>
[CmdletBinding()]
param(
    [string]$ReportPath,
    [string]$DataDrive
)

$ErrorActionPreference = 'Stop'

# $PSScriptRoot can be empty while parameter defaults are evaluated on Windows PowerShell 5.1,
# so the default is resolved here instead.
if (-not $ReportPath) {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $ReportPath = Join-Path $scriptDir 'preflight-report.md'
}
$checks = New-Object System.Collections.ArrayList

function Add-Check {
    param($Name, $Status, $Found, $Needed, $Fix, $Why)
    [void]$checks.Add([pscustomobject]@{
        Name = $Name; Status = $Status; Found = $Found; Needed = $Needed; Fix = $Fix; Why = $Why
    })
}

# Returns the state of an optional feature on a client OS, or a server role on Windows Server.
function Get-FeatureState {
    param([string]$ClientName, [string]$ServerName)
    try {
        $f = Get-WindowsOptionalFeature -Online -FeatureName $ClientName -ErrorAction Stop
        return "$($f.State)"
    } catch {
        try {
            $f = Get-WindowsFeature -Name $ServerName -ErrorAction Stop
            return $(if ($f.Installed) { 'Enabled' } else { 'Disabled' })
        } catch {
            return 'Unknown'
        }
    }
}

# Maps a feature state onto a check status. Unknown means the check could not run, not that it failed.
function Get-FeatureStatus {
    param([string]$State)
    switch ($State) { 'Enabled' { 'PASS' } 'Unknown' { 'WARN' } default { 'FAIL' } }
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning 'Not running as Administrator. Feature checks will report Unknown. Re-run from an elevated prompt for a complete result.'
}

# --- Machine ------------------------------------------------------------------------------------

$os  = Get-CimInstance Win32_OperatingSystem
$cs  = Get-CimInstance Win32_ComputerSystem
$ramGb = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)

Add-Check 'Windows edition' `
    $(if ($os.Caption -match 'Home') { 'FAIL' } else { 'PASS' }) `
    "$($os.Caption) build $($os.BuildNumber)" 'Pro, Enterprise or Server' `
    'Upgrade the edition. This has its own lead time, so settle it first.' `
    'Home has no Hyper-V, so there is no domain controller and no Kerberos test bed (T1.8, #72).'

Add-Check 'RAM' `
    $(if ($ramGb -lt 15.5) { 'FAIL' } elseif ($ramGb -lt 31) { 'WARN' } else { 'PASS' }) `
    "$ramGb GB" '16 GB minimum, 32 GB comfortable' `
    'Order RAM now if it is coming; shipping is lead time on the critical path.' `
    'SQL Server, the legacy app, the port and a 2-4 GB domain controller VM share this box (D-01, #2).'

# Free space in GB on a drive given as 'D' or 'D:', or $null when the drive does not exist.
function Get-FreeGb {
    param([string]$Drive)
    $d = Get-PSDrive -Name $Drive.TrimEnd(':') -PSProvider FileSystem -ErrorAction SilentlyContinue
    if ($d) { [math]::Round($d.Free / 1GB, 1) } else { $null }
}

$sysDriveName = $env:SystemDrive.TrimEnd(':').ToUpper()
$dataDriveName = $(if ($DataDrive) { $DataDrive.TrimEnd(':', '\').ToUpper() } else { $sysDriveName })
$sysFreeGb = Get-FreeGb $sysDriveName

if ($dataDriveName -eq $sysDriveName) {
    Add-Check 'Free disk' `
        $(if ($sysFreeGb -lt 60) { 'FAIL' } elseif ($sysFreeGb -lt 150) { 'WARN' } else { 'PASS' }) `
        "$sysFreeGb GB free on ${sysDriveName}:" '150 GB recommended' `
        'Free space, or put the VM and SQL data on another drive and pass -DataDrive.' `
        'Visual Studio with the ASP.NET workload, SQL Server Developer, a Windows Server VM and two apps.'
} else {
    Add-Check 'Free disk, system' `
        $(if ($sysFreeGb -lt 25) { 'FAIL' } elseif ($sysFreeGb -lt 40) { 'WARN' } else { 'PASS' }) `
        "$sysFreeGb GB free on ${sysDriveName}:" '40 GB recommended' `
        'Free space before installing, not halfway through the Visual Studio installer.' `
        'Visual Studio, the SQL Server binaries and the .NET SDKs install here whatever the data drive.'

    $dataFreeGb = Get-FreeGb $dataDriveName
    Add-Check 'Free disk, data' `
        $(if ($null -eq $dataFreeGb -or $dataFreeGb -lt 60) { 'FAIL' } elseif ($dataFreeGb -lt 110) { 'WARN' } else { 'PASS' }) `
        $(if ($null -eq $dataFreeGb) { "${dataDriveName}: not found" } else { "$dataFreeGb GB free on ${dataDriveName}:" }) `
        '110 GB recommended' `
        'Free space on the data drive, or pick another one with -DataDrive.' `
        'The domain controller VM, SQL Server data, log and backup files, and both apps live here.'
}

$hyperV = Get-FeatureState 'Microsoft-Hyper-V-All' 'Hyper-V'
Add-Check 'Hyper-V' (Get-FeatureStatus $hyperV) $hyperV 'Enabled' `
    'Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All   (reboots)' `
    'The Active Directory domain controller runs as a VM here. No Hyper-V, no Kerberos (T1.8, #72).'

Add-Check 'Domain membership' `
    $(if ($cs.PartOfDomain) { 'PASS' } else { 'WARN' }) `
    $(if ($cs.PartOfDomain) { "joined to $($cs.Domain)" } else { "workgroup $($cs.Workgroup)" }) `
    'Joined to the test domain before week 3' `
    'Stand up the domain controller first (T1.8, #72), then join this machine to it.' `
    'Expected to be a workgroup until T1.8 is done; this is only a failure from week 3 onwards.'

# --- IIS ----------------------------------------------------------------------------------------

$iisVersion = try { (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\InetStp' -ErrorAction Stop).VersionString } catch { $null }
Add-Check 'IIS (full, not IIS Express)' `
    $(if ($iisVersion) { 'PASS' } else { 'FAIL' }) `
    $(if ($iisVersion) { $iisVersion } else { 'not installed' }) 'IIS 8.5 or later' `
    'Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All' `
    'IIS Express falls back to NTLM on localhost, which breaks the Kerberos work (T1.3, #67).'

$winAuth = Get-FeatureState 'IIS-WindowsAuthentication' 'Web-Windows-Auth'
Add-Check 'IIS Windows Authentication' (Get-FeatureStatus $winAuth) $winAuth 'Enabled' `
    'Enable-WindowsOptionalFeature -Online -FeatureName IIS-WindowsAuthentication -All' `
    'The Kerberos variant of the test bed runs behind it (R-105, #48).'

$httpLog = Get-FeatureState 'IIS-HttpLogging' 'Web-Http-Logging'
Add-Check 'IIS HTTP Logging' (Get-FeatureStatus $httpLog) $httpLog 'Enabled' `
    'Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging -All' `
    'D-08 (#53) reads the authenticated user from the W3C log, joined on a request id. No logging, no user attribution.'

# --- Runtimes and tools -------------------------------------------------------------------------

$ndpRelease = try { (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -ErrorAction Stop).Release } catch { 0 }
Add-Check '.NET Framework 4.7.2+' `
    $(if ($ndpRelease -ge 461808) { 'PASS' } else { 'FAIL' }) `
    $(if ($ndpRelease) { "release $ndpRelease" } else { 'not found' }) 'release 461808 or higher' `
    'Install the .NET Framework 4.8 Developer Pack.' `
    'eShopLegacyMVC targets .NET Framework 4.7.2 (T1.1, #65).'

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vsFound = $null
if (Test-Path $vswhere) {
    $vsFound = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Workload.NetWeb -property catalog_productDisplayVersion 2>$null | Select-Object -First 1
}
Add-Check 'Visual Studio 2022, ASP.NET workload' `
    $(if ($vsFound) { 'PASS' } else { 'FAIL' }) `
    $(if ($vsFound) { "version $vsFound" } elseif (Test-Path $vswhere) { 'installed, ASP.NET workload missing' } else { 'not installed' }) `
    'VS 2022 with the "ASP.NET and web development" workload' `
    'winget install Microsoft.VisualStudio.2022.Community, then add the ASP.NET workload.' `
    'The legacy solution is built here (T1.1, #65).'

$sdks = try { (& dotnet --list-sdks 2>$null) } catch { @() }
$net10 = $sdks | Where-Object { $_ -match '^10\.' } | Select-Object -First 1
Add-Check '.NET 10 SDK' `
    $(if ($net10) { 'PASS' } else { 'FAIL' }) `
    $(if ($net10) { ($net10 -split ' ')[0] } elseif ($sdks) { "only $(($sdks | ForEach-Object { ($_ -split ' ')[0] }) -join ', ')" } else { 'dotnet not found' }) `
    'pinned in global.json' `
    'Install the .NET 10 SDK.' `
    'Builds the port (R-102, #14) and the verifier itself.'

# --- SQL Server ---------------------------------------------------------------------------------

$instances = try { Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -ErrorAction Stop } catch { $null }
$editions = @()
if ($instances) {
    foreach ($name in ($instances.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' }).Name) {
        $id = $instances.$name
        $edition = try { (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$id\Setup" -ErrorAction Stop).Edition } catch { 'unknown edition' }
        $editions += "$name ($edition)"
    }
}
$hasCdcEdition = $editions -match 'Developer|Enterprise|Standard'
Add-Check 'SQL Server edition' `
    $(if ($hasCdcEdition) { 'PASS' } else { 'FAIL' }) `
    $(if ($editions) { $editions -join '; ' } else { 'no instance found' }) `
    'Developer, Standard or Enterprise' `
    'Install SQL Server Developer edition (free, full feature set).' `
    'D-10 (#55) chose Change Data Capture, which Express and Web editions do not have.'

$agent = Get-Service -Name 'SQLSERVERAGENT', 'SQLAgent$*' -ErrorAction SilentlyContinue
Add-Check 'SQL Server Agent' `
    $(if ($agent | Where-Object Status -eq 'Running') { 'PASS' } else { 'FAIL' }) `
    $(if ($agent) { ($agent | ForEach-Object { "$($_.Name): $($_.Status)" }) -join '; ' } else { 'service not found' }) `
    'Running, and set to start automatically' `
    'Set-Service -Name SQLSERVERAGENT -StartupType Automatic; Start-Service SQLSERVERAGENT' `
    'The CDC capture job does not run without Agent, and the change tables stay silently empty (D-10, #55).'

$git = try { (& git --version 2>$null) } catch { $null }
Add-Check 'Git' $(if ($git) { 'PASS' } else { 'FAIL' }) $(if ($git) { $git } else { 'not installed' }) 'any recent version' `
    'winget install Git.Git' 'Cloning the fork (T1.1, #65).'

# --- Report -------------------------------------------------------------------------------------

$fails = @($checks | Where-Object Status -eq 'FAIL').Count
$warns = @($checks | Where-Object Status -eq 'WARN').Count
$passes = @($checks | Where-Object Status -eq 'PASS').Count

$lines = New-Object System.Collections.ArrayList
[void]$lines.Add("## Test bed preflight - $(Get-Date -Format 'ddd dd MMM yyyy HH:mm')")
[void]$lines.Add('')
[void]$lines.Add("Machine: ``$env:COMPUTERNAME`` · $passes pass · $warns warn · **$fails fail**")
if (-not $isAdmin) { [void]$lines.Add('') ; [void]$lines.Add('> Not run as Administrator, so feature checks may report Unknown.') }
[void]$lines.Add('')
[void]$lines.Add('| Check | Status | Found | Needed |')
[void]$lines.Add('| --- | --- | --- | --- |')
foreach ($c in $checks) {
    [void]$lines.Add("| $($c.Name) | $($c.Status) | $($c.Found) | $($c.Needed) |")
}
$notPassing = $checks | Where-Object Status -ne 'PASS'
if ($notPassing) {
    [void]$lines.Add('')
    [void]$lines.Add('### What to do')
    [void]$lines.Add('')
    foreach ($c in $notPassing) {
        [void]$lines.Add("**$($c.Name)** - $($c.Why)")
        [void]$lines.Add('')
        [void]$lines.Add("    $($c.Fix)")
        [void]$lines.Add('')
    }
}

$report = $lines -join [Environment]::NewLine
Set-Content -Path $ReportPath -Value $report -Encoding UTF8

$checks | Format-Table Name, Status, Found -AutoSize
Write-Host ''
Write-Host "$passes pass, $warns warn, $fails fail. Report written to $ReportPath" -ForegroundColor $(if ($fails) { 'Red' } else { 'Green' })
Write-Host 'Paste that file into the standup issue as evidence.'

exit $(if ($fails) { 1 } else { 0 })

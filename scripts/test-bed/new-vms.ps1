#Requires -Version 5.1
<#
.SYNOPSIS
    Creates the dc01 and app01 VirtualBox VMs and starts an unattended Windows Server install in each.

.DESCRIPTION
    The test bed layout from D-01 (#2): dc01 is the domain controller (Server Core, 2 GB), app01
    serves IIS and SQL Server (Desktop Experience, 6 GB). Both sit on the TestBed NAT Network so they
    reach each other and the internet; app01 also gets a host-only adapter so the host can reach it.

    A VM that already exists is left alone, so the script is safe to re-run. The guest installs take
    20-40 minutes each after the script returns; watch them in the VirtualBox window.

    The lab admin password is read from -PasswordFile. When the file does not exist a random one is
    generated into it. Keep that file outside the repository.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\test-bed\new-vms.ps1
#>
[CmdletBinding()]
param(
    [string]$IsoPath = 'D:\TestBed\ISO\WindowsServer2025_Eval_x64_en-us.iso',
    [string]$MachineFolder = 'D:\TestBed\VMs',
    [string]$PasswordFile = 'D:\TestBed\secrets\admin-password.txt',
    [string]$NatNetwork = 'TestBed',
    [string]$NatCidr = '10.10.10.0/24',
    [string]$HostOnlyAdapter = 'VirtualBox Host-Only Ethernet Adapter',
    [string]$Domain = 'testbed.local'
)

$ErrorActionPreference = 'Stop'

$vboxDir = $(if ($env:VBOX_MSI_INSTALL_PATH) { $env:VBOX_MSI_INSTALL_PATH } else { Join-Path $env:ProgramFiles 'Oracle\VirtualBox' })
$vbm = Join-Path $vboxDir 'VBoxManage.exe'
if (-not (Test-Path $vbm)) { throw "VBoxManage not found at $vbm. Install VirtualBox first: winget install Oracle.VirtualBox" }
if (-not (Test-Path $IsoPath)) { throw "ISO not found at $IsoPath. See step 2 of docs/test-bed/windows-setup.md." }

# Runs VBoxManage and stops on a non-zero exit, since $ErrorActionPreference does not cover native commands.
function Invoke-VBox {
    & $vbm @args
    if ($LASTEXITCODE -ne 0) { throw "VBoxManage $($args -join ' ') failed with exit code $LASTEXITCODE" }
}

if (-not (Test-Path $PasswordFile)) {
    New-Item -ItemType Directory -Force (Split-Path -Parent $PasswordFile) | Out-Null
    # Upper, lower, digit and symbol, so it meets the Windows Server complexity policy.
    $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[] 16
    $rng.GetBytes($bytes)
    $password = 'Tb!' + (-join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })) + '9a'
    [IO.File]::WriteAllText($PasswordFile, $password)
    Write-Host "Generated the lab admin password into $PasswordFile"
}

Invoke-VBox setproperty machinefolder $MachineFolder

if (-not ((& $vbm natnetwork list) -match "^Name:\s+$NatNetwork$")) {
    Invoke-VBox natnetwork add --netname $NatNetwork --network $NatCidr --enable --dhcp on
    Write-Host "Created NAT Network $NatNetwork ($NatCidr)"
}

$existing = (& $vbm list vms) -replace '^"([^"]+)".*$', '$1'
$timeZone = (Get-TimeZone).Id

$vms = @(
    @{ Name = 'dc01';  ImageIndex = 1; MemoryMb = 2048; Cpus = 2; DiskMb = 30720; HostOnly = $false },
    @{ Name = 'app01'; ImageIndex = 2; MemoryMb = 6144; Cpus = 2; DiskMb = 61440; HostOnly = $true }
)

foreach ($vm in $vms) {
    $name = $vm.Name
    if ($existing -contains $name) {
        Write-Host "$name already exists; leaving it alone."
        continue
    }

    Invoke-VBox createvm --name $name --ostype Windows2025_64 --basefolder $MachineFolder --register
    Invoke-VBox modifyvm $name --memory $vm.MemoryMb --cpus $vm.Cpus --firmware efi --ioapic on `
        --graphicscontroller vboxsvga --vram 128 --audio-enabled off --clipboard-mode bidirectional `
        --nic1 natnetwork --nat-network1 $NatNetwork
    if ($vm.HostOnly) {
        Invoke-VBox modifyvm $name --nic2 hostonly --host-only-adapter2 $HostOnlyAdapter
    }

    $disk = Join-Path (Join-Path $MachineFolder $name) "$name.vdi"
    Invoke-VBox createmedium disk --filename $disk --size $vm.DiskMb --format VDI
    Invoke-VBox storagectl $name --name SATA --add sata --controller IntelAhci --portcount 2
    Invoke-VBox storageattach $name --storagectl SATA --port 0 --device 0 --type hdd --medium $disk

    Invoke-VBox unattended install $name --iso $IsoPath --image-index $vm.ImageIndex `
        --user tbadmin --user-password-file $PasswordFile --admin-password-file $PasswordFile `
        --hostname "$name.$Domain" --time-zone $timeZone --locale en_US --country US `
        --install-additions --start-vm gui

    Write-Host "$name created on $disk and installing (image $($vm.ImageIndex), $($vm.MemoryMb) MB)."
}

Write-Host ''
Write-Host 'Next: when both installs finish, continue at step 3 of docs/test-bed/windows-setup.md.'

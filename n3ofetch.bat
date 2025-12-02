:: =========================================================================================================
::  n3ofetch – Windows System Information Display
:: ---------------------------------------------------------------------------------------------------------
::  Version:      1.0.1
::  Author:       techronmic
::  Contact:      techronmic@gmail.com
::  GitHub        https://github.com/techronmic/n3ofetch
::  Created:      2026-02-12
::  License:      BSD 3-Clause License
::
::  Description:
::      n3ofetch is a lightweight, system information tool for:
::      • Windows 10 / 11
::      • Windows Server 2019 - 2025
::
::      Features:
::      ✓ Clean system overview in neofetch-style layout
::      ✓ Fully PowerShell-optimized with minimal overhead
::      ✓ Shows: OS, Build, Kernel, Uptime, System, Apps, Terminal, Resolution
::      ✓ Shows: Baseboard, BIOS, CPU, GPU, RAM summary, RAM usage, Disk usage, Total storage
::      ✓ Shows: Active physical network adapter (no virtual/NIC teaming)
::
::      Notes:
::      • Storage Space includes local volumes AND mapped network drives (FileSystem PSDrives)
::      • Running n3ofetch from a local path (not UNC / mapped share) is recommended
::
::      Optimized for:
::      • High performance (grouped PowerShell queries)
::      • Clear structure & maintainability
::      • Full portability (no external dependencies)
::
::  Support / Donation:
::      PayPal: https://www.paypal.com/donate/?hosted_button_id=U4MVM7GJ5XMDY
:: =========================================================================================================

@echo off
setlocal EnableDelayedExpansion

:: ------------------------------------------------------------
:: Environment checks
:: ------------------------------------------------------------

:: Check PowerShell availability
where powershell >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR] PowerShell was not found on this system.
    echo         n3ofetch requires Windows PowerShell 5.0 or later.
    echo.
    goto End
)

:: Check PowerShell version (must be 5.0+)
for /f "tokens=1,2" %%a in ('
    powershell -NoLogo -NoProfile -Command "$v=$PSVersionTable.PSVersion; Write-Output ($v.Major.ToString() + ' ' + $v.Minor.ToString())"
') do (
    set "PSMaj=%%a"
    set "PSMin=%%b"
)

if not defined PSMaj set "PSMaj=0"
if not defined PSMin set "PSMin=0"

if %PSMaj% LSS 5 (
    echo.
    echo [ERROR] PowerShell version %PSMaj%.%PSMin% detected.
    echo         n3ofetch requires at least PowerShell 5.0.
    echo.
    goto End
)

:: ------------------------------------------------------------
:: Global settings
:: ------------------------------------------------------------
set "PS=powershell -NoLogo -NoProfile -Command"

:: Terminal setup
title n3ofetch v1.0.1
color 07
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "del=%%a")
cls

:: ------------------------------------------------------------
::  SYSTEM INFORMATION
:: ------------------------------------------------------------

:: ------------------------------------------------------------
:: OS information + System role + Uptime + RAM usage (1 PowerShell call)
::  - WinOS, OSArch, WinVersion, SystemRole
::  - UpTimeValue, UsedMemoryMB, TotalMemoryMB, MemoryUtilizationPercentage
:: ------------------------------------------------------------
for /f "tokens=1-8 delims=|" %%a in ('
    %PS% "$os = Get-CimInstance Win32_OperatingSystem; $cs = Get-CimInstance Win32_ComputerSystem; $osCaption = $os.Caption; $caption = $os.Caption; $arch = $os.OSArchitecture; $ver = $os.Version; $texts = @(); if ($cs.Model) { $texts += $cs.Model }; if ($cs.SystemFamily) { $texts += $cs.SystemFamily }; if ($cs.SystemSKUNumber) { $texts += $cs.SystemSKUNumber }; $blob = ($texts -join ' '); $role = 'Client'; if ($osCaption -like '*Server*') { $role = 'Server' } elseif ($osCaption -match '(?i)\b(Pro|Home)\b') { $role = 'Client' } else { $role = 'Client' }; if ($role -ne 'Server') { if ($blob -match '(?i)Notebook') { $role = 'Notebook' } elseif ($blob -match '(?i)Workstation') { $role = 'Workstation' } }; $isVM = $false; $vmIndicators = @('VirtualBox','VMware','KVM','Virtual Machine','Hyper-V','HVM domU','QEMU'); $model = $cs.Model; $manu = $cs.Manufacturer; foreach ($v in $vmIndicators) { if (($model -like ('*' + $v + '*')) -or ($manu -like ('*' + $v + '*'))) { $isVM = $true; break } }; if (-not $isVM -and $cs.HypervisorPresent) { $isVM = $true }; if ($isVM) { $role = $role + ' (Virtual Machine)' }; $u = (Get-Date) - $os.LastBootUpTime; $totalKB = [int]$os.TotalVisibleMemorySize; $freeKB = [int]$os.FreePhysicalMemory; if($totalKB -le 0){ $usedMB = 0; $totalMB = 0; $pct = 0 } else { $totalMB = [int]($totalKB / 1024); $usedMB = [int](($totalKB - $freeKB) / 1024); $pct = [int]( (($totalKB - $freeKB) * 100) / $totalKB ); }; $up = '{0} days, {1} hours, {2} minutes' -f $u.Days, $u.Hours, $u.Minutes; Write-Output ($caption + '|' + $arch + '|' + $ver + '|' + $role + '|' + $up + '|' + $usedMB.ToString() + '|' + $totalMB.ToString() + '|' + $pct.ToString())"
') do (
    set "WinOS=%%a"
    set "OSArch=%%b"
    set "WinVersion=%%c"
    set "SystemRole=%%d"
    set "UpTimeValue=%%e"
    set "UsedMemoryMB=%%f"
    set "TotalMemoryMB=%%g"
    set "MemoryUtilizationPercentage=%%h"
)

:: ------------------------------------------------------------
:: OS DisplayVersion (22H2 / 23H2 / 24H2 / etc.) + Build + UBR
:: ------------------------------------------------------------
for /f "tokens=1-3 delims=|" %%a in ('
    %PS% "$c = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'; $ver = $c.DisplayVersion; if(-not $ver){ $ver = $c.ReleaseId }; $build = $c.CurrentBuild; $ubr = $c.UBR; Write-Output ($ver + '|' + $build + '|' + $ubr)"
') do (
    set "OSRelease=%%a"
    set "OSBuild=%%b"
    set "OSUBR=%%c"
)

:: ------------------------------------------------------------
:: Installed apps count (Win32) + PowerShell version
:: ------------------------------------------------------------
for /f "tokens=1-2 delims=|" %%a in ('
    %PS% "$paths = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'; $raw = foreach ($p in $paths) { Get-ItemProperty -Path $p -ErrorAction SilentlyContinue }; $apps = $raw | Where-Object { $_.DisplayName -and -not ($_.SystemComponent -eq 1) -and $_.ReleaseType -ne 'Update' }; $pkgCount = if ($apps) { $apps.Count } else { 0 }; $psVer = $PSVersionTable.PSVersion.ToString(); Write-Output ($pkgCount.ToString() + '|' + $psVer)"
') do (
    set "PackagesNumber=%%a"
    set "PShellVersion=%%b"
)

:: ------------------------------------------------------------
:: GPU / display information (resolution, refresh rate, GPU name)
:: ------------------------------------------------------------
for /f "tokens=1-3 delims=|" %%a in ('
    %PS% "$gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1; $mode = 'Unknown'; if($gpu){ $width = $gpu.CurrentHorizontalResolution; $height = $gpu.CurrentVerticalResolution; if($width -and $height){ $mode = ('{0} x {1}' -f $width, $height) } elseif($gpu.VideoModeDescription){ $parts = $gpu.VideoModeDescription -split 'x'; if($parts.Length -ge 2){ $w = $parts[0].Trim(); $hRaw = $parts[1].Trim(); $h = ($hRaw -replace '[^\d]',''); if([string]::IsNullOrWhiteSpace($h)){ $mode = $gpu.VideoModeDescription } else { $mode = ('{0} x {1}' -f $w, $h) } } else { $mode = $gpu.VideoModeDescription } } }; $hz = if($gpu -and $gpu.CurrentRefreshRate){$gpu.CurrentRefreshRate}else{0}; $desc = if($gpu -and $gpu.Description){$gpu.Description}else{'Unknown GPU'}; Write-Output ($mode + '|' + $hz + '|' + $desc)"
') do (
    set "DisplayRes=%%a"
    set "DisplayRefreshRate=%%b"
    set "VGAName=%%c"
)

:: Trim possible spaces from refresh rate
set "DisplayRefreshRate=%DisplayRefreshRate: =%"

:: ------------------------------------------------------------
:: Hardware information (model, CPU cores, BIOS)
:: ------------------------------------------------------------
for /f "tokens=1-4 delims=|" %%a in ('
    %PS% "$cs = Get-CimInstance Win32_ComputerSystem; $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1; $bios = Get-CimInstance Win32_BIOS; $model = if($cs.Model){$cs.Model}else{'Unknown'}; $cpuname = if($cpu.Name){$cpu.Name}else{'Unknown CPU'}; $cores = if($cpu.NumberOfCores){$cpu.NumberOfCores}else{1}; $biosver = if($bios.SMBIOSBIOSVersion){$bios.SMBIOSBIOSVersion}else{'Unknown'}; $biosvend = if($bios.Manufacturer){$bios.Manufacturer}else{'Unknown'}; Write-Output ($model + '|' + $cpuname + '|' + $cores + '|' + ($biosver + ' (' + $biosvend + ')'))"
') do (
    set "BaseboardModel=%%a"
    set "CPUName=%%b"
    set "CPUCores=%%c"
    set "BIOSInfo=%%d"
)

:: ------------------------------------------------------------
:: RAM summary (per module) → e.g. "2x Hynix 16GB DDR5-5600 CL22"
::  - with DDR3/4/5/6 + speed-based guessing
:: ------------------------------------------------------------
for /f "tokens=* delims=" %%a in ('
    %PS% "$ram = Get-CimInstance Win32_PhysicalMemory; if(-not $ram){ 'Unknown RAM' } else { $modules = @(); foreach($m in $ram){ $sizeGB = [math]::Round($m.Capacity / 1GB); $vendor = if($m.Manufacturer){ $m.Manufacturer.Trim() } else { 'Unknown' }; $speed = if($m.Speed){ $m.Speed } else { '?' }; $speedNum = 0; if($m.Speed){ $speedNum = [int]$m.Speed }; $typeId = if($m.SMBIOSMemoryType){ $m.SMBIOSMemoryType } else { $m.MemoryType }; $typeMap = @{20='DDR';21='DDR2';24='DDR3';26='DDR4';30='DDR5';34='DDR6'}; $ddr = $typeMap[$typeId]; if(-not $ddr){ if($speedNum -ge 7000){$ddr='DDR6'}elseif($speedNum -ge 4800){$ddr='DDR5'}elseif($speedNum -ge 2133){$ddr='DDR4'}elseif($speedNum -ge 1333){$ddr='DDR3'}else{$ddr='DDR?'} }; $cl=''; if($m.PSObject.Properties['ConfiguredCL'] -and $m.ConfiguredCL){ $cl = ' CL' + $m.ConfiguredCL; }; $modules += ($vendor + ' ' + $sizeGB + 'GB ' + $ddr + '-' + $speed + $cl); }; $group = $modules | Group-Object; if($group.Count -eq 1){ $count = $ram.Count; ($count.ToString() + 'x ' + $group[0].Name) } else { $modules -join ', ' } }"
') do set "MemorySummary=%%a"

:: ------------------------------------------------------------
:: Combined: Total storage (all filesystem drives),
::  - System disk (%SystemDrive%) and Active physical network adapter
:: Variables:
::  - UsedStorageSpaceGB, TotalStorageSpaceGB, UsedStorageSpacePercentage
::  - UsedDiskSpaceStr, TotalDiskSpaceStr, UsedDiskSpacePercentage
::  - ActiveAdapter
:: ------------------------------------------------------------
for /f "tokens=1-7 delims=|" %%a in ('
    %PS% "$drives = Get-PSDrive -PSProvider FileSystem; if(-not $drives){ $used=0; $total=0; $pctStorage=0 } else { $usedBytes = ($drives | Measure-Object -Property Used -Sum).Sum; $freeBytes = ($drives | Measure-Object -Property Free -Sum).Sum; $totalBytes = $usedBytes + $freeBytes; $used = [int]($usedBytes / 1GB); $total = [int]($totalBytes / 1GB); if($totalBytes -le 0){ $pctStorage = 0 } else { $pctStorage = [int](($used * 100) / $total) } }; $sys = $env:SystemDrive.TrimEnd(':'); $d = $drives | Where-Object { $_.Name -eq $sys -and $_.Provider.Name -eq 'FileSystem' }; if(-not $d){ $usedDiskGB=0; $totalDiskGB=0; $pctDisk=0 } else { $usedDiskGB = [math]::Round($d.Used / 1GB, 2); $totalDiskGB = [math]::Round(($d.Used + $d.Free) / 1GB, 2); if(($d.Used + $d.Free) -le 0){ $pctDisk=0 } else { $pctDisk = [int](($d.Used * 100) / ($d.Used + $d.Free)) } }; $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.HardwareInterface -and -not $_.Virtual } | Sort-Object ifIndex | Select-Object -First 1 -ExpandProperty InterfaceDescription; if(-not $adapter){ $adapter = 'Unknown' }; Write-Output ($used.ToString() + '|' + $total.ToString() + '|' + $pctStorage.ToString() + '|' + $usedDiskGB.ToString() + '|' + $totalDiskGB.ToString() + '|' + $pctDisk.ToString() + '|' + $adapter)"
') do (
    set "UsedStorageSpaceGB=%%a"
    set "TotalStorageSpaceGB=%%b"
    set "UsedStorageSpacePercentage=%%c"
    set "UsedDiskSpaceStr=%%d"
    set "TotalDiskSpaceStr=%%e"
    set "UsedDiskSpacePercentage=%%f"
    set "ActiveAdapter=%%g"
)

set "SystemDisk=%SystemDrive%"

:: ============================================================
::  SAFETY DEFAULTS / FALLBACKS
:: ============================================================

:: OS / Version info
if not defined WinOS       set "WinOS=Unknown Windows"
if not defined OSArch      set "OSArch=Unknown Architecture"
if not defined WinVersion  set "WinVersion=0.0.0"
if not defined OSRelease   set "OSRelease=Unknown Release"
if not defined OSBuild     set "OSBuild=0"
if not defined OSUBR       set "OSUBR=0"

:: Uptime
if not defined UpTimeValue set "UpTimeValue=0 minutes"

:: Apps / PowerShell
if not defined PackagesNumber set "PackagesNumber=0"
if not defined PShellVersion  set "PShellVersion=Unknown"

:: Hardware / Model / BIOS / CPU
if not defined BaseboardModel  set "BaseboardModel=Unknown Model"
if not defined BIOSInfo        set "BIOSInfo=Unknown BIOS"
if not defined CPUName         set "CPUName=Unknown CPU"
if not defined CPUCores        set "CPUCores=0"

:: RAM
if not defined UsedMemoryMB                set "UsedMemoryMB=0"
if not defined TotalMemoryMB               set "TotalMemoryMB=0"
if not defined MemoryUtilizationPercentage set "MemoryUtilizationPercentage=0"
if not defined MemorySummary               set "MemorySummary=Unknown RAM"

:: System role
if not defined SystemRole set "SystemRole=Unknown System"

:: Total storage
if not defined UsedStorageSpaceGB         set "UsedStorageSpaceGB=0"
if not defined TotalStorageSpaceGB        set "TotalStorageSpaceGB=0"
if not defined UsedStorageSpacePercentage set "UsedStorageSpacePercentage=0"

:: System disk
if not defined UsedDiskSpaceStr           set "UsedDiskSpaceStr=0"
if not defined TotalDiskSpaceStr          set "TotalDiskSpaceStr=0"
if not defined UsedDiskSpacePercentage    set "UsedDiskSpacePercentage=0"

:: Network
if not defined ActiveAdapter set "ActiveAdapter=Unknown"

cls

:: ============================================================
::  COLOR TEXT ENVIRONMENT / LAYOUT
:: ============================================================

set AT=:CT 0F "@"
set Node=:CT 06 "%computername%"

:: LABEL DEFINITIONS (readable names)
set LabelOS=:CT 06 "   OS"
set LabelBuild=:CT 06 "   Build"
set LabelKernel=:CT 06 "   Kernel"
set LabelUpTime=:CT 06 "   UpTime"
set LabelSystem=:CT 06 "   System"
set LabelApps=:CT 06 "   Apps"
set LabelShell=:CT 06 "   Terminal"
set LabelResolution=:CT 06 "   Resolution"
set LabelBaseboard=:CT 06 "   Baseboard"
set LabelBIOS=:CT 06 "   BIOS"
set LabelCPU=:CT 06 "   CPU"
set LabelGPU=:CT 06 "   GPU"
set LabelMemory=:CT 06 "   Memory"
set LabelMemoryUsage=:CT 06 "   Memory Usage"
set LabelSystemDisk=:CT 06 "   System Partition"
set LabelStorage=:CT 06 "   Storage Space"
set LabelNetwork=:CT 06 "   Network Adapter"

set LL2=:CT 07 "                                       ["
set Logo-End=:CT 07 "]"

:: ASCII image variables – Windows 10
set W10User=:CT 06 "                                        %username%"
set W10-Line1=:CT 03 "                            ....iilll"
set W10-Line2-OS=:CT 03 "                  ....iilllllllllllll"
set W10-Line3-Build=:CT 03 "      ....iillll  lllllllllllllllllll"
set W10-Line4-Kernel=:CT 03 "  iillllllllllll  lllllllllllllllllll"
set W10-Line5=:CT 03 "  llllllllllllll  lllllllllllllllllll"
set W10-Line6-Baseboard=:CT 06 "                                        Baseboard"
set W10-Line7-SystemPartition=:CT 03 "  ``^^llllllll  lllllllllllllllllll"
set W10-Line8-Storage=:CT 03 "        ````^^  ^lllllllllllllllll"
set W10-Line9-Network=:CT 03 "                       ````^^^llll"

:: ASCII image variables – Windows 11
set W11User=:CT 06 "                                       %username%"
set W11-LL1=:CT 03 "  ################  ################   "
set W11-Resolution-Line=:CT 06 "                                       Resolution"
set W11-Network-Line=:CT 06 "                                       Network Adapter"

:: Colorbar blocks (Black Magic via :CT)
set cb-BrightWhite=:CT FF "369"
set cb-LightYellow=:CT EE "369"
set cb-LightPruple=:CT DD "369"
set cb-LightRed=:CT CC "369"
set cb-LightAqua=:CT BB "369"
set cb-LightGreen=:CT AA "369"
set cb-LightBlue=:CT 99 "369"
set cb-Gray=:CT 88 "369"
set cb-White=:CT 77 "369"
set cb-Yellow=:CT 66 "369"
set cb-Purple=:CT 55 "369"
set cb-Red=:CT 44 "369"
set cb-Aqua=:CT 33 "369"
set cb-Green=:CT 22 "369"
set cb-Blue=:CT 11 "369"

:: ============================================================
::  OS SELECTION
:: ============================================================

set "os_name=%WinOS%"

if /i not "%os_name:Windows 10=%"=="%os_name%" (
    goto W10
) else if /i not "%os_name:Server 2019=%"=="%os_name%" (
    goto W10
) else if /i not "%os_name:Windows 11=%"=="%os_name%" (
    goto W11
) else if /i not "%os_name:Server 2022=%"=="%os_name%" (
    goto W11
) else if /i not "%os_name:Server 2025=%"=="%os_name%" (
    goto W11
) else (
    echo Unsupported Windows version
    goto End
)

:: ============================================================
::  CONSOLE OUTPUT – WINDOWS 10 / SERVER 2019
:: ============================================================

:W10
echo.
    call %W10User% & call %AT% & call %Node%
    echo.
    call %W10-Line1% & echo    ----------------------------
    call %W10-Line2-OS% & call %LabelOS% & echo : %WinOS% %OSArch%
    call %W10-Line3-Build% & call %LabelBuild% & echo : %OSRelease% (%OSBuild%.%OSUBR%)
    call %W10-Line4-Kernel% & call %LabelKernel% & echo : %WinVersion%
    call %W10-Line5% & call %LabelUpTime% & echo : %UpTimeValue%
    call %W10-Line5% & call %LabelSystem% & echo : %SystemRole%
    call %W10-Line5% & call %LabelApps% & echo : %PackagesNumber%
    call %W10-Line5% & call %LabelShell% & echo : PowerShell %PShellVersion%
    call %W10-Line5% & call %LabelResolution% & echo : %DisplayRes% @ %DisplayRefreshRate% HZ
    call %W10-Line6-Baseboard% & echo : %BaseboardModel%
    call %W10-Line5% & call %LabelBIOS% & echo : %BIOSInfo%
    call %W10-Line5% & call %LabelCPU% & echo : %CPUName% Cores %CPUCores%
    call %W10-Line5% & call %LabelGPU% & echo : %VGAName%
    call %W10-Line5% & call %LabelMemory% & echo : %MemorySummary%
    call %W10-Line5% & call %LabelMemoryUsage% & echo : %UsedMemoryMB% MB / %TotalMemoryMB% MB (%MemoryUtilizationPercentage%%% in use)

    set /a FreeDiskPct=100-%UsedDiskSpacePercentage%
    call %W10-Line7-SystemPartition% & call %LabelSystemDisk% & echo : %SystemDisk%\  %UsedDiskSpaceStr% GB / %TotalDiskSpaceStr% GB (%FreeDiskPct%%% free)
    call %W10-Line8-Storage% & call %LabelStorage% & echo : %UsedStorageSpaceGB% GB / %TotalStorageSpaceGB% GB (%UsedStorageSpacePercentage%%% in use)
    call %W10-Line9-Network% & call %LabelNetwork% & echo : %ActiveAdapter%
    echo.
    goto Colorbar

:: ============================================================
::  CONSOLE OUTPUT – WINDOWS 11 / SERVER 2022-2025
:: ============================================================

:W11
    echo.
    call %W11User% & call %AT% & call %Node%
    echo.
    call %W11-LL1% & echo    ----------------------------
    call %W11-LL1% & call %LabelOS% & echo : %WinOS% %OSArch%
    call %W11-LL1% & call %LabelBuild% & echo : %OSRelease% (%OSBuild%.%OSUBR%)
    call %W11-LL1% & call %LabelKernel% & echo : %WinVersion%
    call %W11-LL1% & call %LabelUpTime% & echo : %UpTimeValue%
    call %W11-LL1% & call %LabelSystem% & echo : %SystemRole%
    call %W11-LL1% & call %LabelApps% & echo : %PackagesNumber%
    call %W11-LL1% & call %LabelShell% & echo : PowerShell %PShellVersion%
    call %W11-Resolution-Line% & echo : %DisplayRes% @ %DisplayRefreshRate% HZ
    call %W11-LL1% & call %LabelBaseboard% & echo : %BaseboardModel%
    call %W11-LL1% & call %LabelBIOS% & echo : %BIOSInfo%
    call %W11-LL1% & call %LabelCPU% & echo : %CPUName% Cores %CPUCores%
    call %W11-LL1% & call %LabelGPU% & echo : %VGAName%
    call %W11-LL1% & call %LabelMemory% & echo : %MemorySummary%
    call %W11-LL1% & call %LabelMemoryUsage% & echo : %UsedMemoryMB% MB / %TotalMemoryMB% MB (%MemoryUtilizationPercentage%%% in use)

    set /a FreeDiskPct=100-%UsedDiskSpacePercentage%
    call %W11-LL1% & call %LabelSystemDisk% & echo : %SystemDisk%\  %UsedDiskSpaceStr% GB / %TotalDiskSpaceStr% GB (%FreeDiskPct%%% free)
    call %W11-LL1% & call %LabelStorage% & echo : %UsedStorageSpaceGB% GB / %TotalStorageSpaceGB% GB (%UsedStorageSpacePercentage%%% in use)
    call %W11-Network-Line% & echo : %ActiveAdapter%
    echo.

:Colorbar
    call %LL2% & call %cb-White% & call %cb-Red% & call %cb-Green% & call %cb-Yellow% & call %cb-Blue% & call %cb-Purple% & call %cb-Aqua% & call %cb-BrightWhite% & call %Logo-End%
    echo.
    call %LL2% & call %cb-Gray% & call %cb-LightRed% & call %cb-LightGreen% & call %cb-LightYellow% & call %cb-LightBlue% & call %cb-LightPruple% & call %cb-LightAqua% & echo    ]
    echo.
    echo.
    echo.
        cmd /k 
        echo.

:: ============================================================
::  COLOR TEXT HELPER (:CT)
::  - "Black Magic" inline color via FINDSTR + temp file
:: ============================================================
:CT
echo off
<nul set /p ".=%del%" > "%~2"
findstr /v /a:%1 /R "^$" "%~2" nul
del "%~2" > nul 2>&1

:End
endlocal
exit /b 0

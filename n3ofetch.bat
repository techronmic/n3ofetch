:: =========================================================================================================
::  n3ofetch – Windows System Information Display
:: ---------------------------------------------------------------------------------------------------------
::  Version:      1.0.3
::  Author:       techronmic
::  Contact:      techronmic@gmail.com
::  GitHub        https://github.com/techronmic/n3ofetch
::  Created:      2022-03-16
::  Update:       2025-12-20
::  License:      MIT License
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
::      • Enhanced error handling with try-catch blocks
::      • String sanitization to prevent batch injection
::
::  Support / Donation:
::      PayPal: https://www.paypal.com/donate/?hosted_button_id=U4MVM7GJ5XMDY
::
:: =========================================================================================================

@echo off
setlocal EnableDelayedExpansion

:: ============================================================
::  CMD WINDOW SIZE AUTO-ADJUSTMENT
:: ============================================================
::  Automatically adjusts console window size to fit content
::  Windows 10 logo: 21 lines + colorbar/info = ~85 columns x 30 rows
::  Windows 11 logo: 18 lines + colorbar/info = ~85 columns x 27 rows
:: ============================================================
mode con: cols=120 lines=30

:: ============================================================
::  ENVIRONMENT VALIDATION
:: ============================================================
::  Ensures system meets minimum requirements:
::   - PowerShell must be installed
::   - PowerShell version must be 5.0 or higher
:: ============================================================

:: Check if PowerShell executable is available in PATH
where powershell >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR] PowerShell was not found on this system.
    echo         n3ofetch requires Windows PowerShell 5.0 or later.
    echo.
    goto End
)

:: Query PowerShell version and validate (minimum: 5.0)
:: Uses $PSVersionTable.PSVersion to get major and minor version numbers
for /f "tokens=1,2" %%a in ('
    powershell -NoLogo -NoProfile -Command "$v=$PSVersionTable.PSVersion; Write-Output ($v.Major.ToString() + ' ' + $v.Minor.ToString())"
') do (
    set "PSMaj=%%a"
    set "PSMin=%%b"
)

:: Set defaults if version detection failed
if not defined PSMaj set "PSMaj=0"
if not defined PSMin set "PSMin=0"

:: Validate minimum version requirement (5.0+)
if %PSMaj% LSS 5 (
    echo.
    echo [ERROR] PowerShell version %PSMaj%.%PSMin% detected.
    echo         n3ofetch requires at least PowerShell 5.0.
    echo.
    goto End
)

:: ============================================================
::  GLOBAL CONFIGURATION
:: ============================================================

:: PowerShell command prefix (used throughout script)
set "PS=powershell -NoLogo -NoProfile -Command"

:: Configure terminal appearance
title n3ofetch v1.0.3
color 07

:: Generate backspace character for color output helper function
:: This creates a DEL character used by the :CT color text function
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "del=%%a")

cls

:: ============================================================
::  SYSTEM INFORMATION GATHERING
:: ============================================================
::  The following sections query Windows Management Instrumentation (WMI)
::  via PowerShell to gather comprehensive system information.
::  All queries use CIM cmdlets for better performance and compatibility.
:: ============================================================

:: ------------------------------------------------------------
:: Query 1: OS Information, System Role, Uptime, Memory Usage
:: ------------------------------------------------------------
::  Retrieves from WMI classes:
::   - Win32_OperatingSystem: OS name, version, memory stats, boot time
::   - Win32_ComputerSystem: Model, manufacturer, hypervisor detection
::
::  System Role Detection Logic:
::   1. Check if OS contains "Server" → Server
::   2. Check Model/Family/SKU for "Notebook" → Notebook
::   3. Check Model/Family/SKU for "Workstation" → Workstation
::   4. Default → Client
::   5. VM Detection based on Model/Manufacturer strings (NOT HypervisorPresent flag)
::
::  VM Indicators checked (all roles):
::   VirtualBox, VMware, KVM, Virtual Machine, Hyper-V Virtual, QEMU, Parallels, Xen, Proxmox, bochs, bhyve
::   Note: "Hyper-V Virtual" (not just "Hyper-V") to avoid false positives on physical hosts
:: ------------------------------------------------------------
for /f "tokens=1-8 delims=|" %%a in ('
    %PS% "$os = Get-CimInstance Win32_OperatingSystem; $cs = Get-CimInstance Win32_ComputerSystem; $caption = $os.Caption -replace '[&<>|]',''; $arch = $os.OSArchitecture -replace '[&<>|]',''; $ver = $os.Version -replace '[&<>|]',''; $texts = @(); if ($cs.Model) { $texts += ($cs.Model -replace '[&<>|]','') }; if ($cs.SystemFamily) { $texts += ($cs.SystemFamily -replace '[&<>|]','') }; if ($cs.SystemSKUNumber) { $texts += ($cs.SystemSKUNumber -replace '[&<>|]','') }; $blob = ($texts -join ' '); $role = 'Client'; if ($caption -like '*Server*') { $role = 'Server' } elseif ($caption -match '(?i)\b(Pro|Home)\b') { $role = 'Client' } else { $role = 'Client' }; if ($role -ne 'Server') { if ($blob -match '(?i)Notebook') { $role = 'Notebook' } elseif ($blob -match '(?i)Workstation') { $role = 'Workstation' } }; $isVM = $false; $vmIndicators = @('VirtualBox','VMware','KVM','Virtual Machine','Hyper-V Virtual','HVM domU','QEMU','Parallels','Xen','Proxmox','bochs','bhyve'); $model = $cs.Model; $manu = $cs.Manufacturer; foreach ($v in $vmIndicators) { if (($model -like ('*' + $v + '*')) -or ($manu -like ('*' + $v + '*'))) { $isVM = $true; break } }; if ($isVM) { $role = $role + ' (Virtual Machine)' }; $u = (Get-Date) - $os.LastBootUpTime; $totalKB = [int]$os.TotalVisibleMemorySize; $freeKB = [int]$os.FreePhysicalMemory; if($totalKB -le 0){ $usedMB = 0; $totalMB = 0; $pct = 0 } else { $totalMB = [int]($totalKB / 1024); $usedMB = [int](($totalKB - $freeKB) / 1024); $pct = [int]( (($totalKB - $freeKB) * 100) / $totalKB ); }; $up = '{0} days, {1} hours, {2} minutes' -f $u.Days, $u.Hours, $u.Minutes; Write-Output ($caption + '|' + $arch + '|' + $ver + '|' + $role + '|' + $up + '|' + $usedMB.ToString() + '|' + $totalMB.ToString() + '|' + $pct.ToString())"
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
:: Query 2: OS Build Details
:: ------------------------------------------------------------
::  Retrieves from Registry:
::   - HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion
::
::  Values retrieved:
::   - DisplayVersion: Feature update version (e.g., "23H2", "24H2")
::   - ReleaseId: Fallback for older Windows versions
::   - CurrentBuild: Build number (e.g., "22631")
::   - UBR: Update Build Revision (minor build number)
:: ------------------------------------------------------------
for /f "tokens=1-3 delims=|" %%a in ('
    %PS% "try { $c = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop; $ver = $c.DisplayVersion; if(-not $ver){ $ver = $c.ReleaseId }; $build = $c.CurrentBuild; $ubr = $c.UBR; Write-Output ($ver + '|' + $build + '|' + $ubr) } catch { Write-Output 'Unknown|0|0' }"
') do (
    set "OSRelease=%%a"
    set "OSBuild=%%b"
    set "OSUBR=%%c"
)

:: ------------------------------------------------------------
:: Query 3: Installed Applications Count
:: ------------------------------------------------------------
::  Scans registry uninstall keys to count installed applications:
::   - HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall (64-bit apps)
::   - HKLM:\Software\WOW6432Node\...\Uninstall (32-bit apps on 64-bit OS)
::   - HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall (user apps)
::
::  Filters out:
::   - System components (SystemComponent=1)
::   - Windows updates (ReleaseType='Update')
::   - Entries without DisplayName
:: ------------------------------------------------------------
for /f "tokens=1-2 delims=|" %%a in ('
    %PS% "try { $paths = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'; $raw = foreach ($p in $paths) { Get-ItemProperty -Path $p -ErrorAction SilentlyContinue }; $apps = $raw | Where-Object { $_.DisplayName -and -not ($_.SystemComponent -eq 1) -and $_.ReleaseType -ne 'Update' }; $pkgCount = if ($apps) { $apps.Count } else { 0 }; $psVer = $PSVersionTable.PSVersion.ToString(); Write-Output ($pkgCount.ToString() + '|' + $psVer) } catch { Write-Output '0|Unknown' }"
') do (
    set "PackagesNumber=%%a"
    set "PShellVersion=%%b"
)

:: ------------------------------------------------------------
:: Query 4: GPU and Display Information
:: ------------------------------------------------------------
::  Retrieves from WMI class: Win32_VideoController
::
::  Resolution detection methods (in order of preference):
::   1. CurrentHorizontalResolution x CurrentVerticalResolution
::   2. Parse VideoModeDescription (fallback for some drivers)
::
::  Sanitizes GPU description to prevent batch command injection
:: ------------------------------------------------------------
for /f "tokens=1-3 delims=|" %%a in ('
    %PS% "try { $gpu = Get-CimInstance Win32_VideoController -ErrorAction Stop | Select-Object -First 1; $mode = 'Unknown'; if($gpu){ $width = $gpu.CurrentHorizontalResolution; $height = $gpu.CurrentVerticalResolution; if($width -and $height){ $mode = ('{0} x {1}' -f $width, $height) } elseif($gpu.VideoModeDescription){ $parts = $gpu.VideoModeDescription -split 'x'; if($parts.Length -ge 2){ $w = $parts[0].Trim(); $hRaw = $parts[1].Trim(); $h = ($hRaw -replace '[^\d]',''); if([string]::IsNullOrWhiteSpace($h)){ $mode = $gpu.VideoModeDescription } else { $mode = ('{0} x {1}' -f $w, $h) } } else { $mode = $gpu.VideoModeDescription } } }; $hz = if($gpu -and $gpu.CurrentRefreshRate){$gpu.CurrentRefreshRate}else{0}; $desc = if($gpu -and $gpu.Description){($gpu.Description -replace '[&<>|]','')}else{'Unknown GPU'}; Write-Output ($mode + '|' + $hz + '|' + $desc) } catch { Write-Output 'Unknown|0|Unknown GPU' }"
') do (
    set "DisplayRes=%%a"
    set "DisplayRefreshRate=%%b"
    set "VGAName=%%c"
)

:: Remove any stray spaces from refresh rate value
set "DisplayRefreshRate=%DisplayRefreshRate: =%"

:: Validate refresh rate (set to Unknown if 0)
if "%DisplayRefreshRate%"=="0" set "DisplayRefreshRate=Unknown"

:: ------------------------------------------------------------
:: Query 5: Hardware Details (Baseboard, CPU, BIOS)
:: ------------------------------------------------------------
::  Retrieves from WMI classes:
::   - Win32_ComputerSystem: System model
::   - Win32_Processor: CPU name and core count
::   - Win32_BIOS: BIOS version and manufacturer
::
::  All string values are sanitized to prevent batch injection
:: ------------------------------------------------------------
for /f "tokens=1-4 delims=|" %%a in ('
    %PS% "try { $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop; $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1; $bios = Get-CimInstance Win32_BIOS -ErrorAction Stop; $model = if($cs.Model){($cs.Model -replace '[&<>|]','')}else{'Unknown'}; $cpuname = if($cpu.Name){($cpu.Name -replace '[&<>|]','')}else{'Unknown CPU'}; $cores = if($cpu.NumberOfCores){$cpu.NumberOfCores}else{1}; $biosver = if($bios.SMBIOSBIOSVersion){($bios.SMBIOSBIOSVersion -replace '[&<>|]','')}else{'Unknown'}; $biosvend = if($bios.Manufacturer){($bios.Manufacturer -replace '[&<>|]','')}else{'Unknown'}; Write-Output ($model + '|' + $cpuname + '|' + $cores + '|' + ($biosver + ' (' + $biosvend + ')')) } catch { Write-Output 'Unknown|Unknown CPU|0|Unknown BIOS' }"
') do (
    set "BaseboardModel=%%a"
    set "CPUName=%%b"
    set "CPUCores=%%c"
    set "BIOSInfo=%%d"
)

:: ------------------------------------------------------------
:: Query 6: RAM Module Details
:: ------------------------------------------------------------
::  Retrieves from WMI class: Win32_PhysicalMemory
::
::  For each RAM module, gathers:
::   - Manufacturer (sanitized)
::   - Capacity in GB
::   - Memory type (DDR generation)
::   - Speed in MHz
::   - CAS Latency (if available)
::
::  DDR Type Detection:
::   Primary method: SMBIOSMemoryType or MemoryType property
::    - Type 20 = DDR
::    - Type 21 = DDR2
::    - Type 24 = DDR3
::    - Type 26 = DDR4
::    - Type 30 = DDR5
::    - Type 34 = DDR6
::
::   Fallback method (speed-based):
::    - >= 7000 MHz = DDR6
::    - >= 4800 MHz = DDR5
::    - >= 2133 MHz = DDR4
::    - >= 1333 MHz = DDR3
::
::  Output format examples:
::   - "4 x Corsair 8GB DDR4-2133" (identical modules)
::   - "2 x Kingston 16GB DDR4-3200, Samsung 8GB DDR4-2666" (mixed)
:: ------------------------------------------------------------
for /f "tokens=* delims=" %%a in ('
    %PS% "try { $ram = Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop; if(-not $ram){ 'Unknown RAM' } else { $modules = @(); foreach($m in $ram){ $sizeGB = [math]::Round($m.Capacity / 1GB); $vendor = if($m.Manufacturer){ ($m.Manufacturer.Trim() -replace '[&<>|]','') } else { 'Unknown' }; $speed = if($m.Speed){ $m.Speed } else { '?' }; $speedNum = 0; if($m.Speed){ $speedNum = [int]$m.Speed }; $typeId = if($m.SMBIOSMemoryType){ $m.SMBIOSMemoryType } else { $m.MemoryType }; $typeMap = @{20='DDR';21='DDR2';24='DDR3';26='DDR4';30='DDR5';34='DDR6'}; $ddr = $typeMap[$typeId]; if(-not $ddr){ if($speedNum -ge 7000){$ddr='DDR6'}elseif($speedNum -ge 4800){$ddr='DDR5'}elseif($speedNum -ge 2133){$ddr='DDR4'}elseif($speedNum -ge 1333){$ddr='DDR3'}else{$ddr='DDR?'} }; $modules += ($vendor + ' ' + $sizeGB + 'GB ' + $ddr + '-' + $speed); }; $group = $modules | Group-Object; if($group.Count -eq 1){ $count = $ram.Count; if($count -eq 1){ $group[0].Name } else { ($count.ToString() + ' x ' + $group[0].Name) } } else { $results = @(); foreach($g in ($group | Sort-Object Count -Descending)){ if($g.Count -eq 1){ $results += $g.Name } else { $results += ($g.Count.ToString() + ' x ' + $g.Name) } }; $results -join ', ' } } } catch { 'Unknown RAM' }"
') do set "MemorySummary=%%a"

:: ------------------------------------------------------------
:: Query 7: Storage and Network Information
:: ------------------------------------------------------------
::  Storage calculation:
::   - Uses Get-PSDrive with FileSystem provider
::   - Includes ALL mounted drives (local + mapped network)
::   - Calculates total used/free space across all drives
::   - Separately tracks system drive (typically C:)
::
::  Network adapter selection:
::   - Filters for: Status=Up, HardwareInterface=true, Virtual=false
::   - Excludes virtual adapters: Hyper-V, Docker, vEthernet, Loopback, Teredo, ISATAP
::   - Priority order:
::      1. Ethernet (802.3 media type) - highest priority
::      2. Wireless adapters
::      3. Other physical adapters
::   - Returns InterfaceDescription of first matching adapter
:: ------------------------------------------------------------
for /f "tokens=1-7 delims=|" %%a in ('
    %PS% "$drives = Get-PSDrive -PSProvider FileSystem; if(-not $drives){ $used=0; $total=0; $pctStorage=0 } else { $usedBytes = ($drives | Measure-Object -Property Used -Sum).Sum; $freeBytes = ($drives | Measure-Object -Property Free -Sum).Sum; $totalBytes = $usedBytes + $freeBytes; $used = [int]($usedBytes / 1GB); $total = [int]($totalBytes / 1GB); if($totalBytes -le 0){ $pctStorage = 0 } else { $pctStorage = [int](($used * 100) / $total) } }; $sys = $env:SystemDrive.TrimEnd(':'); $d = $drives | Where-Object { $_.Name -eq $sys -and $_.Provider.Name -eq 'FileSystem' }; if(-not $d){ $usedDiskGB=0; $totalDiskGB=0; $pctDisk=0 } else { $usedDiskGB = [math]::Round($d.Used / 1GB, 2); $totalDiskGB = [math]::Round(($d.Used + $d.Free) / 1GB, 2); if(($d.Used + $d.Free) -le 0){ $pctDisk=0 } else { $pctDisk = [int](($d.Used * 100) / ($d.Used + $d.Free)) } }; $adapter = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' -and $_.HardwareInterface -and -not $_.Virtual -and $_.InterfaceDescription -notmatch '(Hyper-V|Docker|vEthernet|Loopback|Teredo|isatap)' } | Sort-Object { if($_.MediaType -eq '802.3'){0} elseif($_.MediaType -match 'Wireless'){1} else {2} },ifIndex | Select-Object -First 1 -ExpandProperty InterfaceDescription; if(-not $adapter){ $adapter = 'Unknown' } else { $adapter = $adapter -replace '[&<>|]','' }; Write-Output ($used.ToString() + '|' + $total.ToString() + '|' + $pctStorage.ToString() + '|' + $usedDiskGB.ToString() + '|' + $totalDiskGB.ToString() + '|' + $pctDisk.ToString() + '|' + $adapter)"
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
::  SAFETY DEFAULTS AND FALLBACK VALUES
:: ============================================================
::  If any WMI query fails or returns empty values, these
::  fallback values ensure the script doesn't crash and
::  displays "Unknown" instead of blank fields.
:: ============================================================

:: Operating System information
if not defined WinOS       set "WinOS=Unknown Windows"
if not defined OSArch      set "OSArch=Unknown Architecture"
if not defined WinVersion  set "WinVersion=0.0.0"
if not defined OSRelease   set "OSRelease=Unknown Release"
if not defined OSBuild     set "OSBuild=0"
if not defined OSUBR       set "OSUBR=0"

:: System and application information
if not defined UpTimeValue set "UpTimeValue=0 minutes"
if not defined SystemRole set "SystemRole=Unknown System"
if not defined PackagesNumber set "PackagesNumber=0"
if not defined PShellVersion  set "PShellVersion=Unknown"

:: Hardware information
if not defined BaseboardModel  set "BaseboardModel=Unknown Model"
if not defined BIOSInfo        set "BIOSInfo=Unknown BIOS"
if not defined CPUName         set "CPUName=Unknown CPU"
if not defined CPUCores        set "CPUCores=0"

:: Memory information
if not defined UsedMemoryMB                set "UsedMemoryMB=0"
if not defined TotalMemoryMB               set "TotalMemoryMB=0"
if not defined MemoryUtilizationPercentage set "MemoryUtilizationPercentage=0"
if not defined MemorySummary               set "MemorySummary=Unknown RAM"

:: Storage information
if not defined UsedStorageSpaceGB         set "UsedStorageSpaceGB=0"
if not defined TotalStorageSpaceGB        set "TotalStorageSpaceGB=0"
if not defined UsedStorageSpacePercentage set "UsedStorageSpacePercentage=0"
if not defined UsedDiskSpaceStr           set "UsedDiskSpaceStr=0"
if not defined TotalDiskSpaceStr          set "TotalDiskSpaceStr=0"
if not defined UsedDiskSpacePercentage    set "UsedDiskSpacePercentage=0"

:: Network information
if not defined ActiveAdapter set "ActiveAdapter=Unknown"

cls

:: ============================================================
::  DISPLAY CONFIGURATION
:: ============================================================
::  Variable definitions for colored output and ASCII art
::  Uses the :CT (Color Text) helper function for inline colors
:: ============================================================

:: Header symbols
set "AtSymbol=:CT 0F "@""
set "ComputerNode=:CT 06 "%computername%""

:: Information labels (cyan color)
set "LabelOS=:CT 06 "   OS""
set "LabelBuild=:CT 06 "   Build""
set "LabelKernel=:CT 06 "   Kernel""
set "LabelUpTime=:CT 06 "   UpTime""
set "LabelSystem=:CT 06 "   System""
set "LabelApps=:CT 06 "   Apps""
set "LabelShell=:CT 06 "   Terminal""
set "LabelResolution=:CT 06 "   Resolution""
set "LabelBaseboard=:CT 06 "   Baseboard""
set "LabelBIOS=:CT 06 "   BIOS""
set "LabelCPU=:CT 06 "   CPU""
set "LabelGPU=:CT 06 "   GPU""
set "LabelMemory=:CT 06 "   Memory""
set "LabelMemoryUsage=:CT 06 "   Memory Usage""
set "LabelSystemDisk=:CT 06 "   System Partition""
set "LabelStorage=:CT 06 "   Storage Space""
set "LabelNetwork=:CT 06 "   Network Adapter""

:: Colorbar frame
set "LL2=:CT 07 "                                       [""
set "Logo-End=:CT 07 "]""

:: ------------------------------------------------------------
:: ASCII Art: Windows 10 Logo (cyan gradient effect)
:: ------------------------------------------------------------
set "W10_User=:CT 06 "                                        %username%""
set "W10_L1=:CT 03 "                            ....iilll""
set "W10_L2=:CT 03 "                  ....iilllllllllllll""
set "W10_L3=:CT 03 "      ....iillll  lllllllllllllllllll""
set "W10_L4=:CT 03 "  iillllllllllll  lllllllllllllllllll""
set "W10_L5=:CT 03 "  llllllllllllll  lllllllllllllllllll""
set "W10_L6=:CT 03 "  ``^^llllllll  lllllllllllllllllll""
set "W10_L7=:CT 03 "        ````^^  ^lllllllllllllllll""
set "W10_L8=:CT 03 "                       ````^^^llll""
set "W10_Baseboard=:CT 06 "                                        Baseboard""

:: ------------------------------------------------------------
:: ASCII Art: Windows 11 Logo (square block design)
:: ------------------------------------------------------------
set "W11_User=:CT 06 "                                       %username%""
set "W11_Line=:CT 03 "  ################  ################   ""
set "W11_Resolution=:CT 06 "                                       Resolution""
set "W11_Network=:CT 06 "                                       Network Adapter""

:: ------------------------------------------------------------
:: Colorbar: 8-bit color palette blocks
:: ------------------------------------------------------------
:: Bright/High-intensity colors (top row)
set "CB_BrightWhite=:CT FF "369""
set "CB_BrightYellow=:CT EE "369""
set "CB_BrightPurple=:CT DD "369""
set "CB_BrightRed=:CT CC "369""
set "CB_BrightAqua=:CT BB "369""
set "CB_BrightGreen=:CT AA "369""
set "CB_BrightBlue=:CT 99 "369""

:: Normal/Standard colors (bottom row)
set "CB_Gray=:CT 88 "369""
set "CB_White=:CT 77 "369""
set "CB_Yellow=:CT 66 "369""
set "CB_Purple=:CT 55 "369""
set "CB_Red=:CT 44 "369""
set "CB_Aqua=:CT 33 "369""
set "CB_Green=:CT 22 "369""
set "CB_Blue=:CT 11 "369""

:: ============================================================
::  OS VERSION DETECTION AND LAYOUT SELECTION
:: ============================================================
::  Determines which ASCII logo to display based on Windows version:
::   - Windows 10 / Server 2019 → :W10 (gradient logo)
::   - Windows 11 / Server 2022 / Server 2025 → :W11 (block logo)
:: ============================================================

set "os_name=%WinOS%"

:: Check for Windows 10 or Server 2019
if /i not "%os_name:Windows 10=%"=="%os_name%" (
    goto W10
) else if /i not "%os_name:Server 2019=%"=="%os_name%" (
    goto W10
)

:: Check for Windows 11 or Server 2022/2025
if /i not "%os_name:Windows 11=%"=="%os_name%" (
    goto W11
) else if /i not "%os_name:Server 2022=%"=="%os_name%" (
    goto W11
) else if /i not "%os_name:Server 2025=%"=="%os_name%" (
    goto W11
)

:: Unsupported Windows version
echo Unsupported Windows version
goto End

:: ============================================================
::  OUTPUT RENDERING – WINDOWS 10 / SERVER 2019
:: ============================================================
::  Displays system information with Windows 10 ASCII logo
:: ============================================================

:W10
echo.
    :: Header: username@computername
    call %W10_User% & call %AtSymbol% & call %ComputerNode%
    echo.

    :: System information section
    call %W10_L1% & echo    ----------------------------
    call %W10_L2% & call %LabelOS% & echo : %WinOS% %OSArch%
    call %W10_L3% & call %LabelBuild% & echo : %OSRelease% (%OSBuild%.%OSUBR%)
    call %W10_L4% & call %LabelKernel% & echo : %WinVersion%
    call %W10_L5% & call %LabelUpTime% & echo : %UpTimeValue%
    call %W10_L5% & call %LabelSystem% & echo : %SystemRole%
    call %W10_L5% & call %LabelApps% & echo : %PackagesNumber%
    call %W10_L5% & call %LabelShell% & echo : PowerShell %PShellVersion%
    call %W10_L5% & call %LabelResolution% & echo : %DisplayRes% @ %DisplayRefreshRate% Hz

    :: Hardware information section
    call %W10_Baseboard% & echo : %BaseboardModel%
    call %W10_L5% & call %LabelBIOS% & echo : %BIOSInfo%
    call %W10_L5% & call %LabelCPU% & echo : %CPUName% (%CPUCores% Cores)
    call %W10_L5% & call %LabelGPU% & echo : %VGAName%
    call %W10_L5% & call %LabelMemory% & echo : %MemorySummary%
    call %W10_L5% & call %LabelMemoryUsage% & echo : %UsedMemoryMB% MB / %TotalMemoryMB% MB (%MemoryUtilizationPercentage%%% in use)

    :: Storage and network section
    set /a FreeDiskPct=100-%UsedDiskSpacePercentage%
    call %W10_L6% & call %LabelSystemDisk% & echo : %SystemDisk%\  %UsedDiskSpaceStr% GB / %TotalDiskSpaceStr% GB (%FreeDiskPct%%% free)
    call %W10_L7% & call %LabelStorage% & echo : %UsedStorageSpaceGB% GB / %TotalStorageSpaceGB% GB (%UsedStorageSpacePercentage%%% in use)
    call %W10_L8% & call %LabelNetwork% & echo : %ActiveAdapter%
    echo.
    goto Colorbar

:: ============================================================
::  OUTPUT RENDERING – WINDOWS 11 / SERVER 2022-2025
:: ============================================================
::  Displays system information with Windows 11 ASCII logo
:: ============================================================

:W11
    echo.
    :: Header: username@computername
    call %W11_User% & call %AtSymbol% & call %ComputerNode%
    echo.

    :: System information section
    call %W11_Line% & echo    ----------------------------
    call %W11_Line% & call %LabelOS% & echo : %WinOS% %OSArch%
    call %W11_Line% & call %LabelBuild% & echo : %OSRelease% (%OSBuild%.%OSUBR%)
    call %W11_Line% & call %LabelKernel% & echo : %WinVersion%
    call %W11_Line% & call %LabelUpTime% & echo : %UpTimeValue%
    call %W11_Line% & call %LabelSystem% & echo : %SystemRole%
    call %W11_Line% & call %LabelApps% & echo : %PackagesNumber%
    call %W11_Line% & call %LabelShell% & echo : PowerShell %PShellVersion%
    call %W11_Resolution% & echo : %DisplayRes% @ %DisplayRefreshRate% Hz

    :: Hardware information section
    call %W11_Line% & call %LabelBaseboard% & echo : %BaseboardModel%
    call %W11_Line% & call %LabelBIOS% & echo : %BIOSInfo%
    call %W11_Line% & call %LabelCPU% & echo : %CPUName% (%CPUCores% Cores)
    call %W11_Line% & call %LabelGPU% & echo : %VGAName%
    call %W11_Line% & call %LabelMemory% & echo : %MemorySummary%
    call %W11_Line% & call %LabelMemoryUsage% & echo : %UsedMemoryMB% MB / %TotalMemoryMB% MB (%MemoryUtilizationPercentage%%% in use)

    :: Storage and network section
    set /a FreeDiskPct=100-%UsedDiskSpacePercentage%
    call %W11_Line% & call %LabelSystemDisk% & echo : %SystemDisk%\  %UsedDiskSpaceStr% GB / %TotalDiskSpaceStr% GB (%FreeDiskPct%%% free)
    call %W11_Line% & call %LabelStorage% & echo : %UsedStorageSpaceGB% GB / %TotalStorageSpaceGB% GB (%UsedStorageSpacePercentage%%% in use)
    call %W11_Network% & echo : %ActiveAdapter%
    echo.

:: ============================================================
::  COLORBAR DISPLAY
:: ============================================================
::  Renders two rows of colored blocks (8-bit color palette)
:: ============================================================

:Colorbar
    :: Top row: Normal/Standard colors
    call %LL2% & call %CB_Blue% & call %CB_Green% & call %CB_Aqua% & call %CB_Red% & call %CB_Purple% & call %CB_Yellow% & call %CB_White% & call %CB_Gray% & call %Logo-End%
    echo.

    :: Bottom row: Bright/High-intensity colors
    call %LL2% & call %CB_BrightBlue% & call %CB_BrightGreen% & call %CB_BrightAqua% & call %CB_BrightRed% & call %CB_BrightPurple% & call %CB_BrightYellow% & call %CB_BrightWhite% & echo    ]
    echo.
    echo.

    :: Wait for user keypress before exit
    pause >nul
    goto End

:: ============================================================
::  HELPER FUNCTION: COLOR TEXT (:CT)
:: ============================================================
::  Displays colored text inline using FINDSTR technique
::
::  Parameters:
::   %1 = Color code (2-digit hex: foreground+background)
::   %2 = Text to display
::
::  Mechanism:
::   - Creates temporary file with backspace character
::   - Uses FINDSTR with /a flag to apply colors
::   - Deletes temporary file
::
::  Example: call :CT 0A "Hello" (green text on black)
:: ============================================================

:CT
echo off
<nul set /p ".=%del%" > "%~2"
findstr /v /a:%1 /R "^$" "%~2" nul
del "%~2" > nul 2>&1
goto :eof

:: ============================================================
::  CLEANUP AND EXIT
:: ============================================================

:End
echo.
endlocal
exit /b 0

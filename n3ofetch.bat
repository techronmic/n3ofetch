:: =========================================================================================================
::  n3ofetch – Windows System Information Display
:: ---------------------------------------------------------------------------------------------------------
::  Version:      1.0.5
::  Author:       techronmic
::  Contact:      techronmic@gmail.com
::  GitHub        https://github.com/techronmic/n3ofetch
::  Created:      2022-03-16
::  Update:       2026-03-29
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
::  CMD WINDOW SIZE
:: ============================================================
mode con: cols=120 lines=30

:: ============================================================
::  ENVIRONMENT VALIDATION
:: ============================================================

where powershell >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR] PowerShell was not found on this system.
    echo         n3ofetch requires Windows PowerShell 5.0 or later.
    echo.
    goto End
)

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

:: ============================================================
::  GLOBAL CONFIGURATION
:: ============================================================

set "VERSION=1.0.5"
set "PS=powershell -NoLogo -NoProfile -Command"

title n3ofetch v!VERSION!
color 07

:: ANSI escape character + color definitions
for /f "tokens=2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%a"
set "C_CY=!ESC![36m"
set "C_YE=!ESC![33m"
set "C_W=!ESC![97m"
set "C_WH=!ESC![37m"
set "C_0=!ESC![0m"

set "CB_1=!ESC![34;44m"
set "CB_2=!ESC![32;42m"
set "CB_3=!ESC![36;46m"
set "CB_4=!ESC![31;41m"
set "CB_5=!ESC![35;45m"
set "CB_6=!ESC![33;43m"
set "CB_7=!ESC![37;47m"
set "CB_8=!ESC![90;100m"
set "CB_9=!ESC![94;104m"
set "CB_A=!ESC![92;102m"
set "CB_B=!ESC![96;106m"
set "CB_C=!ESC![91;101m"
set "CB_D=!ESC![95;105m"
set "CB_E=!ESC![93;103m"
set "CB_0=!ESC![30;40m"
set "CB_F=!ESC![97;107m"

cls

:: ============================================================
::  SYSTEM INFORMATION GATHERING (single PowerShell call)
:: ============================================================
::  KEY=VALUE output, parsed by for /f.
::  Sanitization: hex escapes remove & < > | ^ % !
:: ============================================================

for /f "tokens=1,* delims==" %%a in ('
    %PS% "$s='[\x26\x3C\x3E\x7C\x5E\x25\x21]'; $os=Get-CimInstance Win32_OperatingSystem; $cs=Get-CimInstance Win32_ComputerSystem; $caption=$os.Caption -replace $s,''; $arch=$os.OSArchitecture -replace $s,''; $ver=$os.Version -replace $s,''; $texts=@(); if($cs.Model){$texts+=($cs.Model -replace $s,'')}; if($cs.SystemFamily){$texts+=($cs.SystemFamily -replace $s,'')}; if($cs.SystemSKUNumber){$texts+=($cs.SystemSKUNumber -replace $s,'')}; $blob=($texts -join ' '); $role='Client'; if($caption -like '*Server*'){$role='Server'}; if($role -ne 'Server'){if($blob -match '(?i)Notebook'){$role='Notebook'} elseif($blob -match '(?i)Workstation'){$role='Workstation'}}; $isVM=$false; $vmI=@('VirtualBox','VMware','KVM','Virtual Machine','Hyper-V Virtual','HVM domU','QEMU','Parallels','Xen','Proxmox','bochs','bhyve'); foreach($v in $vmI){if(($cs.Model -like ('*'+$v+'*')) -or ($cs.Manufacturer -like ('*'+$v+'*'))){$isVM=$true;break}}; if($isVM){$role=$role+' (Virtual Machine)'}; $u=(Get-Date)-$os.LastBootUpTime; $up='{0} days, {1} hours, {2} minutes' -f $u.Days,$u.Hours,$u.Minutes; $totalKB=[int]$os.TotalVisibleMemorySize; $freeKB=[int]$os.FreePhysicalMemory; if($totalKB -le 0){$usedMB=0;$totalMB=0;$pct=0} else{$totalMB=[int]($totalKB/1024);$usedMB=[int](($totalKB-$freeKB)/1024);$pct=[int]((($totalKB-$freeKB)*100)/$totalKB)}; Write-Output ('WinOS='+$caption); Write-Output ('OSArch='+$arch); Write-Output ('WinVersion='+$ver); Write-Output ('SystemRole='+$role); Write-Output ('UpTimeValue='+$up); Write-Output ('UsedMemoryMB='+$usedMB); Write-Output ('TotalMemoryMB='+$totalMB); Write-Output ('MemoryUtilizationPercentage='+$pct); try{$c=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop; $dv=$c.DisplayVersion; if(-not $dv){$dv=$c.ReleaseId}; Write-Output ('OSRelease='+$dv); Write-Output ('OSBuild='+$c.CurrentBuild); Write-Output ('OSUBR='+$c.UBR)} catch{Write-Output 'OSRelease=Unknown'; Write-Output 'OSBuild=0'; Write-Output 'OSUBR=0'}; try{$paths='HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'; $raw=foreach($p in $paths){Get-ItemProperty -Path $p -ErrorAction SilentlyContinue}; $apps=$raw | Where-Object {$_.DisplayName -and -not ($_.SystemComponent -eq 1) -and $_.ReleaseType -ne 'Update'}; $pkgCount=if($apps){$apps.Count}else{0}; Write-Output ('PackagesNumber='+$pkgCount)} catch{Write-Output 'PackagesNumber=0'}; Write-Output ('PShellVersion='+$PSVersionTable.PSVersion.ToString()); try{$gpu=Get-CimInstance Win32_VideoController -ErrorAction Stop | Select-Object -First 1; $mode='Unknown'; if($gpu){$width=$gpu.CurrentHorizontalResolution;$height=$gpu.CurrentVerticalResolution; if($width -and $height){$mode=('{0} x {1}' -f $width,$height)} elseif($gpu.VideoModeDescription){$parts=$gpu.VideoModeDescription -split 'x'; if($parts.Length -ge 2){$w=$parts[0].Trim();$hRaw=$parts[1].Trim();$h=($hRaw -replace '[^\d]',''); if([string]::IsNullOrWhiteSpace($h)){$mode=$gpu.VideoModeDescription} else{$mode=('{0} x {1}' -f $w,$h)}} else{$mode=$gpu.VideoModeDescription}}}; $hz=if($gpu -and $gpu.CurrentRefreshRate){$gpu.CurrentRefreshRate}else{0}; $desc=if($gpu -and $gpu.Description){($gpu.Description -replace $s,'')}else{'Unknown GPU'}; Write-Output ('DisplayRes='+$mode); Write-Output ('DisplayRefreshRate='+$hz); Write-Output ('VGAName='+$desc)} catch{Write-Output 'DisplayRes=Unknown'; Write-Output 'DisplayRefreshRate=0'; Write-Output 'VGAName=Unknown GPU'}; try{$cpu=Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1; $bios=Get-CimInstance Win32_BIOS -ErrorAction Stop; $model2=if($cs.Model){($cs.Model -replace $s,'')}else{'Unknown'}; $cpuname=if($cpu.Name){($cpu.Name -replace $s,'')}else{'Unknown CPU'}; $cores=if($cpu.NumberOfCores){$cpu.NumberOfCores}else{1}; $biosver=if($bios.SMBIOSBIOSVersion){($bios.SMBIOSBIOSVersion -replace $s,'')}else{'Unknown'}; $biosvend=if($bios.Manufacturer){($bios.Manufacturer -replace $s,'')}else{'Unknown'}; Write-Output ('BaseboardModel='+$model2); Write-Output ('CPUName='+$cpuname); Write-Output ('CPUCores='+$cores); Write-Output ('BIOSInfo='+$biosver+' ('+$biosvend+')')} catch{Write-Output 'BaseboardModel=Unknown'; Write-Output 'CPUName=Unknown CPU'; Write-Output 'CPUCores=0'; Write-Output 'BIOSInfo=Unknown BIOS'}; try{$ram=Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop; if(-not $ram){Write-Output 'MemorySummary=Unknown RAM'} else{$modules=@(); foreach($m in $ram){$sizeGB=[math]::Round($m.Capacity/1GB); $vendor=if($m.Manufacturer){($m.Manufacturer.Trim() -replace $s,'')}else{'Unknown'}; $speed=if($m.Speed){$m.Speed}else{'?'}; $speedNum=0; if($m.Speed){$speedNum=[int]$m.Speed}; $typeId=if($m.SMBIOSMemoryType){$m.SMBIOSMemoryType}else{$m.MemoryType}; $typeMap=@{20='DDR';21='DDR2';24='DDR3';26='DDR4';30='DDR5';34='DDR6'}; $ddr=$typeMap[$typeId]; if(-not $ddr){if($speedNum -ge 7000){$ddr='DDR6'}elseif($speedNum -ge 4800){$ddr='DDR5'}elseif($speedNum -ge 2133){$ddr='DDR4'}elseif($speedNum -ge 1333){$ddr='DDR3'}else{$ddr='DDR?'}}; $modules+=($vendor+' '+$sizeGB+'GB '+$ddr+'-'+$speed)}; $group=$modules | Group-Object; if($group.Count -eq 1){$count=$ram.Count; if($count -eq 1){$summary=$group[0].Name}else{$summary=($count.ToString()+' x '+$group[0].Name)}} else{$results=@(); foreach($g in ($group | Sort-Object Count -Descending)){if($g.Count -eq 1){$results+=$g.Name}else{$results+=($g.Count.ToString()+' x '+$g.Name)}}; $summary=$results -join ', '}; Write-Output ('MemorySummary='+$summary)}} catch{Write-Output 'MemorySummary=Unknown RAM'}; $drives=Get-PSDrive -PSProvider FileSystem; if(-not $drives){$used=0;$total=0;$pctStorage=0} else{$usedBytes=($drives | Measure-Object -Property Used -Sum).Sum; $freeBytes=($drives | Measure-Object -Property Free -Sum).Sum; $totalBytes=$usedBytes+$freeBytes; $used=[int]($usedBytes/1GB); $total=[int]($totalBytes/1GB); if($totalBytes -le 0){$pctStorage=0}else{$pctStorage=[int](($used*100)/$total)}}; $sys=$env:SystemDrive.TrimEnd(':'); $d=$drives | Where-Object {$_.Name -eq $sys -and $_.Provider.Name -eq 'FileSystem'}; if(-not $d){$usedDiskGB=0;$totalDiskGB=0;$pctDisk=0} else{$usedDiskGB=[math]::Round($d.Used/1GB,2); $totalDiskGB=[math]::Round(($d.Used+$d.Free)/1GB,2); if(($d.Used+$d.Free) -le 0){$pctDisk=0}else{$pctDisk=[int](($d.Used*100)/($d.Used+$d.Free))}}; $adapter=Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq 'Up' -and $_.HardwareInterface -and -not $_.Virtual -and $_.InterfaceDescription -notmatch '(Hyper-V|Docker|vEthernet|Loopback|Teredo|isatap)'} | Sort-Object {if($_.MediaType -eq '802.3'){0}elseif($_.MediaType -match 'Wireless'){1}else{2}},ifIndex | Select-Object -First 1 -ExpandProperty InterfaceDescription; if(-not $adapter){$adapter='Unknown'}else{$adapter=$adapter -replace $s,''}; Write-Output ('UsedStorageSpaceGB='+$used); Write-Output ('TotalStorageSpaceGB='+$total); Write-Output ('UsedStorageSpacePercentage='+$pctStorage); Write-Output ('UsedDiskSpaceStr='+$usedDiskGB); Write-Output ('TotalDiskSpaceStr='+$totalDiskGB); Write-Output ('UsedDiskSpacePercentage='+$pctDisk); Write-Output ('ActiveAdapter='+$adapter)"
') do (
    if not "%%b"=="" set "%%a=%%b"
)

set "DisplayRefreshRate=%DisplayRefreshRate: =%"
if "%DisplayRefreshRate%"=="0" set "DisplayRefreshRate=Unknown"
set "SystemDisk=%SystemDrive%"

:: ============================================================
::  FALLBACK VALUES
:: ============================================================

if not defined WinOS       set "WinOS=Unknown Windows"
if not defined OSArch      set "OSArch=Unknown Architecture"
if not defined WinVersion  set "WinVersion=0.0.0"
if not defined OSRelease   set "OSRelease=Unknown Release"
if not defined OSBuild     set "OSBuild=0"
if not defined OSUBR       set "OSUBR=0"

if not defined UpTimeValue set "UpTimeValue=0 minutes"
if not defined SystemRole set "SystemRole=Unknown System"
if not defined PackagesNumber set "PackagesNumber=0"
if not defined PShellVersion  set "PShellVersion=Unknown"

if not defined BaseboardModel  set "BaseboardModel=Unknown Model"
if not defined BIOSInfo        set "BIOSInfo=Unknown BIOS"
if not defined CPUName         set "CPUName=Unknown CPU"
if not defined CPUCores        set "CPUCores=0"

if not defined UsedMemoryMB                set "UsedMemoryMB=0"
if not defined TotalMemoryMB               set "TotalMemoryMB=0"
if not defined MemoryUtilizationPercentage set "MemoryUtilizationPercentage=0"
if not defined MemorySummary               set "MemorySummary=Unknown RAM"

if not defined UsedStorageSpaceGB         set "UsedStorageSpaceGB=0"
if not defined TotalStorageSpaceGB        set "TotalStorageSpaceGB=0"
if not defined UsedStorageSpacePercentage set "UsedStorageSpacePercentage=0"
if not defined UsedDiskSpaceStr           set "UsedDiskSpaceStr=0"
if not defined TotalDiskSpaceStr          set "TotalDiskSpaceStr=0"
if not defined UsedDiskSpacePercentage    set "UsedDiskSpacePercentage=0"

if not defined DisplayRes          set "DisplayRes=Unknown"
if not defined DisplayRefreshRate  set "DisplayRefreshRate=Unknown"
if not defined VGAName             set "VGAName=Unknown GPU"
if not defined ActiveAdapter       set "ActiveAdapter=Unknown"

cls

:: ============================================================
::  DISPLAY CONFIGURATION
:: ============================================================

set "W10_L1=!C_CY!                            ....iill"
set "W10_L2=!C_CY!                  ....iillllllllllll"
set "W10_L3=!C_CY!      ....iillll  llllllllllllllllll"
set "W10_L4=!C_CY!  iillllllllllll  llllllllllllllllll"
set "W10_L5=!C_CY!  llllllllllllll  llllllllllllllllll"
set "W10_L6=!C_CY!     ``^^llllllll  llllllllllllllllll"
set "W10_L7=!C_CY!           ````^^  ^llllllllllllllllll"
set "W10_L8=!C_CY!                            ````^^^lll"

set "W11_L=!C_CY!  ################  ################   "

:: ============================================================
::  OS VERSION DETECTION
:: ============================================================

set "os_name=%WinOS%"
if /i not "%os_name:Windows 10=%"=="%os_name%" (
    goto W10
) else if /i not "%os_name:Server 2019=%"=="%os_name%" (
    goto W10
)

if /i not "%os_name:Windows 11=%"=="%os_name%" (
    goto W11
) else if /i not "%os_name:Server 2022=%"=="%os_name%" (
    goto W11
) else if /i not "%os_name:Server 2025=%"=="%os_name%" (
    goto W11
)

echo Unsupported Windows version
goto End

:: ============================================================
::  OUTPUT – WINDOWS 10 / SERVER 2019
:: ============================================================

:W10
    echo.
    echo !C_YE!                                       %username%!C_W!@!C_YE!%computername%!C_0!
    echo.
    echo !W10_L1!!C_0!   ----------------------------
    echo !W10_L2!!C_YE!   OS!C_0!: %WinOS% %OSArch%
    echo !W10_L3!!C_YE!   Build!C_0!: %OSRelease% (%OSBuild%.%OSUBR%)
    echo !W10_L4!!C_YE!   Kernel!C_0!: %WinVersion%
    echo !W10_L5!!C_YE!   UpTime!C_0!: %UpTimeValue%
    echo !W10_L5!!C_YE!   System!C_0!: %SystemRole%
    echo !W10_L5!!C_YE!   Apps!C_0!: %PackagesNumber%
    echo !W10_L5!!C_YE!   Terminal!C_0!: PowerShell %PShellVersion%
    echo !W10_L5!!C_YE!   Resolution!C_0!: %DisplayRes% @ %DisplayRefreshRate% Hz
    echo !C_YE!                                       Baseboard!C_0!: %BaseboardModel%
    echo !W10_L5!!C_YE!   BIOS!C_0!: %BIOSInfo%
    echo !W10_L5!!C_YE!   CPU!C_0!: %CPUName% (%CPUCores% Cores)
    echo !W10_L5!!C_YE!   GPU!C_0!: %VGAName%
    echo !W10_L5!!C_YE!   Memory!C_0!: %MemorySummary%
    echo !W10_L5!!C_YE!   Memory Usage!C_0!: %UsedMemoryMB% MB / %TotalMemoryMB% MB (%MemoryUtilizationPercentage%%% in use)
    set /a FreeDiskPct=100-%UsedDiskSpacePercentage%
    echo !W10_L6!!C_YE!   System Partition!C_0!: %SystemDisk%\  %UsedDiskSpaceStr% GB / %TotalDiskSpaceStr% GB (!FreeDiskPct!%%% free)
    echo !W10_L7!!C_YE!   Storage Space!C_0!: %UsedStorageSpaceGB% GB / %TotalStorageSpaceGB% GB (%UsedStorageSpacePercentage%%% in use)
    echo !W10_L8!!C_YE!   Network Adapter!C_0!: %ActiveAdapter%
    echo.
    goto Colorbar

:: ============================================================
::  OUTPUT – WINDOWS 11 / SERVER 2022-2025
:: ============================================================

:W11
    echo.
    echo !C_YE!                                       %username%!C_W!@!C_YE!%computername%!C_0!
    echo.
    echo !W11_L!!C_0!----------------------------
    echo !W11_L!!C_YE!OS!C_0!: %WinOS% %OSArch%
    echo !W11_L!!C_YE!Build!C_0!: %OSRelease% (%OSBuild%.%OSUBR%)
    echo !W11_L!!C_YE!Kernel!C_0!: %WinVersion%
    echo !W11_L!!C_YE!UpTime!C_0!: %UpTimeValue%
    echo !W11_L!!C_YE!System!C_0!: %SystemRole%
    echo !W11_L!!C_YE!Apps!C_0!: %PackagesNumber%
    echo !W11_L!!C_YE!Terminal!C_0!: PowerShell %PShellVersion%
    echo !C_YE!                                       Resolution!C_0!: %DisplayRes% @ %DisplayRefreshRate% Hz
    echo !W11_L!!C_YE!Baseboard!C_0!: %BaseboardModel%
    echo !W11_L!!C_YE!BIOS!C_0!: %BIOSInfo%
    echo !W11_L!!C_YE!CPU!C_0!: %CPUName% (%CPUCores% Cores)
    echo !W11_L!!C_YE!GPU!C_0!: %VGAName%
    echo !W11_L!!C_YE!Memory!C_0!: %MemorySummary%
    echo !W11_L!!C_YE!Memory Usage!C_0!: %UsedMemoryMB% MB / %TotalMemoryMB% MB (%MemoryUtilizationPercentage%%% in use)
    set /a FreeDiskPct=100-%UsedDiskSpacePercentage%
    echo !W11_L!!C_YE!System Partition!C_0!: %SystemDisk%\  %UsedDiskSpaceStr% GB / %TotalDiskSpaceStr% GB (!FreeDiskPct!%%% free)
    echo !W11_L!!C_YE!Storage Space!C_0!: %UsedStorageSpaceGB% GB / %TotalStorageSpaceGB% GB (%UsedStorageSpacePercentage%%% in use)
    echo !C_YE!                                       Network Adapter!C_0!: %ActiveAdapter%
    echo.

:: ============================================================
::  COLORBAR
:: ============================================================

:Colorbar
    echo !C_WH!                                       !CB_8!   !CB_2!   !CB_3!   !CB_4!   !CB_5!   !CB_6!   !CB_F!   !CB_1!   !C_WH!!C_0!
    echo !C_WH!                                       !CB_7!   !CB_A!   !CB_B!   !CB_C!   !CB_D!   !CB_E!   !CB_0!   !CB_9!   !C_WH!!C_0!
    echo.
    echo.

:: ============================================================
::  EXIT
:: ============================================================

:End
endlocal
cmd /k

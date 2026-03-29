# Changelog

## [1.0.5] - 2026-03-29
### Improved
- Performance: 7 PowerShell processes consolidated into 1 (significantly faster startup)
- Deduplicated Win32_ComputerSystem WMI query (was queried twice)
- Input sanitization upgraded to hex escapes covering & < > | ^ % !
- VERSION variable defined once, referenced globally
- Comments streamlined: section headers kept, verbose descriptions removed
- Added missing fallback values for DisplayRes, DisplayRefreshRate, VGAName
- Colorbar black block uses CB_0 variable instead of inline ANSI code
- Redundant role detection logic simplified

## [1.0.4] - 2026-03-29
### Changed
- Color system replaced: FINDSTR :CT technique replaced with ANSI escape codes
- Eliminates temporary file creation in current directory for color output
- Faster rendering: single echo per line instead of multiple call/findstr cycles
- Improved compatibility with read-only and network paths (no CWD file writes)

## [1.0.3] - 2025-12-20
### Improved
- RAM module grouping optimized: Identical modules are grouped (e.g. "4 x Kingston 16GB DDR4-2133")
- CMD window size adjustment: Automatic adjustment 
  
## [1.0.2] - 2025-12-16
### Improved
- VM detection improved
- Client, Workstation and Server detection improved

## [1.0.1] - 2025-12-02
### Added
- Improved system type detection for Client, Workstation, Notebook, Server, Virtual Machine
- Documentation for system detection and developer guide

### Improved
- Optimized system information queries for faster execution
- Refactored Batch logic for readability and maintainability

### Fixed
- Quoting and syntax issues in CMD
- Minor edge cases in OS detection

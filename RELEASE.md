# n3ofetch v1.0.3 – Windows System Information Script

n3ofetch is a lightweight Batch-based Windows alternative to the well-known Linux tool *neofetch*.
It prints a concise, colored overview of your system directly in the Command Prompt.

## What's New in v1.0.3

### System Detection Improvements
- RAM module grouping optimized: Identical modules are grouped (e.g. "4 x Kingston 16GB DDR4-2133")
- CMD window size adjustment: Automatic adjustment 

## What's New in v1.0.2

### System Detection Improvements
- More accurate detection of:
  - Client systems
  - Notebooks / laptops
  - Workstations
  - Servers
  - Virtual machines

## What's New in v1.0.1

### Performance
- Optimized built-in commands and WMI calls for faster execution
- Reduced redundant environment variables and control flow

### Stability & Cleanup
- Fixed quoting and dash-parsing issues that could cause syntax errors
- Cleaned up formatting and output layout

For full history, see `CHANGELOG.md`.

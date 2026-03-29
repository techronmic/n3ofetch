# n3ofetch User Documentation

This guide explains how to install and use **n3ofetch**, a Windows alternative to the Linux tool *neofetch*.

## Installation

1. Download `n3ofetch.bat` from the GitHub Releases page.
2. Place it in a folder, e.g. `C:\Tools\n3ofetch\`.
3. (Optional) Add that folder to the `PATH` environment variable.

## Usage

Open a Command Prompt and run:

```cmd
n3ofetch.bat
```

You will see a formatted summary of your system including user, host, OS, system type, CPU, and memory.

## Performance

n3ofetch gathers all system information in a single PowerShell call, minimizing process startup overhead. WMI objects are queried once and reused across multiple fields.

## Color Output

n3ofetch uses ANSI escape codes for colored output. This requires Windows 10 version 1607 or later.
If colors do not display correctly, ensure your terminal supports ANSI escape sequences (CMD, PowerShell, Windows Terminal).

For troubleshooting tips and integration ideas, see the main README.

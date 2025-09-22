# WinCrashTrace

**WinCrashTrace** is a PowerShell utility that generates a **Windows Support Bundle** designed for root cause analysis of operating system crashes.  
It collects system information, crash events, hardware errors, driver versions, installed updates, and crash dump metadata into a single compressed archive.  

The resulting ZIP file can be attached directly to a vendor support case (e.g. Dell, Microsoft).

---

## Features

- Collects:
  - System information (hardware, BIOS, OS build, uptime)  
  - Crash events (Kernel-Power 41, BugCheck 1001, Unexpected Shutdown 6008)  
  - Hardware error events (WHEA, HAL, TPM)  
  - Crash dump metadata (minidumps and MEMORY.DMP)  
  - Driver inventory  
  - Installed hotfixes and updates  

- Generates:
  - **SupportReport.txt** – consolidated human‑readable report with auto‑generated summary and raw logs  
  - **CrashEvents.csv** – structured export of crash‑related events  
  - **CrashDumps.csv** – dump file metadata  
  - **Drivers.csv** – driver list  
  - **Hotfixes.csv** – applied updates  

- Includes an auto‑generated **RCA summary section** with:
  - Crash count, first/last crash timestamp, and observation span  
  - Presence of hardware/WHEA errors  
  - Crash dump availability  
  - BIOS age check vs. current date  

- Creates a single ZIP bundle in the user’s **Downloads** folder.

---

## Usage

1. Download or clone the repository containing `WinCrashTrace.ps1`.  
2. Open PowerShell with Administrator rights.  
3. Run the script:

```powershell
.\WinCrashTrace.ps1
```

4. Upon completion, a ZIP support bundle will be created in:

```
C:\Users\<username>\Downloads\WinCrashTrace-Bundle-YYYYMMDD-HHMMSS.zip
```

5. Attach the generated ZIP file to your vendor support case.

---

## Quick Run (One‑Liner)

You can execute **WinCrashTrace** directly from GitHub without downloading the repository first.  
In an **Administrator PowerShell** window, run:

```powershell
irm https://raw.githubusercontent.com/Paul1404/WinCrashTrace/refs/heads/main/WinCrashTrace.ps1 | iex
```

This will download the latest script, run it immediately, and generate the support bundle in your `Downloads` folder.

Example output:

```
C:\Users\<username>\Downloads\WinCrashTrace-Bundle-20250922-2330.zip
```

### Safer Option: Download & Inspect First

For production or audited environments, save and inspect the script before running:

```powershell
irm https://raw.githubusercontent.com/Paul1404/WinCrashTrace/refs/heads/main/WinCrashTrace.ps1 -OutFile .\WinCrashTrace.ps1
.\WinCrashTrace.ps1
```

---

## Example Bundle Contents

```
WinCrashTrace-Bundle-20250922-2330.zip
 ├── SupportReport.txt     # Human-readable report with summary + raw logs
 ├── CrashEvents.csv       # Crash event history
 ├── CrashDumps.csv        # Dump file metadata
 ├── Drivers.csv           # Installed driver inventory
 └── Hotfixes.csv          # Installed updates
```

---

## System Requirements

- Windows 10 or Windows 11  
- PowerShell 5.1 or later (default on Windows 10/11)  
- Administrator privileges (for crash dump access and full log retrieval)  

---

## Design Goals

- Single command execution, no parameters needed  
- Focused on vendor support diagnostics (“sosreport”‑like for Windows)  
- Human‑readable + machine‑readable outputs  
- No external dependencies; works with built‑in PowerShell cmdlets  

---

## License

MIT License. See LICENSE for more details.

\# WinCrashTrace



\*\*WinCrashTrace\*\* is a PowerShell utility that generates a \*\*Windows Support Bundle\*\* designed for root cause analysis of operating system crashes.  

It collects system information, crash events, hardware errors, driver versions, installed updates, and crash dump metadata into a single compressed archive.  



The resulting ZIP file can be attached directly to a vendor support case (e.g. Dell, Microsoft).



---



\## Quick Run (One‑Liner)



You can run \*\*WinCrashTrace\*\* directly from GitHub without downloading the repository.  

Open an \*\*Administrator PowerShell\*\* window and execute:



```powershell

irm https://raw.githubusercontent.com/Paul1404/WinCrashTrace/refs/heads/main/WinCrashTrace.ps1 | iex

```



This will:



\- Download the latest `WinCrashTrace.ps1` from the main branch.  

\- Immediately execute it in your session.  

\- Generate a support bundle ZIP in your `Downloads` folder.  



Example output location:



```

C:\\Users\\<username>\\Downloads\\WinCrashTrace-Bundle-20250922-2330.zip

```



> \*\*Note:\*\* For production or audited environments, you may prefer to download and inspect the script first:



```powershell

irm https://raw.githubusercontent.com/Paul1404/WinCrashTrace/refs/heads/main/WinCrashTrace.ps1 -OutFile .\\WinCrashTrace.ps1

.\\WinCrashTrace.ps1

```



---



\## Features



\- Collects:

&nbsp; - System information (hardware, BIOS, OS build, uptime)  

&nbsp; - Crash events (Kernel-Power 41, BugCheck 1001, Unexpected Shutdown 6008)  

&nbsp; - Hardware error events (WHEA, HAL, TPM)  

&nbsp; - Crash dump metadata (minidumps and MEMORY.DMP)  

&nbsp; - Driver inventory  

&nbsp; - Installed hotfixes and updates  



\- Generates:

&nbsp; - \*\*SupportReport.txt\*\* – consolidated human‑readable report with summary and raw logs  

&nbsp; - \*\*CrashEvents.csv\*\* – structured export of crash‑related events  

&nbsp; - \*\*CrashDumps.csv\*\* – dump file metadata  

&nbsp; - \*\*Drivers.csv\*\* – driver list  

&nbsp; - \*\*Hotfixes.csv\*\* – installed updates  



\- Includes an automatically generated summary section:

&nbsp; - Total crash count  

&nbsp; - First and last crash timestamps  

&nbsp; - Time span covered by events  

&nbsp; - WHEA/hardware error presence  

&nbsp; - BIOS age advisory  

&nbsp; - Presence or absence of crash dumps  



\- Creates a single ZIP bundle in the user’s \*\*Downloads\*\* folder.



---



\## Usage



1\. Download or clone the repository containing `WinCrashTrace.ps1`.

2\. Open PowerShell with Administrator rights.  

&nbsp;  (Recommended: support logs and dump access often require elevation.)

3\. Run:



```powershell

.\\WinCrashTrace.ps1

```



4\. Upon completion, a ZIP bundle will be created in:



```

C:\\Users\\<username>\\Downloads\\WinCrashTrace-Bundle-YYYYMMDD-HHMMSS.zip

```



5\. Attach the generated ZIP file to your support case.



---



\## Example Bundle Contents



```

WinCrashTrace-Bundle-20250922-2330.zip

&nbsp;├── SupportReport.txt     # Human-readable summary report

&nbsp;├── CrashEvents.csv       # Crash event log

&nbsp;├── CrashDumps.csv        # Dump file metadata

&nbsp;├── Drivers.csv           # Installed driver inventory

&nbsp;└── Hotfixes.csv          # Installed updates

```



---



\## Design Goals



\- Single command, no parameters required.  

\- All relevant diagnostics grouped in one archive.  

\- Vendor support–ready output, with both human‑readable and structured formats.  

\- Minimal dependencies (uses built‑in PowerShell cmdlets only).



---



\## Requirements



\- Windows 10 or Windows 11.  

\- PowerShell 5.1 or later (included by default).  

\- Administrator privileges for full access to system logs and dumps.



---



\## License



MIT License. See LICENSE file for details.



# Bash Network Diagnostics Toolkit

A lightweight, native, and robust network diagnostics utility written entirely in Bash. This tool tests network health across multiple layers (ICMP, DNS, TCP) and generates timestamped, color-stripped incident reports.

## Why I Built This

Most network troubleshooting tools I found either required installing extra 
dependencies or hid what they were actually doing under layers of abstraction. 
I wanted something I could drop onto any Linux box — no pip installs, no 
Python runtime, nothing beyond what's already on the system — and get a clear, 
layered picture of network health: is the link up, is DNS resolving, are the 
right ports open, what does the kernel's socket table look like. Building the 
TCP scanner on Bash's `/dev/tcp` pseudo-device instead of reaching for `nc` or 
`nmap` was a deliberate constraint — it forced the tool to stay dependency-free 
and portable by design, not by accident.


## Features

- **Reachability Checks (ICMP):** Pings core public DNS servers and local gateways to check basic outgoing packet connectivity.
- **DNS Resolution Layer:** Translates hostnames using `dig` and records precise lookup latency in milliseconds.
- **TCP Port Scanner:** Uses Bash's built-in `/dev/tcp` pseudo-device to scan connection states (OPEN, CLOSED, FILTERED) without external dependencies.
- **Local Socket Statistics:** Queries the kernel via `ss` to analyze socket counts (ESTAB, LISTEN, TIME-WAIT) and list active listening ports.
- **Dual-Output Reporting:** Generates timestamped logs with system metadata (kernel, hostname, uptime), automatically stripping ANSI color codes via `sed` to keep files clean.

## How to Run

Ensure the script is executable:
```bash
chmod +x netcheck.sh
```

### Run All Diagnostics
```bash
./netcheck.sh
```

### Run Specific Diagnostic Modes
- **Ping only:** `./netcheck.sh ping`
- **DNS only:** `./netcheck.sh dns`
- **Port Scan only:** `./netcheck.sh ports`
- **Connection Summary only:** `./netcheck.sh connections`

### Generate a Diagnostic Report
```bash
./netcheck.sh --report
```
This prints colorized results to the terminal while saving a clean, plain-text log file named `netcheck-YYYY-MM-DD-HHMMSS.log` in your directory.

## Outcome

The toolkit runs cleanly on a bare-minimum Linux install with no extra 
packages, and the timestamped reports give a reusable audit trail instead of 
scrollback you lose the moment you close the terminal. It's become my default 
first-response tool whenever I need a fast read on whether a connectivity 
issue is local, DNS-related, or a blocked port.

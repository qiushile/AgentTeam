---
name: conditional-cron-alerts
description: Pattern for setting up cron jobs that only notify the user when specific conditions are met, using a marker file to prevent constant "task completed" messages.
category: devops
---

## Problem
Hermes cron jobs automatically deliver the agent's final response to the user. Even if a monitoring script runs silently, the agent tends to add "Task completed", "Cronjob Response:", or summary text, causing notification spam for frequent checks (e.g., every 3 minutes).

## Solution: Marker File Pattern
Instead of relying on the script's stdout or the agent's discretion, use a persistent marker file to explicitly control when a message should be delivered.

### Setup Steps
1. Create the monitoring script that writes to a marker file (e.g., `notify_pending.txt`) ONLY when a notification-worthy event occurs. Otherwise, it exits silently.
2. In the cron job prompt, instruct the agent to:
   a. Run the monitoring script.
   b. Check if the marker file exists and is non-empty.
   c. If it has content: print the content exactly, then clear the file.
   d. If empty/missing: exit without printing anything.
   e. Explicitly forbid adding any extra text, prefixes, or summaries.

### Cron Job Prompt Template
```text
1. Run: python3 your_monitor_script.py
2. Check file: ~/.your_project/notify_pending.txt
3. If the file exists and is non-empty:
   - Print the exact file contents (no prefixes, no suffixes, no explanations)
   - Clear the file (write empty string)
   - End immediately
4. If the file is missing or empty:
   - Do NOT output anything
   - End immediately

Important: Do NOT add "Cronjob Response", "Task complete", or any other text. Only output if the marker file has content.
```

### Key Details
- Set `deliver: 'origin'` in the cron job so it delivers to the current chat when it actually prints something.
- The script should write the notification message to the marker file. The cron agent reads it, prints it, and the print triggers the delivery mechanism.
- This pattern guarantees zero spam for routine checks, and reliable alerts for critical state changes.
- Always test the script manually first, then manually create the marker file and trigger a cron `run` to verify the agent correctly outputs only the file content.

### Example: Clash Node Monitor
In the Clash Verge node monitor (`clash_monitor.py`):
- Script checks proxy latency every 3 minutes (cron interval).
- Internally skips actual checks if 17 minutes haven't passed (normal mode).
- On timeout → tests backup nodes.
- If all backups fail → enters emergency mode, writes `notify_pending.txt` with alert message.
- Cron job reads the file, prints the alert, clears it.
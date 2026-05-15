---
name: "desktop-notify"
description: "Sends a Windows desktop balloon notification to the user. MUST invoke when ALL tasks are completed and user needs to be alerted."
---

# Desktop Notify

Sends a balloon tip notification via Windows system tray to alert the user that tasks are complete.

## When to Invoke

**CRITICAL: Invoke this skill IMMEDIATELY when:**
- ALL tasks in the todo list are marked as completed
- You have finished answering the user's request and there's nothing left to do
- You are about to give your final response to the user

## How It Works

Runs the PowerShell script at `.trae/notify.ps1` which:
1. Creates a NotifyIcon in the system tray
2. Shows a balloon tip with title "Trae Notification" and message "Task completed! Check the results."
3. The balloon disappears automatically after 5 seconds

## Instructions

1. Run the following command using the CommandExecutor tool (set blocking=true):

```
powershell -ExecutionPolicy Bypass -File ".trae\notify.ps1"
```

2. Send the notification BEFORE your final text response to the user

## Requirements

- `.trae/notify.ps1` must exist in the project root
- Windows OS with PowerShell

## Note

The notification script uses only English text to avoid character encoding issues.

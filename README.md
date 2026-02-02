#### Switch between different in game locations easily and track your progress attempting routes by marking your last try as successful/failed.

## Setup

### Requirements
- Windows
- AutoHotkey v2
  https://www.autohotkey.com/
- Deadlock running in Windowed Fullscreen

---
### Download
- Click Code → Download ZIP on GitHub, or clone the repository
- Extract it somewhere simple, for example: `C:\Games\deadlock-movement-tracker\`

---

### Configure Deadlock path and hotkeys
1. Open `user_settings.ini` (located in the repository root).
2. Set the Deadlock install path if different that the default below:
```
    [deadlock]
    root=C:\Program Files (x86)\Steam\steamapps\common\Deadlock
 ```

3. Optional (recommended):
Create a copy of `user_settings.ini` named `user_settings.local.ini` for personal
overrides: You can keep the defaults saved this way. The `.local.` file takes priority

---

### Enable console logging (required)
The tracker reads positions from Deadlock’s `console.log`.

In Steam:
1. Right-click Deadlock → Properties
2. Open Launch Options
3. Add: `-condebug`

---

### First run
- Double-click `deadlock-movement-tracker.ahk` in the repository root.

On first run the tracker will:
- Install or update `mvtrack.ps1` in your Deadlock folder
- Install or update `mvtrack.cfg` and `mvtrack_pos.cfg` in `game\citadel\cfg`
- Prompt to add required lines to `autoexec.cfg` (needed for the tracker to work)

Accept the prompt unless you already manage these lines manually.

---

### Using the tracker (default hotkeys)
You can change these in `user_settings.ini`.

- F4 — Save current position as a new route start
- F3 — Switch to an existing route start
- F1 — Mark failed attempt and reset to start
- F2 — Mark successful attempt and reset to start
- F5 — Undo last success/fail entry
- F9 — Close the tracker

---

### Troubleshooting
If positions are not saved or restored correctly:

- Verify Deadlock launch options include `-condebug`
- Ensure you accepted the `autoexec.cfg` modification
  (or manually added `sv_cheats 1` and `exec mvtrack.cfg`)
- Check that the `root=` path in `user_settings.ini` is correct
- Enable debug logging and send the contents in: `src\logs\debug.log`

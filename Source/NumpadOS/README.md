# NumpadOS

NumpadOS turns your numeric keypad into a 16-key launcher for programs,
folders, websites, and keyboard shortcuts, with "Smart Launch" so pressing
a key activates an already-open window instead of spawning a duplicate.

This repo contains two AutoHotkey v2 applications that share a common
library:

| App | File | Purpose |
|---|---|---|
| **Configurator** | `Configurator.ahk` | GUI to create/edit/test/import/export shortcuts and settings. |
| **Launcher** | `Launcher.ahk` | Lightweight background process that binds the numpad hotkeys and performs the actual Smart Launch. Runs at startup if enabled in Settings. |

Both read/write the same `data\config.json`. Every change in the
Configurator (adding/editing/deleting a shortcut, or Settings) is saved
immediately, and you're then asked whether to reload the Launcher right
away so the change takes effect without leaving the Configurator. You can
always say no and reload later from the Launcher's tray icon ("Reload
Configuration"), or by restarting the Launcher.

## Requirements

- Windows 10/11
- [AutoHotkey v2.0+](https://www.autohotkey.com/)

## Running

```
AutoHotkey64.exe Configurator.ahk   ; edit your shortcuts
AutoHotkey64.exe Launcher.ahk       ; run the actual numpad launcher
```

On first launch, the Configurator shows **no shortcuts** — by design,
NumpadOS never pre-creates example shortcuts. Everything is built from
scratch via **+ Add Shortcut**.

## Project layout

```
NumpadOS/
├── Configurator.ahk        Entry point: Configurator GUI app
├── Launcher.ahk             Entry point: background hotkey/launch process
├── lib/
│   ├── JSON.ahk             Minimal JSON parser/serializer
│   ├── Logger.ahk           Shared rolling file logger (logs/ folder)
│   ├── Config.ahk           config.json load/save/validate + accessors
│   ├── Utils.ahk            Key/type labels, hotkey validation, startup
│   │                        registry integration, dark-theme helpers
│   ├── SmartLaunch.ahk       Core launch-or-activate logic (shared by
│   │                        Launcher hotkeys and the Configurator's
│   │                        Test button, so behavior is identical)
│   ├── IconUtils.ahk         Icon extraction (exe/folder) + favicon download
│   ├── Gui_Main.ahk          Main window (shortcut list + actions)
│   ├── Gui_Wizard.ahk        Add/Edit Shortcut wizard (3 steps)
│   └── Gui_Settings.ahk      Settings window
├── config/
│   └── config.default.json  Reference copy of the schema (not read at runtime)
└── data/
    ├── config.json           Created automatically on first run
    └── icon_cache/            Downloaded favicons, cached by shortcut name
```

`data\config.json` is the single source of truth. Example shape:

```json
{
  "settings": {
    "runAtStartup": true,
    "startMinimized": true,
    "runLauncherAfterLogin": false,
    "showTrayIcon": true,
    "checkForUpdates": true,
    "runAsAdmin": false
  },
  "shortcuts": [
    {
      "key": "Numpad1",
      "type": "program",
      "name": "Visual Studio Code",
      "target": "C:\\Program Files\\Microsoft VS Code\\Code.exe",
      "args": "",
      "iconPath": "",
      "matchExe": "",
      "matchTitle": "",
      "matchClass": "",
      "enabled": true
    }
  ]
}
```

> **Note on booleans:** AutoHotkey v2 has no distinct boolean type — `true`/
> `false` are just aliases for the integers `1`/`0`. `lib/JSON.ahk` therefore
> serializes settings and `enabled` as `1`/`0` rather than the literal
> tokens `true`/`false`. This is still valid, parseable JSON and every
> truthy check in the codebase (`sc["enabled"] ? ... : ...`) treats it
> identically to a real boolean — but if you're hand-editing `config.json`
> or writing an external tool against it, expect `1`/`0`, not `true`/`false`.

## Smart Launch strategy

Implemented in `lib/SmartLaunch.ahk`, matching is layered:

1. **Process match** — enumerate windows belonging to the target `ahk_exe`.
2. **Filter** — discard hidden windows, tool windows, and windows with an
   owner (dialogs/popups), and any window whose title matches a known
   helper/splash pattern for that app.
3. **Disambiguate** — if a window class hint is known (built-in for VS
   Code, Obsidian, Notepad, Windows Terminal, Brave, Chrome, Discord,
   Steam, Explorer — see `SmartLaunch.AppRules`) or supplied per-shortcut
   via `matchExe` / `matchTitle` / `matchClass`, use it to pick the right
   window among several candidates.
4. **Activate or launch** — activate the first suitable window found;
   otherwise start a new instance.

`SmartLaunch.AppRules` is a small, editable `Map` — add an entry to teach
NumpadOS about another application's window class or helper-window titles
without touching the matching algorithm itself.

Folder shortcuts use a simpler best-effort match against open Explorer
(`CabinetWClass`) windows by folder name. Website shortcuts always open a
new tab in the default browser today; matching an already-open tab is
called out as a future enhancement (stubbed in `SmartLaunch.LaunchWebsite`)
since it needs browser-specific automation.

`Ctrl+Alt+Delete` is explicitly rejected by `Utils.ValidateHotkeyCombo`
since Windows reserves it and it cannot be sent programmatically.

## Settings

All settings live under `config.json → settings` and are edited from the
Settings window:

- **Launch NumpadOS at Windows startup** — writes/removes a `HKCU\...\Run`
  registry entry pointing at `Launcher.ahk` (see `Utils.SetRunAtStartup`).
- **Start minimized** — Configurator window starts hidden to tray.
- **Run launcher automatically after login** — reserved for a future
  Task Scheduler–based alternative to the Run-key startup entry (e.g. for
  scenarios needing elevation at logon); currently stored but not yet
  wired to a separate mechanism.
- **Show tray icon** — toggles `A_IconHidden` for both apps.
- **Check for updates automatically** — stored for a future update-checker
  module; not yet implemented.
- **Run as Administrator** — stored as a flag; the Launcher logs a warning
  if this is enabled but it isn't actually running elevated, since
  matching/activating windows belonging to elevated processes generally
  requires the Launcher to be elevated too. Wiring up an actual elevation
  request (UAC re-launch) is left for a follow-up since it changes how the
  startup entry needs to be created (a scheduled task is typically needed
  for silent elevated auto-start, rather than the Run key).

## Extending NumpadOS (designed-in extension points)

- **Drag-and-drop shortcut creation** — `Gui_Main.ahk`'s `MainWindow.Show()`
  is the place to add `OnEvent("DropFiles", ...)` on the Gui/ListView; it
  can call `ShortcutWizard.ShowNew()` pre-seeded with a detected type/path.
- **Auto-detect installed applications** — add a module (e.g.
  `lib/AppDiscovery.ahk`) that enumerates Start Menu shortcuts / the
  uninstall registry keys and feeds suggestions into Step 3 of the wizard.
- **Custom icons** — `IconUtils.IconIndexForShortcut` is the single place
  icons are resolved; add a `customIconPath` field to the shortcut schema
  and check it first.
- **Categories** — the `shortcuts` array entries can gain a `category`
  field; `Config._Validate` already fills in missing fields with defaults
  for backward compatibility, and `MainWindow._SortedShortcuts` is the
  place to group/sort by category.
- **Search bar** — add an Edit control above the ListView in `Gui_Main.ahk`
  and filter the array passed into the render loop in `MainWindow.Refresh`.

## Logging

Both apps log to `logs\configurator.log` and `logs\launcher.log`
respectively (rotated to `.old` at 1 MB). Logging failures never crash the
app — see `Logger._Write`.

## Known limitations / notes

- This project was authored and reviewed outside of a Windows/AutoHotkey
  environment, so while the code follows AutoHotkey v2 syntax and API
  conventions carefully, it has not been executed against a live AHK
  interpreter. Please run it locally and file issues for anything that
  needs adjustment — the small, modular file layout is meant to make
  fixes easy to isolate.
- The Configurator uses one consistent, static light theme with standard
  Windows controls (`Utils.ApplyStandardTheme`) - there's no automatic/dark
  Windows theme integration, so text stays readable everywhere.
- The Keyboard Shortcut editor uses three dropdown boxes joined by "+"
  (e.g. `[Ctrl] + [Shift] + [Esc]`) instead of a "press any keys" capture
  field. The first box is a modifier; the second is a modifier or the
  final key; the third is optional and only used when the second box holds
  a modifier. Existing shortcuts created with the old capture-based editor
  still load and edit correctly, since both use the same `Ctrl+Shift+Esc`-style
  storage format.
- Favicon downloading only tries `<origin>/favicon.ico`; sites that only
  expose a favicon via `<link>` tags in a different format/location will
  fall back to a generic globe icon.

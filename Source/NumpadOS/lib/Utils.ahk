; ============================================================================
; Utils.ahk
; ----------------------------------------------------------------------------
; Small shared helpers: key display names, hotkey validation, Windows startup
; registration, and misc path/string helpers. Used by both the Configurator
; and the Launcher so behavior stays consistent between them.
; ============================================================================

class Utils
{
    ; Internal key name (as used in config.json / AHK hotkeys) -> friendly label
    static KeyLabels := Map(
        "Numpad0", "Numpad 0", "Numpad1", "Numpad 1", "Numpad2", "Numpad 2",
        "Numpad3", "Numpad 3", "Numpad4", "Numpad 4", "Numpad5", "Numpad 5",
        "Numpad6", "Numpad 6", "Numpad7", "Numpad 7", "Numpad8", "Numpad 8",
        "Numpad9", "Numpad 9",
        "NumpadDiv", "Numpad /", "NumpadMult", "Numpad *",
        "NumpadSub", "Numpad -", "NumpadAdd", "Numpad +",
        "NumpadDot", "Numpad .", "NumpadEnter", "Numpad Enter"
    )

    static TypeLabels := Map(
        "program", "Program",
        "folder", "Folder",
        "website", "Website",
        "keyboard", "Keyboard Shortcut"
    )

    static KeyLabel(key) => Utils.KeyLabels.Has(key) ? Utils.KeyLabels[key] : key
    static TypeLabel(type) => Utils.TypeLabels.Has(type) ? Utils.TypeLabels[type] : type

    ; Validates a hotkey combo string built from the shortcut editor's
    ; dropdown boxes (e.g. "Ctrl+Shift+Esc"). Returns "" if valid, or an
    ; error message. Checks are token-based (not an exact string match) so
    ; that Ctrl+Alt+Delete is caught regardless of which box each modifier
    ; was chosen in (e.g. "Alt+Ctrl+Delete" is just as reserved).
    static ValidateHotkeyCombo(combo)
    {
        if (combo = "")
            return "No key combination was chosen."

        hasCtrl := false, hasAlt := false, hasDeleteKey := false
        for part in StrSplit(combo, "+")
        {
            t := StrLower(Trim(part))
            if (t = "ctrl" || t = "control")
                hasCtrl := true
            else if (t = "alt")
                hasAlt := true
            else if (t = "delete" || t = "del")
                hasDeleteKey := true
        }
        if (hasCtrl && hasAlt && hasDeleteKey)
            return "Ctrl+Alt+Delete cannot be used - it is reserved by Windows."

        return ""
    }

    ; ---- Save & Apply workflow ----
    ; Called by the Configurator right after any change is saved to
    ; config.json (Add/Edit/Delete Shortcut, Settings). Offers to apply the
    ; change immediately by reloading the (separately running) Launcher
    ; process, without forcing the user to use the tray menu's manual
    ; "Reload Configuration" item, which remains available as before.
    static ShowSavedReloadPrompt()
    {
        result := MsgBox(
            "Configuration saved successfully.`n`nApply changes by reloading the launcher configuration now?",
            "NumpadOS", "YesNo Icon!")
        if (result = "Yes")
            Utils.ReloadRunningLauncher()
    }

    ; Relaunches Launcher.ahk. Because Launcher.ahk declares
    ; "#SingleInstance Force", if it is already running this transparently
    ; replaces the old process with a new one that re-reads config.json and
    ; re-registers hotkeys from scratch - i.e. an automatic reload. If it
    ; isn't running yet, this simply starts it.
    static ReloadRunningLauncher()
    {
        launcherPath := A_ScriptDir . "\Launcher.ahk"
        if !FileExist(launcherPath)
        {
            Logger.Warn("Launcher.ahk not found next to the Configurator - can't reload it.")
            MsgBox("Couldn't find Launcher.ahk to reload it.", "NumpadOS", "Icon!")
            return
        }
        try
        {
            Run('"' . A_AhkPath . '" "' . launcherPath . '"')
            Logger.Info("Requested Launcher reload.")
        }
        catch as e
        {
            Logger.Error("Failed to reload the Launcher: " . e.Message)
            MsgBox("Couldn't reload the Launcher automatically. You can also use its tray icon's 'Reload Configuration' option.", "NumpadOS", "Icon!")
        }
    }

    ; ---- Windows Startup integration ----
    ; Uses the current user's Run registry key rather than the Startup
    ; folder, so it works reliably even if the script is later compiled.
    static StartupRegKey := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    static StartupValueName := "NumpadOS"

    ; Returns true on success, false on failure. RegWrite always overwrites
    ; the single "NumpadOS" value name (never creates a second entry), so
    ; toggling this repeatedly can never produce duplicate startup entries.
    static SetRunAtStartup(enabled, launcherPath)
    {
        try
        {
            if (enabled)
            {
                cmd := '"' . A_AhkPath . '" "' . launcherPath . '"'
                RegWrite(cmd, "REG_SZ", Utils.StartupRegKey, Utils.StartupValueName)
                Logger.Info("Startup entry created: " . cmd)
            }
            else
            {
                if RegRead(Utils.StartupRegKey, Utils.StartupValueName, "")
                    RegDelete(Utils.StartupRegKey, Utils.StartupValueName)
                Logger.Info("Startup entry removed.")
            }
            return true
        }
        catch as e
        {
            Logger.Error("Failed to update startup registration: " . e.Message)
            return false
        }
    }

    ; Reads the actual registry value rather than trusting config.json, so
    ; the Settings checkbox always reflects what Windows will really do at
    ; next login - even if a previous save silently failed before this fix,
    ; or the entry was removed/edited outside of NumpadOS.
    static IsRunAtStartupEnabled()
    {
        try
            return RegRead(Utils.StartupRegKey, Utils.StartupValueName, "") != ""
        catch
            return false
    }

    ; ---- Path / string helpers ----

    static FileExistsAndReadable(path)
    {
        return path != "" && FileExist(path) != ""
    }

    ; Extracts a reasonable default display name from a path or URL.
    static SuggestNameFromPath(path)
    {
        SplitPath(path, &name, , &ext, &nameNoExt)
        return nameNoExt != "" ? nameNoExt : name
    }

    static SuggestNameFromUrl(url)
    {
        host := url
        host := RegExReplace(host, "^https?://", "")
        host := RegExReplace(host, "^www\.", "")
        host := RegExReplace(host, "/.*$", "")
        return host
    }

    ; Basic URL sanity check - not exhaustive, just catches obvious mistakes.
    static IsPlausibleUrl(url)
    {
        return RegExMatch(url, "^https?://[^\s]+\.[^\s]+")
    }

    ; ---- Theme ----
    ; NumpadOS previously tried to automatically follow/approximate Windows'
    ; dark mode (DWM immersive dark title bar + "DarkMode_Explorer" visual
    ; style on controls). AHK v2's built-in controls don't have first-class
    ; dark mode support, so several controls (radio/checkbox labels, dropdown
    ; internals, message boxes) kept their default light rendering while the
    ; Gui background and some text went dark - resulting in unreadable,
    ; low-contrast text in places.
    ;
    ; That automatic/dynamic theme integration has been removed entirely.
    ; NumpadOS now always uses one consistent, static light theme built on
    ; standard Windows controls, which guarantees readable text and proper
    ; contrast everywhere, with no light/dark switching to fall out of sync.
    static Colors := Map(
        "bg", "F0F0F0",
        "bgAlt", "FFFFFF",
        "text", "000000",
        "accent", "0067C0"
    )

    ; Applies the standard NumpadOS theme to a top-level Gui window.
    static ApplyStandardTheme(guiObj)
    {
        guiObj.BackColor := Utils.Colors["bg"]
        guiObj.SetFont("c" . Utils.Colors["text"] . " s10", "Segoe UI")
    }

    ; Intentionally a no-op: NumpadOS uses standard Windows controls with no
    ; per-control theme override, which keeps every control's text readable
    ; and matches the rest of the OS. Kept as a function (rather than
    ; removing every call site) so it stays a single, obvious place to
    ; revisit if custom control styling is ever wanted again.
    static ApplyControlTheme(ctrl)
    {
    }
}

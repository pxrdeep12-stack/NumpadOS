; ============================================================================
; SmartLaunch.ahk
; ----------------------------------------------------------------------------
; Shared "launch or activate" logic used by both the Launcher (real hotkey
; presses) and the Configurator (the Test button), so Test always behaves
; exactly like the real thing.
;
; Layered window-matching strategy (in priority order):
;   1. Enumerate windows belonging to the target process (ahk_exe).
;   2. Discard hidden windows, tool windows, and known helper/splash
;      windows (see AppRules below).
;   3. If a class and/or title hint is known (either from AppRules or
;      from a per-shortcut override), use it to pick the correct window
;      out of several candidates.
;   4. Activate the first remaining candidate; otherwise launch a new
;      instance.
;
; AppRules is intentionally a small, editable table so support for new
; applications can be added without touching the matching algorithm.
; ============================================================================

class SmartLaunch
{
    ; ---- Per-application matching hints (extend this as needed) ----
    ; classHint      - expected window class of the *main* window (optional)
    ; titleExclude   - array of substrings; windows containing any of these
    ;                  in their title are treated as helper/tool windows
    ;                  (e.g. picture-in-picture, notification popups)
    static AppRules := Map(
        "code.exe",        Map("classHint", "Chrome_WidgetWin_1", "titleExclude", []),
        "obsidian.exe",     Map("classHint", "Chrome_WidgetWin_1", "titleExclude", []),
        "notepad.exe",      Map("classHint", "Notepad", "titleExclude", []),
        "windowsterminal.exe", Map("classHint", "CASCADIA_HOSTING_WINDOW_CLASS", "titleExclude", []),
        "brave.exe",        Map("classHint", "Chrome_WidgetWin_1", "titleExclude", []),
        "chrome.exe",       Map("classHint", "Chrome_WidgetWin_1", "titleExclude", []),
        "discord.exe",      Map("classHint", "Chrome_WidgetWin_1", "titleExclude", []),
        "steam.exe",        Map("classHint", "SDL_app", "titleExclude", ["Steam - Update News", "Steam Notification"]),
        "explorer.exe",     Map("classHint", "CabinetWClass", "titleExclude", [])
    )

    ; ================= Public dispatch =================

    ; shortcut is a Map as stored in config.json (see Config.ahk for schema).
    static Launch(shortcut)
    {
        try
        {
            switch shortcut["type"]
            {
                case "program":  SmartLaunch.LaunchProgram(shortcut)
                case "folder":   SmartLaunch.LaunchFolder(shortcut)
                case "website":  SmartLaunch.LaunchWebsite(shortcut)
                case "keyboard": SmartLaunch.SendKeyboardShortcut(shortcut)
                default:
                    Logger.Warn("Unknown shortcut type: " . shortcut["type"])
            }
        }
        catch as e
        {
            Logger.Error("Launch failed for '" . shortcut["name"] . "': " . e.Message)
            throw e
        }
    }

    ; ================= Program =================

    static LaunchProgram(shortcut)
    {
        target := shortcut["target"]
        args := shortcut.Has("args") ? shortcut["args"] : ""

        exeName := shortcut.Has("matchExe") && shortcut["matchExe"] != ""
            ? shortcut["matchExe"]
            : SmartLaunch._ExeNameFromPath(target)

        titleHint := shortcut.Has("matchTitle") ? shortcut["matchTitle"] : ""
        classHint := shortcut.Has("matchClass") ? shortcut["matchClass"] : ""

        hwnd := SmartLaunch.FindMainWindow(exeName, titleHint, classHint)
        if (hwnd)
        {
            Logger.Info("Activating existing window for " . exeName)
            SmartLaunch.ActivateWindow(hwnd)
            return
        }

        Logger.Info("No running instance of " . exeName . " found - launching " . target)
        if !FileExist(target)
        {
            throw Error("Executable not found: " . target)
        }
        workDir := ""
        SplitPath(target, , &workDir)
        Run('"' . target . '" ' . args, workDir)
    }

    ; ================= Folder =================

    static LaunchFolder(shortcut)
    {
        path := shortcut["target"]
        if !DirExist(path)
        {
            throw Error("Folder not found: " . path)
        }

        ; Try to find an existing Explorer window already showing this folder.
        hwnd := SmartLaunch._FindExplorerWindowForPath(path)
        if (hwnd)
        {
            Logger.Info("Activating existing Explorer window for " . path)
            SmartLaunch.ActivateWindow(hwnd)
            return
        }

        Logger.Info("Opening folder in new Explorer window: " . path)
        Run('explorer.exe "' . path . '"')
    }

    static _FindExplorerWindowForPath(path)
    {
        try
        {
            for hwnd in WinGetList("ahk_class CabinetWClass", , , )
            {
                title := WinGetTitle(hwnd)
                ; Explorer window titles are usually just the folder's own name;
                ; compare against the final path segment as a best-effort match.
                SplitPath(path, &folderName)
                if (title = folderName)
                    return hwnd
            }
        }
        return 0
    }

    ; ================= Website =================

    static LaunchWebsite(shortcut)
    {
        url := shortcut["target"]
        Logger.Info("Opening website: " . url)
        ; Future enhancement: detect an already-open tab with this URL in the
        ; default browser and activate it instead of opening a new one. This
        ; requires browser-specific automation (e.g. UI Automation or a
        ; browser extension) and is intentionally left as a stub for now.
        Run(url)
    }

    ; ================= Keyboard shortcut =================

    static SendKeyboardShortcut(shortcut)
    {
        combo := shortcut["target"]
        err := Utils.ValidateHotkeyCombo(combo)
        if (err != "")
            throw Error(err)

        sendString := SmartLaunch._ComboToSendString(combo)
        Logger.Info("Sending keyboard shortcut: " . combo . " (" . sendString . ")")
        Send(sendString)
    }

    ; Converts a human string like "Ctrl+Shift+Esc" into AHK Send syntax,
    ; e.g. "^+{Esc}".
    static _ComboToSendString(combo)
    {
        parts := StrSplit(combo, "+")
        modifiers := ""
        key := ""
        for i, part in parts
        {
            p := StrLower(Trim(part))
            switch p
            {
                case "ctrl", "control": modifiers .= "^"
                case "alt": modifiers .= "!"
                case "shift": modifiers .= "+"
                case "win", "windows": modifiers .= "#"
                default: key := Trim(part)
            }
        }
        if (key = "")
            throw Error("Invalid key combination: " . combo)
        return modifiers . "{" . key . "}"
    }

    ; ================= Window matching core =================

    ; Returns a window handle for the "best" main window belonging to the
    ; given exe, or 0 if no suitable window is currently open.
    static FindMainWindow(exeName, titleHint := "", classHint := "")
    {
        exeNameLower := StrLower(exeName)
        rule := SmartLaunch.AppRules.Has(exeNameLower) ? SmartLaunch.AppRules[exeNameLower] : ""

        effectiveClassHint := classHint != "" ? classHint : (rule != "" ? rule["classHint"] : "")
        titleExclude := rule != "" ? rule["titleExclude"] : []

        candidates := []
        try candidates := WinGetList("ahk_exe " . exeName)
        if !IsSet(candidates) || candidates.Length = 0
            return 0

        for hwnd in candidates
        {
            if !SmartLaunch._IsRealMainWindow(hwnd)
                continue

            title := ""
            try title := WinGetTitle(hwnd)
            if (title = "")
                continue ; hidden/background/helper windows usually have no title

            skip := false
            for pattern in titleExclude
            {
                if InStr(title, pattern)
                {
                    skip := true
                    break
                }
            }
            if (skip)
                continue

            if (titleHint != "" && !InStr(title, titleHint))
                continue

            if (effectiveClassHint != "")
            {
                winClass := ""
                try winClass := WinGetClass(hwnd)
                if (winClass != effectiveClassHint)
                    continue
            }

            return hwnd ; first suitable candidate wins
        }

        return 0
    }

    ; Filters out hidden windows, tool windows, and other non-main windows.
    static _IsRealMainWindow(hwnd)
    {
        try
        {
            if !DllCall("IsWindowVisible", "ptr", hwnd)
                return false

            exStyle := WinGetExStyle(hwnd)
            WS_EX_TOOLWINDOW := 0x80
            if (exStyle & WS_EX_TOOLWINDOW)
                return false

            ; Windows with an owner are typically dialogs/popups, not main windows.
            owner := DllCall("GetWindow", "ptr", hwnd, "uint", 4, "ptr") ; GW_OWNER
            if (owner != 0)
                return false

            return true
        }
        catch
        {
            return false
        }
    }

    static ActivateWindow(hwnd)
    {
        try
        {
            if WinGetMinMax(hwnd) = -1
                WinRestore(hwnd)
            WinActivate(hwnd)
            WinWaitActive(hwnd, , 1)
        }
        catch as e
        {
            Logger.Warn("Failed to activate window: " . e.Message)
        }
    }

    static _ExeNameFromPath(path)
    {
        SplitPath(path, &name)
        return name
    }
}

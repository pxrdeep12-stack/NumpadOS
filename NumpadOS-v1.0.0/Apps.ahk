#Requires AutoHotkey v2.0

; ============================================================================
; NumpadOS - Application Launcher
; ============================================================================
; Intelligent app launcher with smart window detection.
; Prevents duplicate windows by activating existing instances instead of
; spawning new ones.
;
; ARCHITECTURE
; ------------
; Every application (Brave PWA or desktop app) is launched through one of
; two generic pairs of functions. No app-specific window-search logic lives
; outside of these four functions:
;
;   ActivateBravePWA(titleKeyword)                  - find & focus a PWA
;   LaunchBravePWA(titleKeyword, shortcut, appName)  - activate or launch a PWA
;   ActivateDesktopApp(exeName, appName)             - find & focus a desktop app
;   LaunchDesktopApp(launchCmd, exeName, appName)    - activate or launch a desktop app
;
; Harmonoid, Obsidian, and Brave Browser are installed at known, fixed paths
; on this system. Their executable paths come ONLY from Config.ini (which
; defaults to the real install path) via ResolveFixedExecutable() - there is
; no guessing across A_LocalAppData, ProgramFiles(x86), or other common
; install folders.
;
; The individual LaunchXxx() functions below (called directly from hotkeys
; in Launcher.ahk) are thin wrappers that just supply the right arguments to
; these generic functions. This keeps the file free of duplicated
; launch/activate logic.
;
; Exports (Public API):
;   - LaunchChatGPT()
;   - LaunchClaude()
;   - LaunchHarmonoid()
;   - LaunchObsidian()
;   - LaunchVSCode()
;   - LaunchCommandPrompt()
;   - LaunchYouTube()
;   - LaunchNotepad()
;   - LaunchBraveBrowser()
;   - LaunchTaskManager()
;   - LaunchFileExplorer()
; ============================================================================

; Bounded retry settings used after launching a new process. This is a
; one-shot, short-lived wait loop - NOT a persistent background timer/poll.
; It exists only to give a freshly launched app a moment to create its
; window before we give up trying to activate it.
global LAUNCH_RETRY_ATTEMPTS := 10
global LAUNCH_RETRY_INTERVAL_MS := 300

; ============================================================================
; BRAVE PWA DETECTION & ACTIVATION (generic)
; ============================================================================

ActivateBravePWA(titleKeyword) {
    ; Searches all Brave windows for one whose title contains titleKeyword.
    ; Restores it if minimized and activates it.
    ; Returns true if a matching window was found and activated.

    try {
        windowList := WinGetList("ahk_exe brave.exe")
        needle := StrLower(titleKeyword)

        loop windowList.Length {
            hwnd := windowList[A_Index]
            title := WinGetTitle("ahk_id " . hwnd)

            if (DEBUG_MODE)
                LogMessage("Brave window seen: " . title, "DEBUG")

            if InStr(StrLower(title), needle) {
                RestoreAndActivateWindow(hwnd)
                LogMessage("Activated Brave PWA '" . titleKeyword . "' (Title: " . title . ")", "INFO")
                return true
            }
        }

        if (DEBUG_MODE)
            LogMessage("No matching Brave PWA found for: " . titleKeyword, "DEBUG")
        return false

    } catch as err {
        LogMessage("Error searching for Brave PWA '" . titleKeyword . "': " . err.Message, "ERROR")
        return false
    }
}

LaunchBravePWA(titleKeyword, shortcutPath, appName) {
    ; Activates the existing PWA window if one exists, otherwise launches it
    ; via its shortcut and waits (briefly) for the window to appear.

    if (ActivateBravePWA(titleKeyword))
        return true

    if (!FileExist(shortcutPath)) {
        LogMessage("Shortcut not found: " . shortcutPath . " for " . appName, "ERROR")
        return false
    }

    LogMessage("Launching Brave PWA: " . appName, "INFO")

    pid := TryRun(shortcutPath)
    if (pid <= 0) {
        LogMessage("Failed to launch " . appName . " shortcut", "ERROR")
        return false
    }

    ; Bounded wait for the PWA window to appear, then activate it.
    loop LAUNCH_RETRY_ATTEMPTS {
        Sleep(LAUNCH_RETRY_INTERVAL_MS)
        if (ActivateBravePWA(titleKeyword)) {
            LogMessage("Successfully launched Brave PWA: " . appName, "INFO")
            return true
        }
    }

    LogMessage(appName . " launched but window not detected in time", "INFO")
    return true
}

; ============================================================================
; DESKTOP APP DETECTION & ACTIVATION (generic)
; ============================================================================

ActivateDesktopApp(exeName, appName) {
    ; Finds a top-level window belonging to exeName and activates it.

    try {
        target := "ahk_exe " . exeName
        if (!WinExist(target)) {
            if (DEBUG_MODE)
                LogMessage("Desktop app not found: " . appName . " (" . exeName . ")", "DEBUG")
            return false
        }

        hwnd := WinGetID(target)
        RestoreAndActivateWindow(hwnd)
        LogMessage("Activated desktop app: " . appName, "INFO")
        return true
    } catch as err {
        LogMessage("Error activating desktop app '" . appName . "': " . err.Message, "ERROR")
        return false
    }
}

LaunchDesktopApp(launchCmd, exeName, appName) {
    ; Activates the existing app window if one exists, otherwise launches it
    ; and waits (briefly) for the window to appear.

    if (ActivateDesktopApp(exeName, appName))
        return true

    if (launchCmd = "") {
        LogMessage("No launch command configured for " . appName, "ERROR")
        return false
    }

    LogMessage("Launching desktop app: " . appName . " (" . launchCmd . ")", "INFO")

    pid := TryRun(launchCmd)
    if (pid <= 0) {
        LogMessage("Failed to launch " . appName . " from command: " . launchCmd, "ERROR")
        return false
    }

    loop LAUNCH_RETRY_ATTEMPTS {
        Sleep(LAUNCH_RETRY_INTERVAL_MS)
        if (ActivateDesktopApp(exeName, appName)) {
            LogMessage("Successfully launched desktop app: " . appName, "INFO")
            return true
        }
    }

    LogMessage(appName . " launched but window not detected in time", "INFO")
    return true
}

; ============================================================================
; EXECUTABLE RESOLUTION
; ============================================================================
; Harmonoid, Obsidian, and Brave Browser are installed at known, fixed
; locations on this system. NumpadOS uses ONLY the path configured in
; Config.ini (which defaults to the real install path below) - it never
; guesses across A_LocalAppData, ProgramFiles(x86), or other common install
; folders. If the executable isn't at the configured path, that's a
; configuration problem to fix in Config.ini, not something to search for.

ResolveFixedExecutable(exePath, appName, configKey) {
    if (exePath = "" || !FileExist(exePath)) {
        LogMessage(appName . " executable not found at: '" . exePath . "'. Update " . configKey . " in Config.ini.", "ERROR")
        return ""
    }
    return exePath
}

; ============================================================================
; SPECIAL-CASE ACTIVATION
; ============================================================================
; These two need custom logic that doesn't fit the generic Activate*()
; signatures: File Explorer has multiple window classes, and a "normal"
; Brave window must specifically exclude the PWA windows.

ActivateExplorerWindow() {
    try {
        for index, className in ["CabinetWClass", "ExploreWClass"] {
            windowList := WinGetList("ahk_class " . className)
            if (windowList.Length > 0) {
                RestoreAndActivateWindow(windowList[1])
                LogMessage("Activated File Explorer", "INFO")
                return true
            }
        }
        return false
    } catch as err {
        LogMessage("Error activating File Explorer: " . err.Message, "ERROR")
        return false
    }
}

LaunchFileExplorer() {
    if (ActivateExplorerWindow())
        return true

    LogMessage("Launching File Explorer", "INFO")
    pid := TryRun("explorer.exe")
    if (pid <= 0) {
        LogMessage("Failed to launch File Explorer", "ERROR")
        return false
    }

    loop LAUNCH_RETRY_ATTEMPTS {
        Sleep(LAUNCH_RETRY_INTERVAL_MS)
        if (ActivateExplorerWindow()) {
            LogMessage("Successfully launched File Explorer", "INFO")
            return true
        }
    }

    LogMessage("File Explorer launched but window not detected in time", "INFO")
    return true
}

; PWA app names that must never be treated as a "normal" Brave window.
BravePwaTitleKeywords() {
    return ["ChatGPT", "Claude", "YouTube"]
}

ActivateNormalBraveWindow() {
    ; Activates a Brave window that is NOT one of the known PWAs.

    try {
        windowList := WinGetList("ahk_exe brave.exe")
        pwaKeywords := BravePwaTitleKeywords()

        loop windowList.Length {
            hwnd := windowList[A_Index]
            title := WinGetTitle("ahk_id " . hwnd)

            isPwa := false
            for index, keyword in pwaKeywords {
                if InStr(title, keyword) {
                    isPwa := true
                    break
                }
            }

            if (!isPwa) {
                RestoreAndActivateWindow(hwnd)
                LogMessage("Activated normal Brave window: " . title, "INFO")
                return true
            }
        }
        return false
    } catch as err {
        LogMessage("Error searching for normal Brave window: " . err.Message, "ERROR")
        return false
    }
}

LaunchBraveBrowser() {
    if (ActivateNormalBraveWindow())
        return true

    launchCmd := ResolveFixedExecutable(CONFIG["BravePath"], "Brave Browser", "BravePath")
    if (launchCmd = "")
        return false

    LogMessage("Launching Brave Browser", "INFO")
    pid := TryRun(launchCmd)
    if (pid <= 0) {
        LogMessage("Failed to launch Brave Browser", "ERROR")
        return false
    }

    loop LAUNCH_RETRY_ATTEMPTS {
        Sleep(LAUNCH_RETRY_INTERVAL_MS)
        if (ActivateNormalBraveWindow()) {
            LogMessage("Successfully launched Brave Browser", "INFO")
            return true
        }
    }

    LogMessage("Brave Browser launched but window not detected in time", "INFO")
    return true
}

; ============================================================================
; PUBLIC API - APPLICATION LAUNCH FUNCTIONS
; ============================================================================
; Called directly by hotkeys in Launcher.ahk. Each function is a thin
; wrapper around the generic Launch/Activate pair above - no app-specific
; window-search logic here.
; ============================================================================

LaunchChatGPT() {
    shortcut := CONFIG["ChatGPTShortcut"]
    if (shortcut = "") {
        LogMessage("ChatGPT shortcut not configured", "ERROR")
        return false
    }
    return LaunchBravePWA("ChatGPT", shortcut, "ChatGPT")
}

LaunchClaude() {
    ; Claude is a Brave PWA - not a desktop app. Never search for Claude.exe.
    shortcut := CONFIG["ClaudeShortcut"]
    if (shortcut = "") {
        LogMessage("Claude shortcut not configured", "ERROR")
        return false
    }
    return LaunchBravePWA("Claude", shortcut, "Claude")
}

LaunchYouTube() {
    shortcut := CONFIG["YouTubeShortcut"]
    if (shortcut = "") {
        LogMessage("YouTube shortcut not configured", "ERROR")
        return false
    }
    return LaunchBravePWA("YouTube", shortcut, "YouTube")
}

LaunchHarmonoid() {
    resolvedPath := ResolveFixedExecutable(CONFIG["HarmonoidPath"], "Harmonoid", "HarmonoidPath")
    if (resolvedPath = "")
        return false
    return LaunchDesktopApp(resolvedPath, "harmonoid.exe", "Harmonoid")
}

LaunchObsidian() {
    resolvedPath := ResolveFixedExecutable(CONFIG["ObsidianPath"], "Obsidian", "ObsidianPath")
    if (resolvedPath = "")
        return false
    return LaunchDesktopApp(resolvedPath, "Obsidian.exe", "Obsidian")
}

LaunchVSCode() {
    launchCmd := CONFIG["VSCodePath"]
    return LaunchDesktopApp(launchCmd, "Code.exe", "Visual Studio Code")
}

LaunchCommandPrompt() {
    ; Must always be cmd.exe, never Windows Terminal (wt.exe).
    launchCmd := CONFIG["CommandPromptPath"]
    return LaunchDesktopApp(launchCmd, "cmd.exe", "Command Prompt")
}

LaunchNotepad() {
    launchCmd := CONFIG["NotepadPath"]
    return LaunchDesktopApp(launchCmd, "notepad.exe", "Notepad")
}

LaunchTaskManager() {
    launchCmd := CONFIG["TaskManagerPath"]
    return LaunchDesktopApp(launchCmd, "Taskmgr.exe", "Task Manager")
}

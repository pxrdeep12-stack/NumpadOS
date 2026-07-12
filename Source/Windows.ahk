#Requires AutoHotkey v2.0

; ============================================================================
; NumpadOS - Window Management Functions
; ============================================================================
; Functions for manipulating active windows: minimize, maximize, close, etc.
;
; Exports:
;   - MinimizeActiveWindow()
;   - MaximizeOrRestoreWindow()
;   - ToggleAlwaysOnTop()
;   - CloseActiveWindow()
;   - OpenWindowsSettings()
;   - OpenClipboardHistory()
;   - RestoreAndActivateWindow()
;   - ActivateWindowByProcess()
; ============================================================================

; ============================================================================
; WINDOW ACTIVATION
; ============================================================================

RestoreAndActivateWindow(hwnd) {
    if (!hwnd) {
        LogMessage("RestoreAndActivateWindow: Invalid window handle", "DEBUG")
        return false
    }
    
    try {
        ; Restore if minimized
        if (WinGetMinMax("ahk_id " . hwnd) = -1) {
            WinRestore("ahk_id " . hwnd)
            if (DEBUG_MODE) {
                LogMessage("Window restored: " . WinGetTitle("ahk_id " . hwnd), "DEBUG")
            }
        }
        
        ; Activate the window
        WinActivate("ahk_id " . hwnd)
        return true
    } catch as err {
        LogMessage("Failed to restore/activate window: " . err.Message, "ERROR")
        return false
    }
}

ActivateWindowByProcess(exeName) {
    try {
        target := "ahk_exe " . exeName
        if (!WinExist(target)) {
            if (DEBUG_MODE) {
                LogMessage("Process not found: " . exeName, "DEBUG")
            }
            return false
        }
        
        hwnd := WinGetID(target)
        return RestoreAndActivateWindow(hwnd)
    } catch as err {
        LogMessage("ActivateWindowByProcess error: " . err.Message, "ERROR")
        return false
    }
}

; ============================================================================
; WINDOW MANIPULATION
; ============================================================================

MinimizeActiveWindow() {
    try {
        if (!WinExist("A")) {
            return false
        }
        
        WinMinimize("A")
        if (DEBUG_MODE) {
            LogMessage("Window minimized", "DEBUG")
        }
        return true
    } catch as err {
        LogMessage("Failed to minimize window: " . err.Message, "ERROR")
        return false
    }
}

MaximizeOrRestoreWindow() {
    try {
        if (!WinExist("A")) {
            return false
        }
        
        hwnd := WinGetID("A")
        isMaximized := (WinGetMinMax("ahk_id " . hwnd) = 1)
        
        if (isMaximized) {
            WinRestore("ahk_id " . hwnd)
            if (DEBUG_MODE) {
                LogMessage("Window restored", "DEBUG")
            }
        } else {
            WinMaximize("ahk_id " . hwnd)
            if (DEBUG_MODE) {
                LogMessage("Window maximized", "DEBUG")
            }
        }
        return true
    } catch as err {
        LogMessage("Failed to maximize/restore window: " . err.Message, "ERROR")
        return false
    }
}

ToggleAlwaysOnTop() {
    try {
        if (!WinExist("A")) {
            return false
        }
        
        hwnd := WinGetID("A")
        style := WinGetExStyle("ahk_id " . hwnd)
        
        ; Check if always-on-top flag (0x8) is set
        if (style & 0x8) {
            WinSetAlwaysOnTop(0, "ahk_id " . hwnd)
            if (DEBUG_MODE) {
                LogMessage("Always On Top: OFF", "DEBUG")
            }
        } else {
            WinSetAlwaysOnTop(1, "ahk_id " . hwnd)
            if (DEBUG_MODE) {
                LogMessage("Always On Top: ON", "DEBUG")
            }
        }
        return true
    } catch as err {
        LogMessage("Failed to toggle Always On Top: " . err.Message, "ERROR")
        return false
    }
}

CloseActiveWindow() {
    try {
        if (!WinExist("A")) {
            return false
        }
        
        ; Send Alt+F4 to the active window
        Send("!{F4}")
        if (DEBUG_MODE) {
            LogMessage("Alt+F4 sent to active window", "DEBUG")
        }
        Sleep(100)
        return true
    } catch as err {
        LogMessage("Failed to close window: " . err.Message, "ERROR")
        return false
    }
}

; ============================================================================
; SYSTEM ACTIONS
; ============================================================================

OpenWindowsSettings() {
    try {
        Run("ms-settings:")
        if (DEBUG_MODE) {
            LogMessage("Windows Settings opened", "DEBUG")
        }
        return true
    } catch as err {
        LogMessage("Failed to open Windows Settings: " . err.Message, "ERROR")
        return false
    }
}

OpenClipboardHistory() {
    try {
        ; Win+V opens clipboard history
        Send("{LWin down}v{LWin up}")
        if (DEBUG_MODE) {
            LogMessage("Clipboard History opened (Win+V)", "DEBUG")
        }
        Sleep(100)
        return true
    } catch as err {
        LogMessage("Failed to open Clipboard History: " . err.Message, "ERROR")
        return false
    }
}

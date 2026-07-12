#Requires AutoHotkey v2.0

; ============================================================================
; NumpadOS - Main Launcher
; ============================================================================
; A professional Windows launcher and window manager controlled via the numpad.
; When Num Lock is OFF: Numpad becomes a launcher and window manager.
; When Num Lock is ON: Numpad works normally.
;
; Author: NumpadOS Team
; License: MIT
; ============================================================================

#SingleInstance Force
SetWorkingDir(A_ScriptDir)

; Include all modules
#Include "Helpers.ahk"
#Include "Windows.ahk"
#Include "Apps.ahk"
#Include "Toast.ahk"

; ============================================================================
; GLOBAL HOTKEYS
; ============================================================================

Ctrl & NumLock::ReloadScript()
RCtrl & NumLock::ReloadScript()

#HotIf IsNumLockOff()
NumpadEnd::LaunchChatGPT()
Numpad1::LaunchChatGPT()
NumpadDown::LaunchClaude()
Numpad2::LaunchClaude()
NumpadPgDn::LaunchHarmonoid()
Numpad3::LaunchHarmonoid()
NumpadLeft::LaunchObsidian()
Numpad4::LaunchObsidian()
NumpadClear::LaunchVSCode()
Numpad5::LaunchVSCode()
NumpadRight::LaunchCommandPrompt()
Numpad6::LaunchCommandPrompt()
NumpadHome::LaunchYouTube()
Numpad7::LaunchYouTube()
NumpadUp::LaunchNotepad()
Numpad8::LaunchNotepad()
NumpadPgUp::LaunchBraveBrowser()
Numpad9::LaunchBraveBrowser()
NumpadIns::LaunchTaskManager()
Numpad0::LaunchTaskManager()
NumpadDel::LaunchFileExplorer()
NumpadDiv::OpenWindowsSettings()
NumpadMult::CloseActiveWindow()
NumpadSub::MinimizeActiveWindow()
NumpadAdd::MaximizeOrRestoreWindow()
NumpadEnter::OpenClipboardHistory()
#HotIf

; ============================================================================
; GLOBALS
; ============================================================================

global CONFIG := Map()
global DEBUG_MODE := false
global NUMLOCK_STATE := -1

; ============================================================================
; INITIALIZATION
; ============================================================================

InitializeNumpadOS() {
    LogMessage("===== NumpadOS Starting =====", "INFO")
    
    ; Load configuration
    LoadConfig()
    
    ; Set debug mode from config
    DEBUG_MODE := (CONFIG.has("DebugMode") ? CONFIG["DebugMode"] : 0)
    if (DEBUG_MODE) {
        LogMessage("DEBUG MODE ENABLED", "INFO")
    }
    
    ; Register exit handler
    OnExit(HandleExit)
    
    ; Register hotkeys
    RegisterHotkeys()
    SetTimer(CheckNumLockState, 200)
    
    LogMessage("NumpadOS initialized successfully", "INFO")
}

; ============================================================================
; HOTKEY REGISTRATION
; ============================================================================

RegisterHotkeys() {
    LogMessage("Hotkeys registered", "INFO")
}

; ============================================================================
; HOTKEY CONDITION & CALLBACKS
; ============================================================================

IsNumLockOff() {
    return !GetKeyState("NumLock", "T")
}

CheckNumLockState() {
    global NUMLOCK_STATE

    currentState := GetKeyState("NumLock", "T")
    if (NUMLOCK_STATE = -1) {
        NUMLOCK_STATE := currentState
        return
    }

    if (currentState != NUMLOCK_STATE) {
        NUMLOCK_STATE := currentState
        if (currentState) {
            ShowModeNotification("Number Mode")
        } else {
            ShowModeNotification("Launcher Mode")
        }
    }
}

ReloadScript() {
    LogMessage("Reloading script (Ctrl+NumLock)", "INFO")
    Sleep(100)
    Reload()
}

; ============================================================================
; EXIT HANDLER
; ============================================================================

HandleExit(ExitReason, ExitCode) {
    LogMessage("NumpadOS exiting - Reason: " . ExitReason . ", Code: " . ExitCode, "INFO")
    LogMessage("===== NumpadOS Stopped =====", "INFO")
}

; ============================================================================
; SCRIPT START
; ============================================================================

InitializeNumpadOS()
LogMessage("NumpadOS ready. Num Lock controls numpad mode.", "INFO")

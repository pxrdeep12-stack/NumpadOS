#Requires AutoHotkey v2.0
#SingleInstance Force
; ============================================================================
; Launcher.ahk
; ----------------------------------------------------------------------------
; Entry point for the NumpadOS Launcher - the lightweight, tray-only
; background process that actually binds the numpad keys and performs
; Smart Launch. This is the process Windows starts at login when
; "Launch NumpadOS at Windows startup" is enabled in the Configurator.
;
; The Launcher only *reads* data\config.json; all editing happens in the
; Configurator. Use the tray menu's "Reload Configuration" after making
; changes in the Configurator (or simply restart the Launcher).
; ============================================================================

#Include lib\JSON.ahk
#Include lib\Logger.ahk
#Include lib\Config.ahk
#Include lib\Utils.ahk
#Include lib\SmartLaunch.ahk

Logger.Init("launcher.log")
Logger.Info("=== NumpadOS Launcher starting ===")

; IMPORTANT: AutoHotkey only keeps a script running past its auto-execute
; section automatically when it has hotkeys/hotstrings, a Gui, or an active
; timer/OnMessage handler *at the time the auto-execute section ends*.
; RegisterAllHotkeys() below only calls the Hotkey() function when there is
; at least one *enabled* shortcut, so with a brand-new/empty config.json the
; Launcher would otherwise fall straight through to "return" with nothing
; registered and silently exit - which is why the tray icon previously never
; appeared until a shortcut existed. Persistent() guarantees the Launcher
; (and its tray icon) always stays running regardless of shortcut count.
Persistent()

global RegisteredKeys := []

; Config.json always stores the familiar "Numpad1".."Numpad0"/"NumpadDot"
; names (see Config.ValidKeys) regardless of the chosen activation mode -
; those are the only names the Configurator ever shows or writes. However,
; Windows only reports those exact key names while NumLock is ON; the same
; physical keys report the nav-key names below while NumLock is OFF. This
; map is consulted only at hotkey-registration time (ResolveNumpadKey) to
; bind the correct physical key for whichever NumLock state the user chose -
; it never touches config loading, storage, or the GUI. The four operator
; keys and NumpadEnter aren't affected by NumLock, so they're absent here
; and registered unchanged in both modes.
global NumLockOffKeyNames := Map(
    "Numpad0", "NumpadIns",
    "Numpad1", "NumpadEnd",
    "Numpad2", "NumpadDown",
    "Numpad3", "NumpadPgDn",
    "Numpad4", "NumpadLeft",
    "Numpad5", "NumpadClear",
    "Numpad6", "NumpadRight",
    "Numpad7", "NumpadHome",
    "Numpad8", "NumpadUp",
    "Numpad9", "NumpadPgUp",
    "NumpadDot", "NumpadDel"
)

Config.Load()
RegisterAllHotkeys()
TraySetup()

; Global hotkey: Ctrl+NumLock opens the Configurator, or brings it to the
; front if it's already running. Registered directly (not through
; RegisterAllHotkeys/config.json) so it's always available while the
; Launcher is running, independent of any configured numpad shortcuts.
Hotkey("^NumLock", (*) => OpenOrFocusConfigurator(), "On")

if Config.GetSetting("runAsAdmin") && !A_IsAdmin
    Logger.Warn("'Run as Administrator' is enabled but the Launcher is not elevated. Re-launch as admin for shortcuts that require elevated windows to be matched/activated correctly.")

Logger.Info("NumpadOS Launcher ready - " . RegisteredKeys.Length . " hotkey(s) active.")
return

; ============================================================================
; Hotkey registration
; ============================================================================

RegisterAllHotkeys()
{
    global RegisteredKeys
    UnregisterAllHotkeys()

    for sc in Config.GetShortcuts()
    {
        if !sc["enabled"]
            continue
        try
        {
            hotkeyStr := "*" . ResolveNumpadKey(sc["key"])
            Hotkey(hotkeyStr, HandleHotkey.Bind(sc), "On")
            RegisteredKeys.Push(hotkeyStr)
        }
        catch as e
        {
            Logger.Error("Failed to register hotkey for " . sc["key"] . ": " . e.Message)
        }
    }
}

; Returns the AutoHotkey key name to actually register for a stored
; "Numpad1"-style key, given the current "launcherNumLockMode" setting.
; In "on" mode (the default) the stored name is used as-is, which only
; fires while NumLock is ON - identical to the launcher's original,
; always-on-NumLock behavior. In "off" mode the nav-key equivalent is
; registered instead, so the launcher fires while NumLock is OFF and the
; physical key types normal digits/decimal point while NumLock is ON.
ResolveNumpadKey(key)
{
    global NumLockOffKeyNames
    if (Config.GetSetting("launcherNumLockMode") = "off" && NumLockOffKeyNames.Has(key))
        return NumLockOffKeyNames[key]
    return key
}

UnregisterAllHotkeys()
{
    global RegisteredKeys
    for hotkeyStr in RegisteredKeys
    {
        try Hotkey(hotkeyStr, , "Off")
    }
    RegisteredKeys := []
}

HandleHotkey(shortcut, *)
{
    Logger.Info("Hotkey pressed: " . shortcut["key"] . " -> " . shortcut["name"])
    try
    {
        SmartLaunch.Launch(shortcut)
    }
    catch as e
    {
        Logger.Error("Failed to launch '" . shortcut["name"] . "': " . e.Message)
        TrayTip("NumpadOS", "Couldn't launch '" . shortcut["name"] . "': " . e.Message, "Icon!")
    }
}

; ============================================================================
; Tray icon
; ============================================================================

TraySetup()
{
    A_IconTip := "NumpadOS Launcher"
    A_IconHidden := !Config.GetSetting("showTrayIcon")

    tray := A_TrayMenu
    tray.Delete()
    tray.Add("Reload Configuration", (*) => ReloadConfiguration())
    tray.Add("Open Configurator", (*) => OpenOrFocusConfigurator())
    tray.Add()
    tray.Add("Exit", (*) => ExitApp())
    tray.Default := "Open Configurator"
}

ReloadConfiguration()
{
    Logger.Info("Reloading configuration from disk...")
    Config.Load()
    RegisterAllHotkeys()
    TrayTip("NumpadOS", "Configuration reloaded - " . RegisteredKeys.Length . " shortcut(s) active.")
}

OpenConfigurator()
{
    configuratorPath := A_ScriptDir . "\Configurator.ahk"
    if FileExist(configuratorPath)
        Run('"' . A_AhkPath . '" "' . configuratorPath . '"')
    else
        Logger.Warn("Configurator.ahk not found next to the Launcher.")
}

; Brings the existing Configurator window to the front if one is already
; running (matched by its main window title, including when it's hidden
; in the tray), otherwise starts a fresh instance. This is what backs both
; the tray's "Open Configurator" item and the Ctrl+NumLock hotkey, so
; neither can ever end up with two Configurator windows open at once.
OpenOrFocusConfigurator()
{
    ; The Configurator's main window is always created at startup (see
    ; Configurator.ahk / MainWindow.Show()) even if it's immediately hidden
    ; (start-minimized, or closed to tray), so DetectHiddenWindows lets us
    ; find it either way.
    prevDetect := A_DetectHiddenWindows
    A_DetectHiddenWindows := true
    hwnd := WinExist("NumpadOS Configurator")
    A_DetectHiddenWindows := prevDetect

    if hwnd
    {
        Logger.Info("Configurator already running - bringing it to the front.")
        WinShow(hwnd)
        if WinGetMinMax(hwnd) = -1
            WinRestore(hwnd)
        WinActivate(hwnd)
    }
    else
    {
        Logger.Info("Configurator not running - starting a new instance.")
        OpenConfigurator()
    }
}

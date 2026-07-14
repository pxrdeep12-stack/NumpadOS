#Requires AutoHotkey v2.0
#SingleInstance Force
; ============================================================================
; Configurator.ahk
; ----------------------------------------------------------------------------
; Entry point for the NumpadOS Configurator - the GUI application used to
; create, edit, test, import, and export NumpadOS shortcuts.
;
; This script only edits data\config.json. It does not register any numpad
; hotkeys itself - that's the Launcher's job (see Launcher.ahk).
; ============================================================================

#Include lib\JSON.ahk
#Include lib\Logger.ahk
#Include lib\Config.ahk
#Include lib\Utils.ahk
#Include lib\SmartLaunch.ahk
#Include lib\IconUtils.ahk
#Include lib\Gui_Main.ahk
#Include lib\Gui_Wizard.ahk
#Include lib\Gui_Settings.ahk

Logger.Init("configurator.log")
Logger.Info("=== NumpadOS Configurator starting ===")

Config.Load()

; ---- Tray icon & menu ----
A_IconTip := "NumpadOS Configurator"
TraySetup()

MainWindow.Show()

if Config.GetSetting("startMinimized")
    MainWindow.gui.Hide()

return

; ============================================================================
; Tray icon
; ============================================================================

TraySetup()
{
    A_IconHidden := !Config.GetSetting("showTrayIcon")

    tray := A_TrayMenu
    tray.Delete()
    tray.Add("Open NumpadOS Configurator", (*) => ShowMainWindow())
    tray.Add("Add Shortcut...", (*) => ShortcutWizard.ShowNew((*) => MainWindow.Refresh()))
    tray.Add()
    tray.Add("Exit", (*) => ExitApp())
    tray.Default := "Open NumpadOS Configurator"
    A_TrayMenu.ClickCount := 1
}

ShowMainWindow()
{
    MainWindow.gui.Show()
    WinActivate(MainWindow.gui.Hwnd)
}

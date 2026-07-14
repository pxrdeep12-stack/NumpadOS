; ============================================================================
; Gui_Settings.ahk
; ----------------------------------------------------------------------------
; Dedicated Settings window: startup behavior, tray icon, and update checks.
; Checkboxes only hold pending, in-memory choices - nothing is written to
; config.json (or to the startup registry entry) until "Save" is clicked,
; which then offers to reload the Launcher so the change takes effect right
; away. "Close" discards any unsaved checkbox changes.
; ============================================================================

class SettingsWindow
{
    static gui := ""
    static chkStartup := ""
    static chkMinimized := ""
    static chkAutoRun := ""
    static chkTray := ""
    static chkUpdates := ""
    static chkAdmin := ""
    static radNumLockOn := ""
    static radNumLockOff := ""

    static Show()
    {
        g := Gui("+Owner" . MainWindow.gui.Hwnd . " -MinimizeBox -MaximizeBox", "NumpadOS Settings")
        SettingsWindow.gui := g
        Utils.ApplyStandardTheme(g)
        g.OnEvent("Close", (*) => g.Destroy())

        title := g.Add("Text", "x16 y14 w400", "Settings")
        title.SetFont("s12 bold")

        y := 56
        chkStartup := g.Add("Checkbox", "x16 y" . y . " w440 vChkStartup Checked" . (Utils.IsRunAtStartupEnabled() ? 1 : 0),
            "Launch NumpadOS at Windows startup")
        SettingsWindow.chkStartup := chkStartup
        y += 34

        chkMinimized := g.Add("Checkbox", "x16 y" . y . " w440 vChkMinimized Checked" . (Config.GetSetting("startMinimized") ? 1 : 0),
            "Start minimized")
        SettingsWindow.chkMinimized := chkMinimized
        y += 34

        chkAutoRun := g.Add("Checkbox", "x16 y" . y . " w440 vChkAutoRun Checked" . (Config.GetSetting("runLauncherAfterLogin") ? 1 : 0),
            "Run launcher automatically after login")
        SettingsWindow.chkAutoRun := chkAutoRun
        y += 34

        chkTray := g.Add("Checkbox", "x16 y" . y . " w440 vChkTray Checked" . (Config.GetSetting("showTrayIcon") ? 1 : 0),
            "Show tray icon")
        SettingsWindow.chkTray := chkTray
        y += 34

        chkUpdates := g.Add("Checkbox", "x16 y" . y . " w440 vChkUpdates Checked" . (Config.GetSetting("checkForUpdates") ? 1 : 0),
            "Check for updates automatically")
        SettingsWindow.chkUpdates := chkUpdates
        y += 34

        chkAdmin := g.Add("Checkbox", "x16 y" . y . " w440 vChkAdmin Checked" . (Config.GetSetting("runAsAdmin") ? 1 : 0),
            "Run as Administrator (optional)")
        SettingsWindow.chkAdmin := chkAdmin
        y += 44

        numLockMode := Config.GetSetting("launcherNumLockMode")

        label := g.Add("Text", "x16 y" . y . " w440", "Launcher Activation Mode")
        label.SetFont("s10 bold")
        y += 26

        radNumLockOn := g.Add("Radio", "x16 y" . y . " w440 Group vRadNumLockOn Checked" . (numLockMode != "off" ? 1 : 0),
            "Launcher Active When: Num Lock ON")
        SettingsWindow.radNumLockOn := radNumLockOn
        y += 28

        radNumLockOff := g.Add("Radio", "x16 y" . y . " w440 vRadNumLockOff Checked" . (numLockMode = "off" ? 1 : 0),
            "Launcher Active When: Num Lock OFF  (Default)")
        SettingsWindow.radNumLockOff := radNumLockOff
        y += 44

        for c in [chkStartup, chkMinimized, chkAutoRun, chkTray, chkUpdates, chkAdmin, radNumLockOn, radNumLockOff]
            Utils.ApplyControlTheme(c)

        closeBtn := g.Add("Button", "x286 y" . y . " w80 h30", "Close")
        closeBtn.OnEvent("Click", (*) => g.Destroy())
        Utils.ApplyControlTheme(closeBtn)

        saveBtn := g.Add("Button", "x376 y" . y . " w80 h30 Default", "Save")
        saveBtn.OnEvent("Click", (*) => SettingsWindow._Save())
        Utils.ApplyControlTheme(saveBtn)

        g.Show("w472 h" . (y + 60))
    }

    static _Save()
    {
        startupVal := SettingsWindow.chkStartup.Value ? true : false
        ok := Utils.SetRunAtStartup(startupVal, A_ScriptDir . "\Launcher.ahk")
        if (ok)
        {
            Config.SetSetting("runAtStartup", startupVal)
        }
        else
        {
            ; Don't let config.json claim a state that isn't actually true in
            ; the registry - store what's really there instead of the
            ; requested value, and tell the user plainly what happened.
            Config.SetSetting("runAtStartup", Utils.IsRunAtStartupEnabled())
            MsgBox(
                "Couldn't update the Windows startup setting.`n`n"
                . "NumpadOS may not start automatically at login until this is fixed. "
                . "Check launcher.log/configurator.log for details, or try running "
                . "the Configurator as Administrator.",
                "NumpadOS - Startup Setting Failed", "Icon!")
        }

        Config.SetSetting("startMinimized", SettingsWindow.chkMinimized.Value ? true : false)
        Config.SetSetting("runLauncherAfterLogin", SettingsWindow.chkAutoRun.Value ? true : false)
        Config.SetSetting("showTrayIcon", SettingsWindow.chkTray.Value ? true : false)
        Config.SetSetting("checkForUpdates", SettingsWindow.chkUpdates.Value ? true : false)
        Config.SetSetting("runAsAdmin", SettingsWindow.chkAdmin.Value ? true : false)
        Config.SetSetting("launcherNumLockMode", SettingsWindow.radNumLockOff.Value ? "off" : "on")

        SettingsWindow.gui.Destroy()
        Utils.ShowSavedReloadPrompt()
    }
}

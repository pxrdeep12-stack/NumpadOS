#Requires AutoHotkey v2.0

; ============================================================================
; NumpadOS - Notification Toast System
; ============================================================================
; Small, non-intrusive notifications for mode changes and errors.
; Uses a lightweight GUI instead of TrayTip.
;
; Exports:
;   - ShowModeNotification()
;   - ShowErrorNotification()
;   - ShowToast()
;   - HideToast()
; ============================================================================

; ============================================================================
; TOAST DISPLAY
; ============================================================================

global MODE_NOTIFICATION_GUI := ""
global MODE_NOTIFICATION_TEXT := ""

ShowModeNotification(message) {
    ShowTransientNotification(message, 650)
}

ShowErrorNotification(message) {
    ShowTransientNotification("Error: " . message, 900)
}

ShowToast(message, title := "NumpadOS") {
    ShowTransientNotification(message, 700)
}

ShowTransientNotification(message, displayMs := 700) {
    global MODE_NOTIFICATION_GUI
    global MODE_NOTIFICATION_TEXT

    try {
        if (MODE_NOTIFICATION_GUI = "") {
            MODE_NOTIFICATION_GUI := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound")
            MODE_NOTIFICATION_GUI.BackColor := "0x1F1F1F"
            MODE_NOTIFICATION_GUI.SetFont("s10 q5", "Segoe UI")
            MODE_NOTIFICATION_TEXT := MODE_NOTIFICATION_GUI.AddText("x12 y10 w180 h24 Center", "")
            WinSetTransColor("0x1F1F1F 0", MODE_NOTIFICATION_GUI.Hwnd)
        }

        MODE_NOTIFICATION_TEXT.Text := message

        screenWidth := A_ScreenWidth
        screenHeight := A_ScreenHeight
        notificationX := screenWidth - 220
        notificationY := screenHeight - 90
        MODE_NOTIFICATION_GUI.Show("x" . notificationX . " y" . notificationY . " NoActivate")

        fadeSteps := 10
        fadeDelay := 8
        alpha := 0
        while alpha <= 220 {
            WinSetTransColor("0x1F1F1F " . alpha, MODE_NOTIFICATION_GUI.Hwnd)
            Sleep(fadeDelay)
            alpha += 22
        }

        Sleep(displayMs - (fadeSteps * fadeDelay * 2))

        alpha := 220
        while alpha >= 0 {
            WinSetTransColor("0x1F1F1F " . alpha, MODE_NOTIFICATION_GUI.Hwnd)
            Sleep(fadeDelay)
            alpha -= 22
        }

        MODE_NOTIFICATION_GUI.Hide()
    } catch as err {
        LogMessage("Error showing notification: " . err.Message, "ERROR")
    }
}

HideToast() {
    try {
        if (MODE_NOTIFICATION_GUI != "") {
            MODE_NOTIFICATION_GUI.Hide()
        }
    } catch as err {
        LogMessage("Error hiding toast: " . err.Message, "ERROR")
    }
}
